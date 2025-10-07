import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import '../models/voice_models.dart';
import '../services/voice_api_service.dart';
import '../services/cross_platform_recorder_simple.dart';
import '../di/injection_container.dart';
import '../utils/permission_helper.dart';

// Providers
final voiceApiServiceProvider = Provider<VoiceApiService>((ref) {
  return ServiceLocator.instance.voiceApi;
});

final voiceRecordingProvider = StateNotifierProvider<VoiceRecordingNotifier, VoiceRecordingState>((ref) {
  return VoiceRecordingNotifier();
});

final voiceAnalysisProvider = StateNotifierProvider<VoiceAnalysisNotifier, AsyncValue<VoiceAnalysis?>>((ref) {
  return VoiceAnalysisNotifier(ref.watch(voiceApiServiceProvider));
});

final accentTwinProvider = StateNotifierProvider<AccentTwinNotifier, AsyncValue<AccentTwin?>>((ref) {
  return AccentTwinNotifier(ref.watch(voiceApiServiceProvider));
});

// Voice Recording State
class VoiceRecordingState {
  final bool isRecording;
  final bool isPlaying;
  final bool hasRecording;
  final String? recordingPath;
  final Duration recordingDuration;
  final RecordingStatus status;
  final String? errorMessage;
  final double? audioLevel;
  final VoiceSample? uploadedSample; // Track uploaded sample for accent twin generation

  const VoiceRecordingState({
    this.isRecording = false,
    this.isPlaying = false,
    this.hasRecording = false,
    this.recordingPath,
    this.recordingDuration = Duration.zero,
    this.status = RecordingStatus.idle,
    this.errorMessage,
    this.audioLevel,
    this.uploadedSample,
  });

  VoiceRecordingState copyWith({
    bool? isRecording,
    bool? isPlaying,
    bool? hasRecording,
    String? recordingPath,
    Duration? recordingDuration,
    RecordingStatus? status,
    String? errorMessage,
    double? audioLevel,
    VoiceSample? uploadedSample,
  }) {
    return VoiceRecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPlaying: isPlaying ?? this.isPlaying,
      hasRecording: hasRecording ?? this.hasRecording,
      recordingPath: recordingPath ?? this.recordingPath,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      audioLevel: audioLevel ?? this.audioLevel,
      uploadedSample: uploadedSample ?? this.uploadedSample,
    );
  }
}

enum RecordingStatus {
  idle,
  recording,
  stopped,
  playing,
  analyzing,
  analyzed,
  error,
}

// Voice Recording Notifier
class VoiceRecordingNotifier extends StateNotifier<VoiceRecordingState> {
  late final CrossPlatformRecorderSimple _recorder;
  AudioPlayer? _audioPlayer; // Use audioplayers for playback
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<double>? _amplitudeSubscription;
  StreamSubscription<bool>? _recordingStateSubscription;

  VoiceRecordingNotifier() : super(const VoiceRecordingState()) {
    _recorder = CrossPlatformRecorderSimple();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    try {
      // Initialize the recorder
      final success = await _recorder.initialize();
      if (!success) {
        state = state.copyWith(
          status: RecordingStatus.error,
          errorMessage: 'Failed to initialize audio recorder',
        );
        return;
      }

      // Set up stream subscriptions for real-time updates
      _durationSubscription = _recorder.durationStream.listen((duration) {
        if (mounted) {
          state = state.copyWith(recordingDuration: duration);
        }
      });

      _amplitudeSubscription = _recorder.amplitudeStream.listen((amplitude) {
        if (mounted) {
          state = state.copyWith(audioLevel: amplitude);
        }
      });

      _recordingStateSubscription = _recorder.recordingStateStream.listen((isRecording) {
        if (mounted) {
          // Preserve duration when recording stops
          final currentDuration = state.recordingDuration;
          state = state.copyWith(
            isRecording: isRecording,
            status: isRecording ? RecordingStatus.recording : RecordingStatus.stopped,
            recordingDuration: isRecording ? currentDuration : currentDuration, // Always preserve duration
          );
        }
      });

      debugPrint('🎤 CrossPlatformRecorderSimple initialized successfully');
    } catch (e) {
      debugPrint('🎤 Error initializing recorder: $e');
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Failed to initialize audio system: $e',
      );
    }
  }

  Future<void> startRecording() async {
    debugPrint('🎤 Start recording requested');

    // Clear any previous error messages and set initial state immediately for faster UI response
    state = state.copyWith(
      errorMessage: null,
      status: RecordingStatus.idle,
      isRecording: false,
    );

    // Check if recorder is supported on this platform (fast synchronous check)
    if (!_recorder.isSupported) {
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Audio recording is not supported on this platform',
      );
      return;
    }

    // Start recording immediately without waiting for permission check
    // The recorder will handle permission internally if needed
    try {
      final success = await _recorder.startRecording();
      if (success) {
        // Update state immediately for responsive UI
        state = state.copyWith(
          isRecording: true,
          hasRecording: false,
          status: RecordingStatus.recording,
          errorMessage: null,
          recordingDuration: Duration.zero,
        );
        debugPrint('🎤 Recording started successfully');
      } else {
        state = state.copyWith(
          status: RecordingStatus.error,
          errorMessage: 'Failed to start recording. Please check microphone permissions.',
        );
      }
    } catch (e) {
      debugPrint('🎤 Error starting recording: $e');
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Failed to start recording: $e',
      );
    }
  }

  Future<void> stopRecording() async {
    debugPrint('🎤 Stop recording requested');

    if (!state.isRecording) {
      debugPrint('🎤 Not currently recording, ignoring stop request');
      return;
    }

    try {
      // Capture final duration before stopping
      final finalDuration = state.recordingDuration;
      debugPrint('🎤 Final recording duration: ${finalDuration.inSeconds} seconds');
      
      // Stop recording and get path immediately
      final recordingPath = await _recorder.stopRecording();

      // Cancel subscriptions to prevent them from overwriting our preserved state
      _durationSubscription?.cancel();
      _amplitudeSubscription?.cancel();
      _recordingStateSubscription?.cancel();

      if (recordingPath != null && recordingPath.isNotEmpty) {
        // Update state immediately for responsive UI, preserving duration
        state = state.copyWith(
          isRecording: false,
          hasRecording: true,
          recordingPath: recordingPath,
          status: RecordingStatus.stopped,
          errorMessage: null,
          recordingDuration: finalDuration, // Preserve the final duration
        );
        debugPrint('🎤 Recording stopped successfully: $recordingPath');
      } else {
        // For macOS, the path might be null but file exists - don't treat as error
        state = state.copyWith(
          isRecording: false,
          hasRecording: false, // Will be corrected by file search if needed
          status: RecordingStatus.stopped,
          errorMessage: null, // Don't show error for macOS null path
          recordingDuration: finalDuration, // Preserve the final duration
        );
        debugPrint('🎤 Recording stopped, file path validation in progress');
      }
    } catch (e) {
      debugPrint('🎤 Error stopping recording: $e');
      state = state.copyWith(
        isRecording: false,
        hasRecording: false,
        status: RecordingStatus.error,
        errorMessage: 'Failed to stop recording: $e',
      );
    }
  }

  Future<void> pauseRecording() async {
    if (state.isRecording) {
      await _recorder.pauseRecording();
      debugPrint('🎤 Recording paused');
    }
  }

  Future<void> resumeRecording() async {
    if (state.isRecording) {
      await _recorder.resumeRecording();
      debugPrint('🎤 Recording resumed');
    }
  }

  Future<void> playRecording() async {
    if (state.recordingPath == null) {
      debugPrint('🎤 No recording path available for playback');
      return;
    }

    try {
      if (_audioPlayer == null) {
        _audioPlayer = AudioPlayer();
        
        // Configure audio player for speaker output
        await _audioPlayer!.setAudioContext(AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.allowBluetooth,
            ],
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ));
        
        debugPrint('🎤 AudioPlayer initialized with speaker output');
      }

      debugPrint('🎤 Starting playback with AudioPlayer: ${state.recordingPath}');
      
      // Set up completion listener
      _audioPlayer!.onPlayerComplete.listen((_) {
        debugPrint('🎤 AudioPlayer playback finished');
        if (mounted) {
          state = state.copyWith(
            isPlaying: false,
            status: RecordingStatus.stopped,
            errorMessage: null,
          );
        }
      });

      await _audioPlayer!.play(DeviceFileSource(state.recordingPath!));

      state = state.copyWith(
        isPlaying: true,
        status: RecordingStatus.playing,
        errorMessage: null,
      );

      debugPrint('🎤 Playing recording with AudioPlayer: ${state.recordingPath}');
    } catch (e) {
      debugPrint('🎤 Error playing recording: $e');
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Failed to play recording: $e',
      );
    }
  }

  Future<void> stopPlayback() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        debugPrint('🎤 AudioPlayer stopped');
      }
      state = state.copyWith(isPlaying: false, status: RecordingStatus.stopped);
    } catch (e) {
      debugPrint('❌ Error stopping playback: $e');
    }
  }

  Future<void> analyzeRecording(String audioFilePath) async {
    try {
      state = state.copyWith(
        status: RecordingStatus.analyzing,
        errorMessage: null,
      );
      
      debugPrint('🔬 Starting voice analysis for: $audioFilePath');
      
      // Verify file exists
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception('Recording file not found');
      }
      
      // File size check
      final fileSize = await file.length();
      debugPrint('🔬 Recording file size: ${fileSize} bytes');
      
      if (fileSize == 0) {
        throw Exception('Recording file is empty');
      }

      state = state.copyWith(
        status: RecordingStatus.analyzed,
        errorMessage: null,
      );
      
      debugPrint('🔬 Voice analysis completed successfully');
      
    } catch (e) {
      debugPrint('🔬 Voice analysis failed: $e');
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Analysis failed: $e',
      );
    }
  }

  void clearRecording() {
    if (state.recordingPath != null) {
      // Try to delete the file
      try {
        final file = File(state.recordingPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('🗑️ Error deleting recording file: $e');
      }
    }
    
    state = const VoiceRecordingState(
      status: RecordingStatus.idle,
      errorMessage: null,
    );
    debugPrint('🗑️ Recording cleared');
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _recordingStateSubscription?.cancel();
    _audioPlayer?.dispose();
    _recorder.dispose();
    super.dispose();
  }
}

//-----------------------------------------------------------
// Audio player state management for accent twin playback
//-----------------------------------------------------------

enum AudioPlayerState { stopped, playing, paused }

class AudioPlaybackState {
  final AudioPlayerState state;
  final String? currentAudioUrl;
  final Duration? position;
  final Duration? duration;

  const AudioPlaybackState({
    this.state = AudioPlayerState.stopped,
    this.currentAudioUrl,
    this.position,
    this.duration,
  });

  AudioPlaybackState copyWith({
    AudioPlayerState? state,
    String? currentAudioUrl,
    Duration? position,
    Duration? duration,
  }) {
    return AudioPlaybackState(
      state: state ?? this.state,
      currentAudioUrl: currentAudioUrl ?? this.currentAudioUrl,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }

  bool get isPlaying => state == AudioPlayerState.playing;
  bool get isPaused => state == AudioPlayerState.paused;
  bool get isStopped => state == AudioPlayerState.stopped;
}

final audioPlaybackProvider = StateNotifierProvider<AudioPlaybackNotifier, AudioPlaybackState>((ref) {
  return AudioPlaybackNotifier();
});

class AudioPlaybackNotifier extends StateNotifier<AudioPlaybackState> {
  AudioPlaybackNotifier() : super(const AudioPlaybackState());

  void updateState(AudioPlayerState audioState, {String? url, Duration? position, Duration? duration}) {
    state = state.copyWith(
      state: audioState,
      currentAudioUrl: url ?? state.currentAudioUrl,
      position: position,
      duration: duration,
    );
  }

  void reset() {
    state = const AudioPlaybackState();
  }
}

//-----------------------------------------------------------
// Voice Analysis Notifier
//-----------------------------------------------------------
class VoiceAnalysisNotifier extends StateNotifier<AsyncValue<VoiceAnalysis?>> {
  final VoiceApiService _voiceApiService;
  VoiceSample? _currentSample; // Store the uploaded sample

  VoiceAnalysisNotifier(this._voiceApiService) : super(const AsyncValue.data(null));

  VoiceSample? get currentSample => _currentSample;

  Future<void> analyzeVoice(String audioFilePath) async {
    state = const AsyncValue.loading();

    try {
      final file = File(audioFilePath);

      if (!file.existsSync()) {
        throw Exception('Audio file not found');
      }

      debugPrint('🔬 Step 1: Uploading voice sample: $audioFilePath');

      // Step 1: Upload the voice sample
      final voiceSample = await _voiceApiService.uploadVoiceSample(file);
      _currentSample = voiceSample; // Store for accent twin generation
      debugPrint('✅ Voice sample uploaded with ID: ${voiceSample.id}');

      // Step 2: Trigger analysis
      debugPrint('🔬 Step 2: Analyzing voice sample ID: ${voiceSample.id}');
      final analysisResponse = await _voiceApiService.analyzeVoiceSample(voiceSample.id);
      debugPrint('✅ Analysis request completed successfully');

      // Step 3: Create VoiceAnalysis from the response
      final voiceAnalysis = VoiceAnalysis(
        status: analysisResponse.status,
        message: analysisResponse.message,
        analysis: analysisResponse.analysis,
      );

      state = AsyncValue.data(voiceAnalysis);
      debugPrint('✅ Voice analysis completed: ${voiceAnalysis.detectedAccent}');

    } catch (e, stackTrace) {
      debugPrint('❌ Voice analysis error: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshAnalysisResults() async {
    if (_currentSample == null) {
      debugPrint('⚠️ No current sample to refresh analysis for');
      return;
    }

    try {
      debugPrint('🔄 Refreshing analysis results for sample: ${_currentSample!.id}');
      final resultsResponse = await _voiceApiService.getAnalysisResults(_currentSample!.id);

      if (resultsResponse.analyzed && resultsResponse.analysis != null) {
        final voiceAnalysis = VoiceAnalysis(
          status: resultsResponse.status,
          message: resultsResponse.message ?? 'Analysis completed',
          analysis: resultsResponse.analysis!,
        );
        state = AsyncValue.data(voiceAnalysis);
        debugPrint('✅ Analysis results refreshed');
      } else {
        debugPrint('ℹ️ Analysis not yet completed');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error refreshing analysis results: $e');
      // Don't update state on refresh errors to preserve existing data
    }
  }

  Future<void> reanalyzeVoice({String? promptText, bool forceCompleteReanalysis = false}) async {
    if (_currentSample == null) {
      debugPrint('⚠️ No current sample to re-analyze');
      return;
    }

    state = const AsyncValue.loading();

    try {
      debugPrint('🔄 Re-analyzing voice sample: ${_currentSample!.id}');
      final reanalyzeRequest = ReanalyzeRequest(
        promptText: promptText,
        forceCompleteReanalysis: forceCompleteReanalysis,
      );

      final analysisResponse = await _voiceApiService.reanalyzeVoiceSample(
        _currentSample!.id,
        reanalyzeRequest,
      );

      final voiceAnalysis = VoiceAnalysis(
        status: analysisResponse.status,
        message: analysisResponse.message,
        analysis: analysisResponse.analysis,
      );

      state = AsyncValue.data(voiceAnalysis);
      debugPrint('✅ Voice re-analysis completed');

    } catch (e, stackTrace) {
      debugPrint('❌ Voice re-analysis error: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Transform VoiceSample with analysis_data into VoiceAnalysis object
  VoiceAnalysis _transformToVoiceAnalysis(VoiceSample sample) {
    final analysisData = sample.analysisData;
    if (analysisData == null) {
      throw Exception('No analysis data available');
    }

    // Create a mock VoiceAnalysis structure based on what we expect
    // This will need to be adjusted based on the actual structure of analysis_data
    return VoiceAnalysis(
      status: 'success',
      message: 'Analysis completed successfully',
      analysis: AnalysisData(
        transcription: analysisData['transcription']?.toString() ?? '',
        confidenceScore: (analysisData['confidence_score'] ?? 0.0).toDouble(),
        detectedAccent: analysisData['detected_accent']?.toString() ?? 'unknown',
        accentConfidence: (analysisData['accent_confidence'] ?? 0.0).toDouble(),
        overallScore: (analysisData['overall_score'] ?? 0.0).toDouble(),
        pronunciationScore: (analysisData['pronunciation_score'] ?? 0.0).toDouble(),
        fluencyScore: (analysisData['fluency_score'] ?? 0.0).toDouble(),
        feedback: List<String>.from(analysisData['feedback'] ?? []),
        phonemeIssues: List<dynamic>.from(analysisData['phoneme_issues'] ?? []),
        audioFeatures: AudioFeatures(
          mfcc: List<double>.from(analysisData['audio_features']?['mfcc'] ?? []),
          spectralCentroid: (analysisData['audio_features']?['spectral_centroid'] ?? 0.0).toDouble(),
          spectralRolloff: (analysisData['audio_features']?['spectral_rolloff'] ?? 0.0).toDouble(),
          zeroCrossingRate: (analysisData['audio_features']?['zero_crossing_rate'] ?? 0.0).toDouble(),
          fundamentalFrequency: (analysisData['audio_features']?['fundamental_frequency'] ?? 0.0).toDouble(),
          rmsEnergy: (analysisData['audio_features']?['rms_energy'] ?? 0.0).toDouble(),
          tempo: (analysisData['audio_features']?['tempo'] ?? 0.0).toDouble(),
          duration: sample.duration ?? 0.0,
          snrEstimate: (analysisData['audio_features']?['snr_estimate'] ?? 0.0).toDouble(),
        ),
      ),
    );
  }

  void clearAnalysis() {
    state = const AsyncValue.data(null);
    _currentSample = null;
  }
}

// Accent Twin Notifier
class AccentTwinNotifier extends StateNotifier<AsyncValue<AccentTwin?>> {
  final VoiceApiService _voiceApiService;
  late final AudioPlaybackNotifier _audioPlaybackNotifier;
  Timer? _pollTimer;
  AudioPlayer? _audioPlayer;
  final Map<String, String> _downloadedFiles = {}; // Cache downloaded files

  AccentTwinNotifier(this._voiceApiService) : super(const AsyncValue.data(null)) {
    _audioPlaybackNotifier = AudioPlaybackNotifier();
  }

  Future<void> generateAccentTwin(int sampleId, String targetAccent, {int retryCount = 0}) async {
    state = const AsyncValue.loading();

    try {
      debugPrint('🎭 Generating accent twin: $targetAccent for sample: $sampleId (attempt ${retryCount + 1})');
      
      final request = AccentTwinCreateRequest(
        originalSample: sampleId,
        targetAccent: targetAccent,
        ttsProvider: 'edge_tts', // Use Edge TTS as default
        voiceModel: _getVoiceModelForAccent(targetAccent),
        generationParams: {
          'voice_speed': 1.0,
          'voice_pitch': 1.0,
        },
      );

      final accentTwin = await _voiceApiService.createAccentTwin(request);
      
      state = AsyncValue.data(accentTwin);
      debugPrint('✅ Accent twin created: ${accentTwin.id ?? 'unknown'}, status: ${accentTwin.generationStatus ?? 'pending'}');
      
      debugPrint('🎭 Provider: ${accentTwin.ttsProvider}');
      debugPrint('🎭 Voice Model: ${accentTwin.voiceModel}');
      
      // If no ID is returned, try to find the newly created accent twin
      if (accentTwin.id == null) {
        debugPrint('⚠️ Warning: Accent twin creation response missing ID. Attempting to find newly created twin...');
        await _findNewlyCreatedAccentTwin(sampleId, targetAccent);
      } else {
        // If we have an ID, start polling if needed
        final needsPolling = (accentTwin.isReady != true) &&
            (accentTwin.generationStatus == null || 
             accentTwin.generationStatus == 'pending' || 
             accentTwin.generationStatus == 'processing');
             
        if (needsPolling) {
          _startPolling(accentTwin.id!);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Accent twin generation error: $e');
      
      // Retry logic for server errors (500) - up to 2 retries
      if (e.toString().contains('500') && retryCount < 2) {
        debugPrint('🔄 Retrying accent twin generation due to server error (attempt ${retryCount + 2}/3)');
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2)); // Exponential backoff
        return generateAccentTwin(sampleId, targetAccent, retryCount: retryCount + 1);
      }
      
      // Handle different types of errors with user-friendly messages
      String errorMessage;
      if (e.toString().contains('500')) {
        errorMessage = 'Server error during accent twin generation. Please try again later.';
        debugPrint('🔥 Server Error (500): The server encountered an error while processing accent twin generation');
      } else if (e.toString().contains('404')) {
        errorMessage = 'Voice sample not found. Please upload a new voice sample.';
      } else if (e.toString().contains('429')) {
        errorMessage = 'Rate limit exceeded. Please wait before generating another accent twin.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network connection error. Please check your internet connection.';
      } else {
        errorMessage = 'Failed to generate accent twin. Please try again.';
      }
      
      state = AsyncValue.error(errorMessage, stackTrace);
    }
  }

  // Helper method to find newly created accent twin when ID is not returned
  Future<void> _findNewlyCreatedAccentTwin(int sampleId, String targetAccent) async {
    try {
      debugPrint('🔍 Searching for newly created accent twin for sample: $sampleId, accent: $targetAccent');
      
      // Get the list of accent twins and find the most recent one for this sample/accent
      final accentTwinsList = await _voiceApiService.getAccentTwinsList(ordering: '-created_at');
      
      // Find the most recent accent twin that matches our criteria
      final matchingTwin = accentTwinsList.results.firstWhere(
        (twin) => twin.originalSample == sampleId && 
                 twin.targetAccent == targetAccent &&
                 twin.ttsProvider == 'edge_tts',
        orElse: () => throw Exception('Could not find newly created accent twin'),
      );
      
      debugPrint('✅ Found newly created accent twin: ${matchingTwin.id}, status: ${matchingTwin.generationStatus}');
      
      // Update state with the complete accent twin object
      state = AsyncValue.data(matchingTwin);
      
      // Start polling if needed
      final needsPolling = (matchingTwin.isReady != true) &&
          (matchingTwin.generationStatus == 'pending' || 
           matchingTwin.generationStatus == 'processing');
           
      if (needsPolling && matchingTwin.id != null) {
        _startPolling(matchingTwin.id!);
      }
      
    } catch (e) {
      debugPrint('❌ Failed to find newly created accent twin: $e');
      // Keep the original incomplete accent twin in state
      // The user can try refreshing manually
    }
  }

  // Get appropriate voice model for target accent
  String _getVoiceModelForAccent(String accent) {
    switch (accent.toUpperCase()) {
      case 'US':
        return 'en-US-AriaNeural';
      case 'UK':
        return 'en-GB-SoniaNeural';
      case 'AU':
        return 'en-AU-NatashaNeural';
      case 'CA':
        return 'en-CA-ClaraNeural';
      case 'IE':
        return 'en-IE-EmilyNeural';
      default:
        return 'en-US-AriaNeural'; // Default to US
    }
  }

  void _startPolling(int accentTwinId) {
    debugPrint('🔄 Starting polling for accent twin: $accentTwinId');
    
    // Poll every 3 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkAccentTwinStatus(accentTwinId);
    });
    
    // Stop polling after 2 minutes to avoid infinite polling
    Timer(const Duration(minutes: 2), () {
      if (_pollTimer?.isActive == true) {
        _pollTimer?.cancel();
        debugPrint('⏰ Polling timeout for accent twin: $accentTwinId');
      }
    });
  }

  Future<void> _checkAccentTwinStatus(int accentTwinId) async {
    try {
      debugPrint('🔄 Checking accent twin status: $accentTwinId');
      
      // Use the new status endpoint for more efficient polling
      final statusResponse = await _voiceApiService.getAccentTwinStatus(accentTwinId);
      final accentTwin = statusResponse.accentTwin;
      
      // Update state with new status
      state = AsyncValue.data(accentTwin);
      
      debugPrint('📊 Accent twin status: ${accentTwin.generationStatus}, ready: ${accentTwin.isReady}');
      
      // Log generation info if available
      if (statusResponse.generationInfo != null) {
        debugPrint('🎭 Provider: ${statusResponse.generationInfo!['provider']}');
        debugPrint('🎭 Voice Model: ${statusResponse.generationInfo!['voice_model']}');
        if (statusResponse.generationInfo!['processing_time'] != null) {
          debugPrint('⏱️ Processing time: ${statusResponse.generationInfo!['processing_time']}s');
        }
      }
      
      // Stop polling if ready or failed
      if (accentTwin.isReady == true || 
          accentTwin.generationStatus == 'completed' ||
          accentTwin.generationStatus == 'failed' || 
          accentTwin.generationStatus == 'error') {
        _pollTimer?.cancel();
        debugPrint('✅ Polling stopped for accent twin: $accentTwinId (${accentTwin.generationStatus})');
        
        if (accentTwin.generationStatus == 'failed' || accentTwin.generationStatus == 'error') {
          final errorMsg = (accentTwin.errorMessage?.isNotEmpty == true) 
              ? accentTwin.errorMessage! 
              : 'Accent twin generation failed';
          state = AsyncValue.error(errorMsg, StackTrace.current);
        }
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking accent twin status: $e');
      // Fallback to the regular getAccentTwin endpoint if status endpoint fails
      try {
        final accentTwin = await _voiceApiService.getAccentTwin(accentTwinId);
        state = AsyncValue.data(accentTwin);
      } catch (fallbackError) {
        debugPrint('❌ Fallback also failed: $fallbackError');
        // Don't update state on polling errors, just log them
      }
    }
  }

  Future<void> refreshAccentTwin(int accentTwinId) async {
    try {
      debugPrint('🔄 Manually refreshing accent twin: $accentTwinId');
      final accentTwin = await _voiceApiService.getAccentTwin(accentTwinId);
      state = AsyncValue.data(accentTwin);
    } catch (e, stackTrace) {
      debugPrint('❌ Error refreshing accent twin: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> playAccentTwin(String audioUrl) async {
    try {
      // Update playback state to playing
      _audioPlaybackNotifier.updateState(AudioPlayerState.playing, url: audioUrl);
      
      // Stop any existing playback first to avoid conflicts
      await stopAccentTwinPlayback();
      
      // Check if we have a cached local file first
      if (_downloadedFiles.containsKey(audioUrl)) {
        final localPath = _downloadedFiles[audioUrl]!;
        if (await File(localPath).exists()) {
          try {
            debugPrint('🎵 Playing cached local file: $localPath');
            
            // Ensure clean audio player state
            _audioPlayer?.dispose();
            _audioPlayer = null;
            await Future.delayed(const Duration(milliseconds: 200)); // Allow cleanup
            
            _audioPlayer = AudioPlayer();
            
            // Use playback audio context for audible speech playback
            await _audioPlayer!.setAudioContext(AudioContext(
              iOS: AudioContextIOS(
                category: AVAudioSessionCategory.playback, // For audible playback
                options: [
                  AVAudioSessionOptions.defaultToSpeaker, // Route to speaker
                ],
              ),
              android: AudioContextAndroid(
                isSpeakerphoneOn: true,
                stayAwake: true,
                contentType: AndroidContentType.music,
                usageType: AndroidUsageType.media,
                audioFocus: AndroidAudioFocus.gain,
              ),
              ));
            
            await _audioPlayer!.play(DeviceFileSource(localPath));
            debugPrint('✅ Cached file playback started');
            
            // Set volume to maximum to ensure audibility
            await _audioPlayer!.setVolume(1.0);
            debugPrint('🔊 Volume set to maximum (1.0)');
            
            // Add completion listener for debugging
            _audioPlayer!.onPlayerComplete.listen((_) {
              debugPrint('🎵 Cached file playback completed');
              _audioPlaybackNotifier.updateState(AudioPlayerState.stopped);
            });
            
            _audioPlayer!.onPlayerStateChanged.listen((playerState) {
              debugPrint('🎵 Cached file player state: $playerState');
              // Update our state based on player state
              switch (playerState) {
                case PlayerState.playing:
                  _audioPlaybackNotifier.updateState(AudioPlayerState.playing, url: audioUrl);
                  break;
                case PlayerState.paused:
                  _audioPlaybackNotifier.updateState(AudioPlayerState.paused, url: audioUrl);
                  break;
                case PlayerState.stopped:
                case PlayerState.completed:
                case PlayerState.disposed:
                  _audioPlaybackNotifier.updateState(AudioPlayerState.stopped);
                  break;
              }
            });            return;
          } catch (cachedError) {
            debugPrint('❌ Cached file playback failed: $cachedError');
            _audioPlaybackNotifier.updateState(AudioPlayerState.stopped);
            // Fall through to download and try again
          }
        } else {
          // Remove invalid cache entry
          _downloadedFiles.remove(audioUrl);
        }
      }
      
      if (_audioPlayer == null) {
        _audioPlayer = AudioPlayer();
        
        // Configure audio player with a simpler, more compatible setup
        await _audioPlayer!.setAudioContext(AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playAndRecord, // More permissive category
            options: [
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.allowBluetoothA2DP,
            ],
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ));
        
        debugPrint('🔊 AudioPlayer initialized for accent twin playback');
      }

      debugPrint('🔊 Playing accent twin audio: $audioUrl');
      await _audioPlayer!.play(UrlSource(audioUrl));
      
    } catch (e) {
      debugPrint('❌ Error playing accent twin: $e');
      _audioPlaybackNotifier.updateState(AudioPlayerState.stopped);
      
      // Skip the first fallback and go straight to download for HTTP URLs
      if (audioUrl.startsWith('http://')) {
        await _downloadAndPlayLocally(audioUrl);
      } else {
        // Try fallback audio configuration for non-HTTP URLs
        try {
          debugPrint('🔄 Trying fallback audio configuration...');
          _audioPlayer?.dispose();
          _audioPlayer = AudioPlayer();
          
          await _audioPlayer!.setAudioContext(AudioContext(
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.ambient,
            ),
            android: AudioContextAndroid(
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
            ),
          ));
          
          await _audioPlayer!.play(UrlSource(audioUrl));
          debugPrint('✅ Fallback audio configuration worked');
          _audioPlaybackNotifier.updateState(AudioPlayerState.playing, url: audioUrl);
          
        } catch (fallbackError) {
          debugPrint('❌ Fallback audio configuration also failed: $fallbackError');
          _audioPlaybackNotifier.updateState(AudioPlayerState.stopped);
        }
      }
    }
  }

  Future<void> _downloadAndPlayLocally(String audioUrl) async {
    // Declare filePath outside try block for catch block access
    final tempDir = await getTemporaryDirectory();
    final fileName = audioUrl.split('/').last;
    final filePath = '${tempDir.path}/$fileName';
    
    try {
      debugPrint('🔄 Downloading file for local playback...');
      
      // Use simple HTTP get to download the file
      final dio = Dio();
      
      await dio.download(audioUrl, filePath);
      debugPrint('✅ File downloaded to: $filePath');
      
      // Cache the downloaded file path
      _downloadedFiles[audioUrl] = filePath;
      
      // Try playing the local file with proper audio session reset
      _audioPlayer?.dispose();
      _audioPlayer = null; // Reset to null first
      
      // Allow disposal to complete and audio session to reset
      await Future.delayed(const Duration(milliseconds: 200));
      
      _audioPlayer = AudioPlayer();
      
      // Use audible playback audio context to ensure sound is heard
      await _audioPlayer!.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback, // For audible playback
          options: [
            AVAudioSessionOptions.defaultToSpeaker, // Route to speaker
          ],
        ),
        android: AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ));
      
      await _audioPlayer!.play(DeviceFileSource(filePath));
      debugPrint('✅ Local file playback started with audio context');
      
      // Set volume to maximum to ensure audibility
      await _audioPlayer!.setVolume(1.0);
      debugPrint('🔊 Volume set to maximum (1.0)');
      
      // Add playback monitoring for debugging
      _audioPlayer!.onPlayerComplete.listen((_) {
        debugPrint('🎵 Downloaded file playback completed');
      });
      
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        debugPrint('🎵 Downloaded file player state: $state');
      });
      
    } catch (downloadError) {
      debugPrint('❌ Download fallback also failed: $downloadError');
      
      // Last resort: try without audio context configuration
      try {
        debugPrint('🔄 Final attempt: Playing without audio context...');
        _audioPlayer?.dispose();
        _audioPlayer = null;
        await Future.delayed(const Duration(milliseconds: 300));
        
        _audioPlayer = AudioPlayer();
        // No audio context setup - use default
        await _audioPlayer!.play(DeviceFileSource(filePath));
        debugPrint('✅ Basic playback started (no audio context)');
        
      } catch (basicError) {
        debugPrint('❌ Even basic playback failed: $basicError');
      }
    }
  }

  Future<void> stopAccentTwinPlayback() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        _audioPlaybackNotifier.updateState(AudioPlayerState.stopped);
        debugPrint('🔊 Accent twin playback stopped');
      }
    } catch (e) {
      debugPrint('❌ Error stopping accent twin playback: $e');
      _audioPlaybackNotifier.updateState(AudioPlayerState.stopped);
    }
  }

  Future<void> pauseAccentTwinPlayback() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.pause();
        _audioPlaybackNotifier.updateState(AudioPlayerState.paused);
        debugPrint('⏸️ Accent twin playback paused');
      }
    } catch (e) {
      debugPrint('❌ Error pausing accent twin playback: $e');
    }
  }

  Future<void> resumeAccentTwinPlayback() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.resume();
        _audioPlaybackNotifier.updateState(AudioPlayerState.playing);
        debugPrint('▶️ Accent twin playback resumed');
      }
    } catch (e) {
      debugPrint('❌ Error resuming accent twin playback: $e');
    }
  }

  void clearAccentTwin() {
    _pollTimer?.cancel();
    state = const AsyncValue.data(null);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }
}
