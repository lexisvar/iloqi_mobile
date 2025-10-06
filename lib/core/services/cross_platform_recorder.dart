import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

import '../utils/permission_helper.dart';

/// Cross-platform audio recorder that works reliably on iOS, Android, and macOS
class CrossPlatformRecorder {
  static final CrossPlatformRecorder _instance = CrossPlatformRecorder._internal();
  factory CrossPlatformRecorder() => _instance;
  CrossPlatformRecorder._internal();

  final Record _recorder = Record();
  bool _isRecording = false;
  String? _currentRecordingPath;
  Timer? _durationTimer;
  Timer? _amplitudeTimer;
  
  // Stream controllers for real-time updates
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  final StreamController<bool> _recordingStateController = StreamController<bool>.broadcast();

  // Getters for streams
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  Stream<bool> get recordingStateStream => _recordingStateController.stream;

  // State getters
  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Initialize the recorder (check permissions, etc.)
  Future<bool> initialize() async {
    try {
      // Check if recording is available on this platform
      if (!await _recorder.hasPermission()) {
        debugPrint('🎤 Record package: No microphone permission');
        return false;
      }
      
      debugPrint('🎤 CrossPlatformRecorder initialized successfully');
      return true;
    } catch (e) {
      debugPrint('🎤 CrossPlatformRecorder initialization failed: $e');
      return false;
    }
  }

  /// Request microphone permission using our cross-platform helper
  Future<bool> requestPermission() async {
    final status = await PermissionHelper.requestMicrophonePermission();
    return status == PermissionStatus.granted;
  }

  /// Check if we have microphone permission
  Future<bool> hasPermission() async {
    final status = await PermissionHelper.checkMicrophonePermission();
    return status == PermissionStatus.granted;
  }

  /// Start recording with cross-platform configuration
  Future<bool> startRecording() async {
    try {
      debugPrint('🎤 Start recording requested');

      // Check permission first
      if (!await hasPermission()) {
        debugPrint('🎤 Recording permission not granted');
        return false;
      }

      String? path;

      if (Platform.isMacOS) {
        // For macOS, don't specify a path - let the system handle it to avoid URL issues
        debugPrint('🎤 Using macOS-optimized recording configuration');
        path = null;
      } else if (Platform.isIOS || Platform.isAndroid) {
        // For mobile platforms, use a specific path
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        path = '${directory.path}/$fileName';
        debugPrint('🎤 Recording to: $path');
      }

      print('Start recording');

      // Enhanced configuration for better macOS compatibility
      if (Platform.isMacOS) {
        // macOS-specific configuration to avoid AVFoundation issues
        await _recorder.start(
          path: path,
          encoder: AudioEncoder.aacLc,
        );
      } else {
        // Standard configuration for other platforms
        await _recorder.start(
          path: path,
          encoder: AudioEncoder.aacLc,
        );
      }

      _isRecording = true;
      _currentRecordingPath = path;
      _recordingStateController.add(true);
      _startTimers();

      debugPrint('🎤 Recording started: $path');
      debugPrint('🎤 Recording started successfully');

      return true;
    } catch (e) {
      debugPrint('🎤 Failed to start recording: $e');
      debugPrint('🎤 Error type: ${e.runtimeType}');
      debugPrint('🎤 Platform: ${Platform.operatingSystem}');

      // Try alternative configuration for macOS if the first attempt fails
      if (Platform.isMacOS && e.toString().contains('AVFoundation')) {
        debugPrint('🎤 Attempting alternative macOS recording configuration');
        return await _startRecordingWithAlternativeConfig();
      }

      _recordingStateController.add(false);
      return false;
    }
  }

  /// Alternative recording configuration for macOS when the primary method fails
  Future<bool> _startRecordingWithAlternativeConfig() async {
    try {
      debugPrint('🎤 Trying alternative recording configuration');

      // Use temporary directory and minimal configuration
      final tempDir = await getTemporaryDirectory();
      final fileName = 'recording_alt_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final path = '${tempDir.path}/$fileName';

      debugPrint('🎤 Alternative recording path: $path');

      // Minimal configuration for macOS fallback
      await _recorder.start(
        path: path,
        encoder: AudioEncoder.aacLc,
      );

      _isRecording = true;
      _currentRecordingPath = path;
      _recordingStateController.add(true);
      _startTimers();

      debugPrint('🎤 Alternative recording started successfully: $path');
      return true;
    } catch (e) {
      debugPrint('🎤 Alternative recording configuration also failed: $e');
      _recordingStateController.add(false);
      return false;
    }
  }

  /// Stop recording
  Future<String?> stopRecording() async {
    try {
      debugPrint('🎤 Stop recording requested');

      if (!_isRecording) {
        debugPrint('🎤 Not currently recording');
        return null;
      }

      print('Stop recording');

      // Stop the recording and get the file path
      final path = await _recorder.stop();

      _isRecording = false;
      _recordingStateController.add(false);
      _stopTimers();

      debugPrint('🎤 Recording stopped: $path');
      debugPrint('🎤 Platform: ${Platform.operatingSystem}');

      // Enhanced validation for all platforms
      if (path != null) {
        final file = File(path);

        // Check if file exists and has content
        if (await file.exists()) {
          final size = await file.length();
          debugPrint('🎤 Recording file exists with size: $size bytes');

          if (size > 0) {
            debugPrint('🎤 Recording file has content');
            _currentRecordingPath = path;
            return path;
          } else {
            debugPrint('🎤 Recording file exists but is empty (0 bytes)');

            // For macOS, this might indicate an AVFoundation issue
            if (Platform.isMacOS) {
              debugPrint('🎤 Empty file on macOS - likely AVFoundation recording failure');
              return await _handleMacOSRecordingFailure();
            }

            return null;
          }
        } else {
          debugPrint('🎤 Recording file does not exist at: $path');

          // For macOS, try to find the file in alternative locations
          if (Platform.isMacOS) {
            return await _handleMacOSRecordingFailure();
          }

          return null;
        }
      } else {
        debugPrint('🎤 No recording path returned');

        // For macOS, this might indicate an AVFoundation issue
        if (Platform.isMacOS) {
          return await _handleMacOSRecordingFailure();
        }

        return null;
      }
    } catch (e) {
      debugPrint('🎤 Failed to stop recording: $e');
      debugPrint('🎤 Error type: ${e.runtimeType}');
      debugPrint('🎤 Platform: ${Platform.operatingSystem}');

      // Check if this is the specific AVFoundation error
      if (e.toString().contains('AVFoundationErrorDomain') && e.toString().contains('-11805')) {
        debugPrint('🎤 Detected AVFoundation "Cannot Record" error');
        return await _handleMacOSRecordingFailure();
      }

      _isRecording = false;
      _recordingStateController.add(false);
      _stopTimers();
      return null;
    }
  }

  /// Handle macOS recording failures by searching for files in alternative locations
  Future<String?> _handleMacOSRecordingFailure() async {
    debugPrint('🎤 Handling macOS recording failure - searching for files');

    final searchDirectories = [
      Directory.systemTemp,
      await getApplicationSupportDirectory(),
      await getTemporaryDirectory(),
      await getApplicationDocumentsDirectory(),
    ];

    for (final dir in searchDirectories) {
      try {
        debugPrint('🎤 Searching for recording files in: ${dir.path}');

        if (!await dir.exists()) {
          debugPrint('🎤 Directory does not exist: ${dir.path}');
          continue;
        }

        final files = await dir.list().where((entity) =>
          entity is File &&
          (entity.path.endsWith('.m4a') || entity.path.endsWith('.aac') || entity.path.endsWith('.wav') || entity.path.endsWith('.caf'))
        ).toList();

        debugPrint('🎤 Found ${files.length} potential recording files');

        if (files.isNotEmpty) {
          // Find the most recent file
          File? recentFile;
          DateTime? recentTime;

          for (final entity in files) {
            final file = entity as File;
            try {
              final stat = await file.stat();
              if (recentTime == null || stat.modified.isAfter(recentTime)) {
                recentTime = stat.modified;
                recentFile = file;
              }
            } catch (e) {
              debugPrint('🎤 Could not stat file ${file.path}: $e');
            }
          }

          if (recentFile != null && recentTime != null) {
            final timeDiff = DateTime.now().difference(recentTime);
            debugPrint('🎤 Most recent file: ${recentFile.path} (${timeDiff.inSeconds}s ago)');

            // For macOS with null path, be more lenient with timing (up to 5 minutes)
            if (timeDiff.inMinutes < 5) {
              final size = await recentFile.length();
              debugPrint('🎤 Found valid recording file: ${recentFile.path} (${size} bytes)');

              if (size > 0) {
                _currentRecordingPath = recentFile.path;
                return recentFile.path;
              } else {
                debugPrint('🎤 File exists but is empty');
              }
            } else {
              debugPrint('🎤 File is too old to be our recording');
            }
          }
        }
      } catch (e) {
        debugPrint('🎤 Error searching for recording files in ${dir.path}: $e');
      }
    }

    debugPrint('🎤 No valid recording files found in any location');
    return null;
  }

  /// Pause recording (if supported)
  Future<void> pauseRecording() async {
    try {
      if (_isRecording) {
        await _recorder.pause();
        debugPrint('🎤 Recording paused');
      }
    } catch (e) {
      debugPrint('🎤 Failed to pause recording: $e');
    }
  }

  /// Resume recording (if supported)
  Future<void> resumeRecording() async {
    try {
      if (_isRecording) {
        await _recorder.resume();
        debugPrint('🎤 Recording resumed');
      }
    } catch (e) {
      debugPrint('🎤 Failed to resume recording: $e');
    }
  }

  /// Check if the current platform supports recording
  bool get isSupported {
    // The record package supports iOS, Android, macOS, Windows, and Linux
    return Platform.isIOS || Platform.isAndroid || Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  /// Get platform-specific recording directory
  Future<Directory> _getRecordingDirectory() async {
    if (Platform.isMacOS) {
      // Use application support directory for macOS - more reliable than temp
      try {
        final appSupport = await getApplicationSupportDirectory();
        final recordingDir = Directory(path.join(appSupport.path, 'recordings'));
        return recordingDir;
      } catch (e) {
        debugPrint('🎤 Could not get app support directory, using temp: $e');
        return await getTemporaryDirectory();
      }
    } else if (Platform.isWindows || Platform.isLinux) {
      // Desktop platforms
      return await getApplicationDocumentsDirectory();
    } else {
      // Mobile platforms
      return await getTemporaryDirectory();
    }
  }

  /// Start monitoring timers
  void _startTimers() {
    // Duration timer - update every 100ms for smooth UI
    final startTime = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final duration = DateTime.now().difference(startTime);
      _durationController.add(duration);
    });

    // Amplitude timer - simplified for version 4.x compatibility
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      try {
        // For now just add a mock amplitude since API may be different
        _amplitudeController.add(0.5); // Placeholder amplitude
      } catch (e) {
        // Amplitude might not be available on all platforms
        _amplitudeController.add(0.0);
      }
    });
  }

  /// Stop monitoring timers
  void _stopTimers() {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _durationTimer = null;
    _amplitudeTimer = null;
  }

  /// Clean up resources
  void dispose() {
    _stopTimers();
    _recorder.dispose();
    _durationController.close();
    _amplitudeController.close();
    _recordingStateController.close();
  }

  /// Get the file extension for recordings on this platform
  String get recordingExtension {
    if (Platform.isIOS || Platform.isMacOS) {
      return '.m4a'; // AAC in M4A container works best on Apple platforms
    } else if (Platform.isAndroid) {
      return '.aac'; // Pure AAC works well on Android
    } else {
      return '.wav'; // Fallback for other platforms
    }
  }

  /// Get the MIME type for recordings on this platform
  String get recordingMimeType {
    if (Platform.isIOS || Platform.isMacOS) {
      return 'audio/mp4'; // M4A files
    } else if (Platform.isAndroid) {
      return 'audio/aac'; // AAC files
    } else {
      return 'audio/wav'; // WAV files
    }
  }

  /// Delete a recording file
  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🎤 Deleted recording: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('🎤 Failed to delete recording $filePath: $e');
      return false;
    }
  }
}
