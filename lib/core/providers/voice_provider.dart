import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

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
      
      // Step 2: Analyze the uploaded sample
      debugPrint('🔬 Step 2: Analyzing voice sample ID: ${voiceSample.id}');
      final analysis = await _voiceApiService.analyzeVoiceSample(voiceSample.id);
      
      state = AsyncValue.data(analysis);
      debugPrint('✅ Voice analysis completed: ${analysis.detectedAccent}');
    } catch (e, stackTrace) {
      debugPrint('❌ Voice analysis error: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clearAnalysis() {
    state = const AsyncValue.data(null);
    _currentSample = null;
  }
}

// Accent Twin Notifier
class AccentTwinNotifier extends StateNotifier<AsyncValue<AccentTwin?>> {
  final VoiceApiService _voiceApiService;

  AccentTwinNotifier(this._voiceApiService) : super(const AsyncValue.data(null));

  Future<void> generateAccentTwin(int sampleId, String targetAccent) async {
    state = const AsyncValue.loading();

    try {
      debugPrint('🎭 Generating accent twin: $targetAccent for sample: $sampleId');
      
      final request = {
        'target_accent': targetAccent,
        'tts_provider': 'edge_tts', // Use Edge TTS as default
        'voice_model': 'en-US-AriaNeural',
        'generation_params': {},
      };

      final accentTwin = await _voiceApiService.generateAccentTwin(sampleId, request);
      
      state = AsyncValue.data(accentTwin);
      debugPrint('✅ Accent twin generated: ${accentTwin.id}');
    } catch (e, stackTrace) {
      debugPrint('❌ Accent twin generation error: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clearAccentTwin() {
    state = const AsyncValue.data(null);
  }
}
