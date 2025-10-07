import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/permission_helper.dart';

/// Simplified cross-platform audio recorder using the record package
class CrossPlatformRecorderSimple {
  static final CrossPlatformRecorderSimple _instance = CrossPlatformRecorderSimple._internal();
  factory CrossPlatformRecorderSimple() => _instance;
  CrossPlatformRecorderSimple._internal();

  final AudioRecorder _recorder = AudioRecorder();
  
  // Debug mode for development (simulates microphone input when no real input available)
  static const bool _debugMode = kDebugMode;
  
  // State variables
  bool _isRecording = false;
  String? _currentRecordingPath;
  
  // Stream controllers for real-time updates
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  final StreamController<bool> _recordingStateController = StreamController<bool>.broadcast();
  
  // Timers for monitoring
  Timer? _durationTimer;
  Timer? _amplitudeTimer;

  // Stream getters
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  Stream<bool> get recordingStateStream => _recordingStateController.stream;

  // State getters
  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;
  bool get isSupported => true; // The record package handles platform support internally

  /// Initialize the recorder (check permissions, etc.)
  Future<bool> initialize() async {
    try {
      // Check if recording is available on this platform
      if (!await hasPermission()) {
        debugPrint('🎤 Record package: No microphone permission');
        return false;
      }
      
      debugPrint('🎤 CrossPlatformRecorderSimple initialized successfully');
      return true;
    } catch (e) {
      debugPrint('🎤 CrossPlatformRecorderSimple initialization failed: $e');
      return false;
    }
  }

  /// Check if we have microphone permission
  Future<bool> hasPermission() async {
    try {
      // Use the same record package method for consistency
      return await _recorder.hasPermission();
    } catch (e) {
      print('🎤 Error checking permission: $e');
      return false;
    }
  }

  /// Request microphone permission using native dialog
  Future<bool> requestPermission() async {
    try {
      print('🎤 Requesting native microphone permission...');
      
      // Check current status first
      final currentStatus = await PermissionHelper.checkMicrophonePermission();
      if (currentStatus.isGranted) {
        print('🎤 Permission already granted');
        return true;
      }
      
      // Use the record package's built-in permission request
      // This will trigger the native iOS permission dialog
      final hasPermission = await _recorder.hasPermission();
      
      if (hasPermission) {
        print('🎤 Native permission dialog granted access');
        return true;
      } else {
        print('🎤 Native permission dialog denied access');
        return false;
      }
    } catch (e) {
      print('🎤 Error requesting permission: $e');
      return false;
    }
  }

  /// Start recording following AI overview best practices
  Future<bool> startRecording() async {
    try {
      print('🎤 Start recording requested');

      // Check permissions first
      if (!(await hasPermission())) {
        print('🎤 Recording permission not granted');
        return false;
      }

      final path = await _getRecordingPath();
      print('🎤 Recording to file path: $path');

      // Verify directory exists
      final file = File(path);
      final directory = file.parent;
      print('🎤 Directory: ${directory.path}');
      print('🎤 Directory exists: ${await directory.exists()}');

      // Configure audio session for iOS
      if (Platform.isIOS) {
        try {
          print('🎤 iOS: Configuring audio session');
          final session = await AudioSession.instance;
          await session.configure(AudioSessionConfiguration(
            avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
            avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker | 
                                          AVAudioSessionCategoryOptions.allowBluetooth,
            avAudioSessionMode: AVAudioSessionMode.defaultMode,
            avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
            avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
            androidAudioAttributes: const AndroidAudioAttributes(
              contentType: AndroidAudioContentType.speech,
              flags: AndroidAudioFlags.none,
              usage: AndroidAudioUsage.voiceCommunication,
            ),
            androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
            androidWillPauseWhenDucked: true,
          ));
          await session.setActive(true);
          print('🎤 iOS: Audio session configured and activated successfully');
        } catch (e) {
          print('🎤 iOS: Audio session configuration failed: $e');
          // Continue anyway, maybe it will work
        }
      }

      // Platform-specific configuration
      if (Platform.isMacOS) {
        print('🎤 macOS: Using minimal configuration');
        const config = RecordConfig();
        await _recorder.start(config, path: path);
      } else {
        // iOS and other platforms - using WAV for better simulator compatibility
        print('🎤 Using WAV format for better simulator compatibility');
        const config = RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000,       // Standard bitrate for WAV
          sampleRate: 16000,     // Voice-optimized sample rate
          numChannels: 1,        // Mono for voice
        );
        await _recorder.start(config, path: path);
      }

      _currentRecordingPath = path;
      _isRecording = true;
      print('🎤 Recording started successfully');
      print('🎤 Stored recording path: $_currentRecordingPath');
      
      // Start monitoring amplitude to check if we're receiving audio
      _startAmplitudeMonitoring();
      _startTimers();
      _recordingStateController.add(true);
      
      return true;
    } catch (e) {
      print('🎤 Error starting recording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Start basic amplitude monitoring to verify audio input
  void _startAmplitudeMonitoring() {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      try {
        final amplitude = await _recorder.getAmplitude();
        
        // In debug mode, simulate realistic microphone input if no real input detected
        if (_debugMode && amplitude.current <= -100.0) {
          // Simulate realistic voice input levels
          final simulatedLevel = -20.0 + (DateTime.now().millisecondsSinceEpoch % 1000) / 100.0;
          print('🎤 [DEBUG MODE] Simulated audio level: ${simulatedLevel.toStringAsFixed(2)} dB');
          print('🎤 [DEBUG MODE] ✅ Simulated audio input detected!');
        } else {
          print('🎤 Audio level - Current: ${amplitude.current.toStringAsFixed(2)}, Max: ${amplitude.max.toStringAsFixed(2)}');
          
          if (amplitude.current > -60.0) {  // Reasonable threshold for voice detection
            print('🎤 ✅ Audio input detected!');
          } else {
            print('🎤 ⚠️ Very low or no audio input');
            if (_debugMode) {
              print('🎤 [DEBUG MODE] This is normal in iOS Simulator - real device would have microphone access');
            }
          }
        }
      } catch (e) {
        print('🎤 Could not read amplitude: $e');
        if (_debugMode) {
          print('🎤 [DEBUG MODE] Simulating successful recording for development');
        }
      }
    });
  }

  /// Stop recording following AI overview best practices
  Future<String?> stopRecording() async {
    try {
      debugPrint('🎤 Stop recording requested');
      
      if (!_isRecording) {
        debugPrint('🎤 Not currently recording, ignoring stop request');
        return null;
      }

      String? path;
      
      // For macOS, try using cancel() as a workaround for AVFoundation -11805 issue
      if (Platform.isMacOS) {
        debugPrint('🎤 macOS: Using cancel() workaround for AVFoundation issues');
        
        // Add a small delay before canceling to ensure recording is stable
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          // Use cancel() instead of stop() for macOS to avoid -11805 error
          await _recorder.cancel();
          debugPrint('🎤 macOS: Recording canceled successfully');
          
          // Try to return the file path we were recording to
          if (_currentRecordingPath != null) {
            debugPrint('🎤 macOS: Looking for file at: $_currentRecordingPath');
            final file = File(_currentRecordingPath!);
            
            // Give the system time to finalize the file
            await Future.delayed(const Duration(seconds: 2));
            
            if (await file.exists()) {
              final size = await file.length();
              debugPrint('🎤 macOS: Found recording file: ${file.path} (${size} bytes)');
              
              if (size > 0) {
                path = _currentRecordingPath;
              } else {
                debugPrint('🎤 macOS: File exists but is empty, waiting a bit more...');
                await Future.delayed(const Duration(seconds: 1));
                final newSize = await file.length();
                if (newSize > 0) {
                  debugPrint('🎤 macOS: File now has content: ${newSize} bytes');
                  path = _currentRecordingPath;
                } else {
                  debugPrint('🎤 macOS: File remains empty after additional wait');
                }
              }
            } else {
              debugPrint('🎤 macOS: Recording file not found');
            }
          }
        } catch (e) {
          debugPrint('🎤 macOS: Cancel failed: $e');
          // Try fallback file check
          if (_currentRecordingPath != null) {
            final file = File(_currentRecordingPath!);
            if (await file.exists() && await file.length() > 0) {
              path = _currentRecordingPath;
            }
          }
        }
      } else {
        // For other platforms, use the standard stop() method
        debugPrint('🎤 Using standard stop() method');
        path = await _recorder.stop();
        
        // Verify the file was created and has content
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            final size = await file.length();
            print('🎤 Recording file created: $path (${size} bytes)');
            
            if (size == 0) {
              print('🎤 ⚠️ Warning: Recording file is empty! This might indicate an issue with audio input or permissions.');
              
              if (_debugMode) {
                print('🎤 [DEBUG MODE] Empty file is expected in iOS Simulator without microphone access');
                print('🎤 [DEBUG MODE] On a real device, this file would contain actual audio data');
                print('🎤 [DEBUG MODE] Creating a small dummy audio file for testing...');
                
                try {
                  // Create a minimal valid audio file for testing
                  await _createDummyAudioFile(path);
                  final newSize = await file.length();
                  print('🎤 [DEBUG MODE] Created dummy audio file: ${newSize} bytes');
                } catch (e) {
                  print('🎤 [DEBUG MODE] Could not create dummy file: $e');
                }
              }
              
              // Wait a moment and check again
              await Future.delayed(const Duration(milliseconds: 500));
              final newSize = await file.length();
              print('🎤 File size after delay: ${newSize} bytes');
            }
          } else {
            print('🎤 ⚠️ Recording file does not exist at: $path');
          }
        }
      }
      
      // Update state
      _isRecording = false;
      _stopTimers();
      _recordingStateController.add(false);
      
      if (path != null) {
        debugPrint('🎤 Recording stopped successfully: $path');
      } else {
        debugPrint('🎤 Recording stopped but no file path returned');
      }
      
      // Clear current recording path
      _currentRecordingPath = null;
      return path;
      
    } catch (e) {
      debugPrint('🎤 Failed to stop recording: $e');
      
      // Special handling for AVFoundation -11805 error
      if (e.toString().contains('-11805') || e.toString().contains('Cannot Record')) {
        debugPrint('🎤 Detected AVFoundation -11805 error, attempting workaround...');
        
        // Reset state to allow retry
        _isRecording = false;
        _stopTimers();
        _recordingStateController.add(false);
        
        // Try to salvage the file if it exists
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            final size = await file.length();
            debugPrint('🎤 Attempting to salvage file: ${file.path} (${size} bytes)');
            
            if (size > 0) {
              final result = _currentRecordingPath;
              _currentRecordingPath = null;
              return result;
            }
          }
        }
      }
      
      // Clean up state
      _isRecording = false;
      _stopTimers();
      _recordingStateController.add(false);
      _currentRecordingPath = null;
      return null;
    }
  }

  /// Create a dummy audio file for testing in debug mode
  Future<void> _createDummyAudioFile(String path) async {
    if (!_debugMode) return;
    
    final file = File(path);
    
    // Create a minimal WAV file with proper header
    final dummyWavData = <int>[
      // WAV header
      0x52, 0x49, 0x46, 0x46, // "RIFF"
      0x2C, 0x00, 0x00, 0x00, // File size - 8 (36 bytes for this example)
      0x57, 0x41, 0x56, 0x45, // "WAVE"
      
      // Format chunk
      0x66, 0x6D, 0x74, 0x20, // "fmt "
      0x10, 0x00, 0x00, 0x00, // Chunk size (16 bytes)
      0x01, 0x00,             // Audio format (1 = PCM)
      0x01, 0x00,             // Number of channels (1 = mono)
      0x40, 0x1F, 0x00, 0x00, // Sample rate (8000 Hz)
      0x80, 0x3E, 0x00, 0x00, // Byte rate (16000)
      0x02, 0x00,             // Block align (2)
      0x10, 0x00,             // Bits per sample (16)
      
      // Data chunk
      0x64, 0x61, 0x74, 0x61, // "data"
      0x08, 0x00, 0x00, 0x00, // Data chunk size (8 bytes)
      
      // Audio data (8 bytes of silence - 4 samples of 16-bit mono)
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    ];
    
    await file.writeAsBytes(dummyWavData);
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    try {
      debugPrint('🎤 Pause recording requested');
      
      if (!_isRecording) {
        debugPrint('🎤 Not currently recording');
        return;
      }

      await _recorder.pause();
      debugPrint('🎤 Recording paused successfully');
    } catch (e) {
      debugPrint('🎤 Failed to pause recording: $e');
      throw e;
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    try {
      debugPrint('🎤 Resume recording requested');
      
      if (!_isRecording) {
        debugPrint('🎤 Not currently recording');
        return;
      }

      await _recorder.resume();
      debugPrint('🎤 Recording resumed successfully');
    } catch (e) {
      debugPrint('🎤 Failed to resume recording: $e');
      throw e;
    }
  }

  /// Get recording file path
  Future<String> _getRecordingPath() async {
    if (Platform.isMacOS) {
      // Use temporary directory for macOS
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '${tempDir.path}/recording_$timestamp.wav';
    } else {
      // Use documents directory for other platforms
      final documentsDir = await getApplicationDocumentsDirectory();
      return '${documentsDir.path}/my_audio.wav';  // Using .wav for better compatibility
    }
  }

  /// Start the duration and amplitude monitoring timers
  void _startTimers() {
    // Duration timer - update every 100ms
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_isRecording) {
        // Estimate duration based on timer ticks (more reliable than querying recorder)
        final duration = Duration(milliseconds: timer.tick * 100);
        _durationController.add(duration);
      }
    });

    // Amplitude timer - update every 100ms
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_isRecording) {
        try {
          final amplitude = await _recorder.getAmplitude();
          final normalizedAmplitude = amplitude.current / amplitude.max;
          _amplitudeController.add(normalizedAmplitude.clamp(0.0, 1.0));
        } catch (e) {
          // If amplitude reading fails, just send 0
          _amplitudeController.add(0.0);
        }
      }
    });
  }

  /// Stop the duration and amplitude monitoring timers
  void _stopTimers() {
    _durationTimer?.cancel();
    _durationTimer = null;
    
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    
    // Reset streams
    _durationController.add(Duration.zero);
    _amplitudeController.add(0.0);
  }

  /// Dispose of resources
  void dispose() {
    _stopTimers();
    _durationController.close();
    _amplitudeController.close();
    _recordingStateController.close();
    _recorder.dispose();
  }
}
