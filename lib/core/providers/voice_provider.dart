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

  const VoiceRecordingState({
    this.isRecording = false,
    this.isPlaying = false,
    this.hasRecording = false,
    this.recordingPath,
    this.recordingDuration = Duration.zero,
    this.status = RecordingStatus.idle,
    this.errorMessage,
    this.audioLevel,
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
  Timer? _recordingTimer;
  Timer? _levelTimer;

  VoiceRecordingNotifier() : super(const VoiceRecordingState()) {
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
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
    print('🎤 Requesting microphone permission...');
    
    final microphoneStatus = await Permission.microphone.request();
    print('🎤 Permission status: $microphoneStatus');
    
    if (microphoneStatus.isGranted) {
      print('🎤 Microphone permission granted!');
      return true;
    } else if (microphoneStatus.isPermanentlyDenied) {
      print('🎤 Microphone permission permanently denied');
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Microphone permission was permanently denied. Please enable it in iOS Settings → Eloqi Mobile → Microphone, then try again.',
      );
      return false;
    } else if (microphoneStatus.isDenied) {
      print('🎤 Microphone permission denied');
      state = state.copyWith(
        status: RecordingStatus.error,
        errorMessage: 'Microphone permission was denied. Please try again.',
      );
      return false;
    }
    
    print('🎤 Microphone permission: $microphoneStatus');
    return false;
  }

  Future<void> startRecording() async {
    print('🎤 Start recording button pressed');
    
    if (!await _requestPermissions()) {
      print('🎤 Permission check failed, cannot start recording');
      return;
    }

    print('🎤 Permission granted, proceeding with recording initialization');

    try {
      if (_recorder == null) {
        print('🎤 Initializing recorder...');
        await _initializeRecorder();
      }

      // Get the documents directory for storing the recording
      final appDirectory = await getApplicationDocumentsDirectory();
      final filePath = '${appDirectory.path}/voice_recording_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      state = state.copyWith(
        isRecording: true,
        status: RecordingStatus.recording,
        recordingPath: filePath,
        errorMessage: null,
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
        status: RecordingStatus.stopped,
        recordingPath: recordingPath,
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
    if (state.recordingPath == null) return;

    try {
      if (_player == null) {
        _player = FlutterSoundPlayer();
        await _player!.openPlayer();
      }

      await _player!.startPlayer(
        fromURI: state.recordingPath!,
        whenFinished: () {
          if (mounted) {
            state = state.copyWith(
              isPlaying: false,
              status: RecordingStatus.stopped,
            );
          }
        },
      );

      state = state.copyWith(
        isPlaying: true,
        status: RecordingStatus.playing,
      );

      print('🎤 Playing recording: ${state.recordingPath}');
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
      if (_player != null && _player!.isPlaying) {
        await _player!.stopPlayer();
      }
      state = state.copyWith(isPlaying: false, status: RecordingStatus.stopped);
    } catch (e) {
      debugPrint('❌ Error stopping playback: $e');
    }
  }

  Future<void> analyzeRecording(String audioFilePath) async {
    try {
      state = state.copyWith(status: RecordingStatus.analyzing);
      
      // For now, just mark as analyzed
      // The actual analysis will be triggered by the UI using VoiceAnalysisNotifier
      state = state.copyWith(status: RecordingStatus.analyzed);
      
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

    state = const VoiceRecordingState();
    debugPrint('🗑️ Recording cleared');
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _levelTimer?.cancel();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    super.dispose();
  }
}

// Voice Analysis Notifier
class VoiceAnalysisNotifier extends StateNotifier<AsyncValue<VoiceAnalysis?>> {
  final VoiceApiService _voiceApiService;

  VoiceAnalysisNotifier(this._voiceApiService) : super(const AsyncValue.data(null));

  Future<void> analyzeVoice(String audioFilePath) async {
    state = const AsyncValue.loading();

    try {
      final file = File(audioFilePath);
      
      if (!file.existsSync()) {
        throw Exception('Audio file not found');
      }

      debugPrint('🔬 Analyzing audio file: $audioFilePath');
      final analysis = await _voiceApiService.analyzeVoice(file);
      
      state = AsyncValue.data(analysis);
      debugPrint('✅ Voice analysis completed: ${analysis.detectedAccent}');
    } catch (e, stackTrace) {
      debugPrint('❌ Voice analysis error: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clearAnalysis() {
    state = const AsyncValue.data(null);
  }
}

// Accent Twin Notifier
class AccentTwinNotifier extends StateNotifier<AsyncValue<AccentTwin?>> {
  final VoiceApiService _voiceApiService;

  AccentTwinNotifier(this._voiceApiService) : super(const AsyncValue.data(null));

  Future<void> generateAccentTwin(String analysisId, String targetAccent) async {
    state = const AsyncValue.loading();

    try {
      debugPrint('🎭 Generating accent twin: $targetAccent for analysis: $analysisId');
      
      final request = {
        'original_analysis': analysisId,
        'target_accent': targetAccent,
        'tts_provider': 'elevenlabs', // Default to ElevenLabs
      };

      final accentTwin = await _voiceApiService.generateAccentTwin(request);
      
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
