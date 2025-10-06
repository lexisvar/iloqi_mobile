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
        // For macOS, use a simple, reliable path in the temp directory
        debugPrint('🎤 Using macOS-optimized recording configuration');
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        path = '${tempDir.path}/iloqi_recording_$timestamp.m4a';
        debugPrint('🎤 Recording to: $path');
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

      // Stop the recording
      await _recorder.stop();

      _isRecording = false;
      _recordingStateController.add(false);
      _stopTimers();

      debugPrint('🎤 Platform: ${Platform.operatingSystem}');

      // For macOS, use the path we set during start recording
      if (Platform.isMacOS && _currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);

        // Check if file exists and has content
        if (await file.exists()) {
          final size = await file.length();
          debugPrint('🎤 Recording file exists with size: $size bytes');

          if (size > 0) {
            debugPrint('🎤 Recording file has content');
            return _currentRecordingPath;
          } else {
            debugPrint('🎤 Recording file exists but is empty');
            return null;
          }
        } else {
          debugPrint('🎤 Recording file does not exist at expected path: $_currentRecordingPath');
          // Try to find it with a quick search
          return await _findRecordingFile();
        }
      } else {
        // For other platforms, get the path from the recorder
        final path = await _recorder.stop();
        if (path != null && await File(path).exists()) {
          _currentRecordingPath = path;
          return path;
        }
      }

      return null;
    } catch (e) {
      debugPrint('🎤 Failed to stop recording: $e');
      debugPrint('🎤 Error type: ${e.runtimeType}');
      debugPrint('🎤 Platform: ${Platform.operatingSystem}');

      _isRecording = false;
      _recordingStateController.add(false);
      _stopTimers();
      return null;
    }
  }

  /// Quick file search for when the expected path doesn't work
  Future<String?> _findRecordingFile() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = tempDir.path;

      // Look for our specific recording file pattern in temp directory
      final prefix = path.basenameWithoutExtension(_currentRecordingPath ?? '');
      final files = await tempDir.list().where((entity) {
        return entity is File && entity.path.contains(prefix);
      }).toList();

      if (files.isNotEmpty) {
        final file = files.first as File;
        final size = await file.length();
        if (size > 0) {
          debugPrint('🎤 Found recording file: ${file.path}');
          return file.path;
        }
      }
    } catch (e) {
      debugPrint('🎤 Error finding recording file: $e');
    }

    return null;
  }

  /// Handle macOS recording by searching for files in multiple locations
  Future<String?> _handleMacOSRecording() async {
    debugPrint('🎤 Searching for macOS recording files');

    // Expanded search directories including common macOS locations
    final searchDirectories = [
      await getTemporaryDirectory(),
      Directory.systemTemp,
      await getApplicationSupportDirectory(),
      await getApplicationDocumentsDirectory(),
      Directory('/tmp'), // macOS temp directory
      Directory('${Platform.environment['HOME'] ?? ''}/Library/Caches'),
      Directory('${Platform.environment['HOME'] ?? ''}/Documents'),
    ];

    // Search for files created in the last 90 seconds for macOS
    final cutoffTime = DateTime.now().subtract(const Duration(seconds: 90));

    for (final dir in searchDirectories) {
      try {
        if (!await dir.exists()) continue;

        debugPrint('🎤 Searching in: ${dir.path}');

        // Get all files and directories first
        final entities = await dir.list().toList();
        final recentFiles = <File>[];

        for (final entity in entities) {
          if (entity is File) {
            final fileName = path.basename(entity.path).toLowerCase();

            // Look for any file that might be a recording (broader search)
            if (fileName.endsWith('.m4a') || fileName.endsWith('.aac') ||
                fileName.endsWith('.wav') || fileName.endsWith('.caf') ||
                fileName.contains('recording') || fileName.contains('audio') ||
                fileName.contains('temp') || fileName.matches(r'^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}')) {
              try {
                final stat = await entity.stat();
                if (stat.modified.isAfter(cutoffTime)) {
                  recentFiles.add(entity);
                }
              } catch (e) {
                // File might be deleted or inaccessible, continue
              }
            }
          }
        }

        debugPrint('🎤 Found ${recentFiles.length} recent files in ${dir.path}');

        if (recentFiles.isNotEmpty) {
          // Sort by modification time (most recent first) and size (largest first)
          recentFiles.sort((a, b) {
            try {
              final statA = a.statSync();
              final statB = b.statSync();

              // First sort by modification time (most recent first)
              final timeCompare = statB.modified.compareTo(statA.modified);
              if (timeCompare != 0) return timeCompare;

              // Then by size (largest first) for same-time files
              return statB.size.compareTo(statA.size);
            } catch (e) {
              return 0;
            }
          });

          // Check the most recent files (up to 3) for valid recordings
          for (final recentFile in recentFiles.take(3)) {
            try {
              final size = await recentFile.length();
              final modified = recentFile.statSync().modified;
              debugPrint('🎤 Checking: ${recentFile.path} (${size} bytes, modified: $modified)');

              // More lenient size check for macOS recordings
              if (size > 512) { // At least 512 bytes
                debugPrint('🎤 Found valid recording file: ${recentFile.path}');
                _currentRecordingPath = recentFile.path;
                return recentFile.path;
              } else {
                debugPrint('🎤 File too small: ${size} bytes');
              }
            } catch (e) {
              debugPrint('🎤 Error checking file ${recentFile.path}: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('🎤 Error searching ${dir.path}: $e');
      }
    }

    debugPrint('🎤 No valid recording files found');

    // As a last resort, try to find any recently created files in common locations
    try {
      debugPrint('🎤 Attempting broader search for any recent files...');
      final homeDir = Platform.environment['HOME'];
      if (homeDir != null) {
        final commonDirs = [
          Directory('$homeDir/Desktop'),
          Directory('$homeDir/Downloads'),
          Directory('$homeDir/Documents'),
        ];

        for (final dir in commonDirs) {
          if (await dir.exists()) {
            final recentFiles = await dir
                .list()
                .where((entity) => entity is File)
                .cast<File>()
                .where((file) async {
                  try {
                    final stat = await file.stat();
                    return stat.modified.isAfter(cutoffTime) && await file.length() > 1024;
                  } catch (e) {
                    return false;
                  }
                })
                .toList();

            if (recentFiles.isNotEmpty) {
              debugPrint('🎤 Found ${recentFiles.length} recent files in ${dir.path}');
              // Return the most recently modified file as a fallback
              final fallbackFile = recentFiles.reduce((a, b) {
                try {
                  return a.statSync().modified.isAfter(b.statSync().modified) ? a : b;
                } catch (e) {
                  return a;
                }
              });

              debugPrint('🎤 Using fallback file: ${fallbackFile.path}');
              _currentRecordingPath = fallbackFile.path;
              return fallbackFile.path;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('🎤 Fallback search failed: $e');
    }

    debugPrint('🎤 No valid recording files found');
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
