import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import '../models/voice_models.dart';
import '../services/voice_api_service.dart';
import '../di/injection_container.dart';

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
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  AudioPlayer? _audioPlayer; // Use audioplayers for better speaker routing
  Timer? _recordingTimer;
  Timer? _levelTimer;

  VoiceRecordingNotifier() : super(const VoiceRecordingState()) {
    // Don't initialize recorder immediately - wait for permission first
  }

  Future<void> _initializeRecorder() async {
    if (_recorder != null) return; // Already initialized
    
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    
    try {
      await _recorder!.openRecorder();
      await _player!.openPlayer();
      
      print('🎤 FlutterSound recorder and player initialized successfully');
    } catch (e) {
      print('🎤 Error initializing FlutterSound: $e');
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Failed to initialize audio system: $e',
      );
    }
  }

  Future<bool> _requestPermissions() async {
    print('🎤 Requesting permissions...');
    
    try {
      // Try to initialize FlutterSound first - it will trigger the native permission dialog
      print('🎤 Attempting to initialize FlutterSound to trigger native permission...');
      
      if (_recorder == null) {
        _recorder = FlutterSoundRecorder();
        await _recorder!.openRecorder();
        print('🎤 FlutterSound recorder opened successfully - permission likely granted');
        return true;
      }
      
      return true;
    } catch (e) {
      print('🎤 FlutterSound initialization failed: $e');
      
      // Fallback to permission_handler
      print('🎤 Falling back to permission_handler...');
      
      final microphoneStatus = await Permission.microphone.status;
      print('🎤 Current microphone permission: $microphoneStatus');
      
      final microphoneResult = await Permission.microphone.request();
      print('🎤 Microphone permission result: $microphoneResult');
      
      if (microphoneResult.isGranted) {
        print('🎤 Microphone permission granted via permission_handler!');
        return true;
      } else if (microphoneResult.isPermanentlyDenied) {
        print('🎤 Microphone permission permanently denied');
        state = state.copyWith(
          status: RecordingStatus.error,
          errorMessage: 'Microphone permission was permanently denied. Please enable it in Settings → iloqi → Microphone, then try again.',
        );
        return false;
      } else {
        print('🎤 Microphone permission denied: $microphoneResult');
        state = state.copyWith(
          status: RecordingStatus.error,
          errorMessage: 'Microphone permission was denied. Please try again.',
        );
        return false;
      }
    }
  }

  Future<void> startRecording() async {
    print('🎤 Start recording button pressed');
    
    // Clear any previous error messages
    state = state.copyWith(
      errorMessage: null,
      status: RecordingStatus.idle,
    );
    
    if (!await _requestPermissions()) {
      print('🎤 Permission check failed, cannot start recording');
      return;
    }

    print('🎤 Permission granted, proceeding with recording initialization');

    try {
      // Get the documents directory for storing the recording
      final appDirectory = await getApplicationDocumentsDirectory();
      final filePath = '${appDirectory.path}/voice_recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder!.startRecorder(
        toFile: filePath,
        codec: Codec.pcm16WAV,
      );

      state = state.copyWith(
        isRecording: true,
        hasRecording: false, // Will be set to true when recording stops
        status: RecordingStatus.recording,
        recordingPath: filePath,
        errorMessage: null,
        recordingDuration: Duration.zero,
      );

      print('🎤 Recording started: $filePath');

      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          state = state.copyWith(
            recordingDuration: Duration(seconds: timer.tick),
          );
        }
      });

    } catch (e) {
      print('🎤 Error starting recording: $e');
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Failed to start recording: $e',
      );
    }
  }

  Future<void> stopRecording() async {
    try {
      if (_recorder == null || !_recorder!.isRecording) {
        return;
      }

      final recordingPath = await _recorder!.stopRecorder();
      _recordingTimer?.cancel();
      _recordingTimer = null;

      state = state.copyWith(
        isRecording: false,
        hasRecording: true, // Mark that we have a recording
        status: RecordingStatus.stopped,
        recordingPath: recordingPath,
        errorMessage: null, // Clear any error messages
      );

      print('🎤 Recording stopped: $recordingPath');

      // Analyze the recording
      if (recordingPath != null) {
        await analyzeRecording(recordingPath);
      }

    } catch (e) {
      print('🎤 Error stopping recording: $e');
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Failed to stop recording: $e',
      );
    }
  }

  Future<void> playRecording() async {
    if (state.recordingPath == null) {
      print('🎤 No recording path available for playback');
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
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ));
        
        print('🎤 AudioPlayer initialized with speaker output');
      }

      print('🎤 Starting playback with AudioPlayer: ${state.recordingPath}');
      
      // Set up completion listener
      _audioPlayer!.onPlayerComplete.listen((_) {
        print('🎤 AudioPlayer playback finished');
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

      print('🎤 Playing recording with AudioPlayer: ${state.recordingPath}');
    } catch (e) {
      print('🎤 Error playing recording: $e');
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
        print('🎤 AudioPlayer stopped');
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
        errorMessage: null, // Clear any error messages
      );
      
      // For now, just mark as analyzed
      // The actual analysis will be triggered by the UI using VoiceAnalysisNotifier
      state = state.copyWith(
        status: RecordingStatus.analyzed,
        errorMessage: null, // Clear any error messages
      );
      
      print('🔬 Recording ready for analysis: $audioFilePath');
    } catch (e) {
      print('🔬 Error preparing recording for analysis: $e');
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Failed to analyze recording: $e',
      );
    }
  }

  void clearRecording() {
    _recordingTimer?.cancel();
    _levelTimer?.cancel();
    _player?.stopPlayer();
    _audioPlayer?.stop();
    
    if (state.recordingPath != null) {
      try {
        final file = File(state.recordingPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('⚠️ Error deleting recording file: $e');
      }
    }

    // Reset to clean state with no error messages
    state = const VoiceRecordingState(
      status: RecordingStatus.idle,
      errorMessage: null,
    );
    debugPrint('🗑️ Recording cleared');
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _levelTimer?.cancel();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _audioPlayer?.dispose();
    super.dispose();
  }
}

// Voice Analysis Notifier
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
      
      // Step 2: Trigger analysis and get results directly
      debugPrint('🔬 Step 2: Analyzing voice sample ID: ${voiceSample.id}');
      final analysisResponse = await _voiceApiService.analyzeVoiceSample(voiceSample.id);
      debugPrint('✅ Analysis completed successfully');
      
      // Step 3: Create VoiceAnalysis from the direct response
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
  Timer? _pollTimer;
  AudioPlayer? _audioPlayer;
  final Map<String, String> _downloadedFiles = {}; // Cache downloaded files

  AccentTwinNotifier(this._voiceApiService) : super(const AsyncValue.data(null));

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
            await Future.delayed(Duration(milliseconds: 200)); // Allow cleanup
            
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
                  contentType: AndroidContentType.speech,
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
            });
            
            _audioPlayer!.onPlayerStateChanged.listen((state) {
              debugPrint('🎵 Cached file player state: $state');
            });
            
            return;
          } catch (cachedError) {
            debugPrint('❌ Cached file playback failed: $cachedError');
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
            contentType: AndroidContentType.speech,
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
          
        } catch (fallbackError) {
          debugPrint('❌ Fallback audio configuration also failed: $fallbackError');
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
      await Future.delayed(Duration(milliseconds: 200));
      
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
        await Future.delayed(Duration(milliseconds: 300));
        
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
        debugPrint('🔊 Accent twin playback stopped');
      }
    } catch (e) {
      debugPrint('❌ Error stopping accent twin playback: $e');
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
