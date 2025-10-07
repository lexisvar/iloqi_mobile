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

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isStoppingRecording = false; // Prevent multiple simultaneous stop attempts
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
  bool get isRecording {
    // In the new version, we'll rely on our internal flag
    // since _recorder.isRecording is now async
    return _isRecording;
  }
  String? get currentRecordingPath => _currentRecordingPath;

  /// Initialize the recorder (check permissions, etc.)
  Future<bool> initialize() async {
    try {
      // Check if recording is available on this platform
      if (!await hasPermission()) {
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

  /// Test the recording interface (for debugging/validation)
  Future<bool> testRecordingInterface() async {
    try {
      debugPrint('🎤 Testing recording interface...');
      
      // Check permission
      if (!await hasPermission()) {
        debugPrint('🎤 Test failed: No microphone permission');
        return false;
      }
      
      // Test platform support
      if (!isSupported) {
        debugPrint('🎤 Test failed: Platform not supported');
        return false;
      }
      
      // Test recorder availability
      if (!await hasPermission()) {
        debugPrint('🎤 Test failed: Recorder permission check failed');
        return false;
      }
      
      debugPrint('🎤 Recording interface test passed ✅');
      return true;
    } catch (e) {
      debugPrint('🎤 Recording interface test failed: $e');
      return false;
    }
  }

  /// Start recording following AI overview best practices
  Future<bool> startRecording() async {
    try {
      debugPrint('🎤 Start recording requested');

      // Step 1: Check permissions exactly as recommended
      if (await _recorder.hasPermission()) {
        // Step 2: Define file path exactly as in AI overview
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/my_audio.m4a'; // Exact pattern from AI overview
        
        debugPrint('🎤 Recording to file path: $filePath');

        // Step 3: Start recording with exact configuration from AI overview
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc), // Choose an appropriate encoder (from AI overview)
          path: filePath,
        );

        // Update internal state
        _isRecording = true;
        _currentRecordingPath = filePath;
        _recordingStateController.add(true);
        _startTimers();

        debugPrint('🎤 Recording started successfully');
        return true;
      } else {
        // Handle permission denial exactly as in AI overview
        debugPrint('🎤 Permission denied - cannot start recording');
        return false;
      }
    } catch (e) {
      debugPrint('🎤 Failed to start recording: $e');
      _recordingStateController.add(false);
      return false;
    }
  }

  /// Stop recording following AI overview best practices
  Future<String?> stopRecording() async {
    try {
      debugPrint('🎤 Stop recording requested');
      
      if (!_isRecording) {
        debugPrint('🎤 Not currently recording');
        return null;
      }

      // Simple stop following AI overview pattern
      final path = await _recorder.stop();
      
      // Update state
      _isRecording = false;
      _stopTimers();
      _recordingStateController.add(false);
      
      debugPrint('🎤 Recording stopped successfully: $path');
      
      // Return the path where the audio file is saved (as in AI overview)
      _currentRecordingPath = null;
      return path;
      
    } catch (e) {
      debugPrint('🎤 Failed to stop recording: $e');
      _isRecording = false;
      _stopTimers();
      _recordingStateController.add(false);
      return null;
    }
  }

  /// Check if platform supports recording
  bool get isSupported {
    // The record package supports iOS, Android, and macOS
    return Platform.isIOS || Platform.isAndroid || Platform.isMacOS;
  }

  /// Handle recorder timeout with aggressive recovery
  Future<String?> _handleRecorderTimeout() async {
    debugPrint('🎤 Handling recorder timeout - trying recovery methods');
    
    // Force update state immediately
    await _updateStateAfterStop();
    
    // Try cancel with its own timeout - but don't wait if it hangs
    debugPrint('🎤 Trying cancel() with timeout...');
    try {
      await Future.any([
        _recorder.cancel(),
        Future.delayed(const Duration(seconds: 1), () {
          throw TimeoutException('cancel() timed out', const Duration(seconds: 1));
        }),
      ]);
      debugPrint('🎤 Cancel completed successfully');
    } on TimeoutException {
      debugPrint('🎤 Cancel also timed out - proceeding with file recovery');
    } catch (e) {
      debugPrint('🎤 Cancel failed: $e - proceeding with file recovery');
    }
    
    // Try dispose with very short timeout
    debugPrint('🎤 Trying dispose() with timeout...');
    try {
      await Future.any([
        Future(() => _recorder.dispose()),
        Future.delayed(const Duration(milliseconds: 500), () {
          throw TimeoutException('dispose() timed out', const Duration(milliseconds: 500));
        }),
      ]);
      debugPrint('🎤 Dispose completed successfully');
    } on TimeoutException {
      debugPrint('🎤 Dispose also timed out - abandoning recorder');
    } catch (e) {
      debugPrint('🎤 Dispose failed: $e - abandoning recorder');
    }
    
    // Always try to recover any existing recording file
    debugPrint('🎤 Attempting file recovery regardless of recorder state');
    return await _tryReturnStoredRecording();
  }

  /// Handle AVFoundation-specific errors with aggressive recovery
  Future<String?> _handleAVFoundationError() async {
    debugPrint('🎤 Handling AVFoundation error with aggressive recovery...');
    
    // Don't wait for the recorder - just immediately try to find the file
    await _updateStateAfterStop();
    
    // Try multiple recovery strategies in parallel
    final recoveryFutures = [
      _tryReturnStoredRecording(),
      _findAlternativeRecordingFile(),
      Future.delayed(const Duration(milliseconds: 500), () => _searchSystemTempDirectories()),
    ];
    
    try {
      // Return the first successful result
      final results = await Future.wait(recoveryFutures, eagerError: false);
      
      for (final result in results) {
        if (result != null && result.isNotEmpty) {
          debugPrint('🎤 Recovery successful: $result');
          return result;
        }
      }
      
      debugPrint('🎤 All recovery attempts failed');
      return null;
    } catch (e) {
      debugPrint('🎤 Recovery attempts failed: $e');
      return null;
    }
  }

  /// Try alternative stop methods for AVFoundation errors
  Future<String?> _tryAlternativeStop() async {
    try {
      debugPrint('🎤 Trying cancel() with timeout for AVFoundation error...');
      await Future.any([
        _recorder.cancel(),
        Future.delayed(const Duration(seconds: 2), () {
          throw TimeoutException('cancel() timed out', const Duration(seconds: 2));
        }),
      ]);
      debugPrint('🎤 Recording cancelled successfully');
      await _updateStateAfterStop();
      
      // Return the stored path if the file exists
      return await _tryReturnStoredRecording();
    } on TimeoutException {
      debugPrint('🎤 Cancel timed out');
    } catch (cancelError) {
      debugPrint('🎤 Cancel also failed: $cancelError');
    }
    
    // Final fallback
    await _updateStateAfterStop();
    return await _tryReturnStoredRecording();
  }

  /// Standard stop recording for non-macOS platforms
  Future<String?> _stopRecordingStandard() async {
    debugPrint('🎤 About to check recorder.isRecording()...');
    
    // Check the actual recorder state (now async in v6.x)
    bool recorderIsRecording;
    try {
      recorderIsRecording = await _recorder.isRecording();
      debugPrint('🎤 Recorder.isRecording = $recorderIsRecording');
    } catch (e) {
      debugPrint('🎤 Error checking recorder.isRecording(): $e');
      // Assume it's recording if we can't check
      recorderIsRecording = true;
    }

    if (!recorderIsRecording) {
      debugPrint('🎤 Recorder reports it is not recording');
      await _updateStateAfterStop();
      return null;
    }

    debugPrint('🎤 About to call recorder.stop()...');
    print('Stop recording');

    final recordingPath = await _recorder.stop();
    debugPrint('🎤 Recording stopped. Returned path: $recordingPath');

    await _updateStateAfterStop();
    return await _verifyAndReturnRecording(recordingPath);
  }

  /// Update internal state after stopping recording
  Future<void> _updateStateAfterStop() async {
    _isRecording = false;
    _recordingStateController.add(false);
    _stopTimers();
  }

  /// Verify recording file and return path
  Future<String?> _verifyAndReturnRecording(String? recordingPath) async {
    if (recordingPath != null) {
      final file = File(recordingPath);
      
      debugPrint('🎤 Checking if file exists: ${file.path}');
      
      // Give the system a moment to finalize the file
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (await file.exists()) {
        final size = await file.length();
        debugPrint('🎤 Recording file exists with size: $size bytes');
        
        if (size > 0) {
          debugPrint('🎤 Recording completed successfully');
          _currentRecordingPath = null;
          return recordingPath;
        } else {
          debugPrint('🎤 Recording file is empty, waiting a bit more...');
          await Future.delayed(const Duration(milliseconds: 1000));
          final newSize = await file.length();
          if (newSize > 0) {
            debugPrint('🎤 Recording file now has content: $newSize bytes');
            _currentRecordingPath = null;
            return recordingPath;
          } else {
            debugPrint('🎤 Recording file is still empty after waiting');
          }
        }
      } else {
        debugPrint('🎤 Recording file does not exist at: $recordingPath');
      }
    } else {
      debugPrint('🎤 No recording path returned from stop()');
    }

    // Try to return stored recording as fallback
    return await _tryReturnStoredRecording();
  }

  /// Try to return the stored recording path
  Future<String?> _tryReturnStoredRecording() async {
    if (_currentRecordingPath != null) {
      debugPrint('🎤 Trying to find file at stored path: $_currentRecordingPath');
      final file = File(_currentRecordingPath!);
      
      // Give the system more time to finalize the file on macOS
      if (Platform.isMacOS) {
        debugPrint('🎤 macOS: Waiting longer for file to be finalized...');
        await Future.delayed(const Duration(seconds: 2));
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (await file.exists()) {
        final size = await file.length();
        debugPrint('🎤 Found recording file at stored path with size: $size bytes');
        
        if (size > 0) {
          final result = _currentRecordingPath;
          _currentRecordingPath = null;
          debugPrint('🎤 Successfully returning recording: $result');
          return result;
        } else {
          debugPrint('🎤 File exists but is empty, waiting a bit more...');
          await Future.delayed(const Duration(seconds: 1));
          final newSize = await file.length();
          if (newSize > 0) {
            final result = _currentRecordingPath;
            _currentRecordingPath = null;
            debugPrint('🎤 File now has content, returning: $result');
            return result;
          }
        }
      } else {
        debugPrint('🎤 No file found at stored path: $_currentRecordingPath');
        
        // On macOS, try alternative search in case the path changed
        if (Platform.isMacOS) {
          debugPrint('🎤 macOS: Searching for alternative recording files...');
          return await _findAlternativeRecordingFile();
        }
      }
    }

    debugPrint('🎤 No valid recording found');
    _currentRecordingPath = null;
    return null;
  }

  /// Search for alternative recording files on macOS
  Future<String?> _findAlternativeRecordingFile() async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final directory = Directory(documentsDir.path);
      
      if (!await directory.exists()) {
        debugPrint('🎤 Documents directory does not exist');
        return null;
      }

      debugPrint('🎤 Searching for recent audio files in: ${documentsDir.path}');
      
      // Search for all audio files (prioritize WAV on macOS)
      final audioExtensions = Platform.isMacOS 
        ? ['.wav', '.m4a', '.aac', '.mp3', '.caf'] 
        : ['.m4a', '.aac', '.wav', '.mp3', '.caf'];
      final files = <File>[];
      
      await for (final entity in directory.list()) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if (audioExtensions.any((ext) => path.endsWith(ext))) {
            files.add(entity);
          }
        }
      }

      // Also search in Application Support directory on macOS
      if (Platform.isMacOS) {
        try {
          final appSupportDir = Directory('${Platform.environment['HOME']}/Library/Application Support/com.iloqi.mobile');
          if (await appSupportDir.exists()) {
            debugPrint('🎤 macOS: Also searching Application Support directory');
            await for (final entity in appSupportDir.list()) {
              if (entity is File) {
                final path = entity.path.toLowerCase();
                if (audioExtensions.any((ext) => path.endsWith(ext))) {
                  files.add(entity);
                }
              }
            }
          }
        } catch (e) {
          debugPrint('🎤 macOS: Error accessing Application Support directory: $e');
        }
      }

      if (files.isEmpty) {
        debugPrint('🎤 No audio files found in documents directory');
        
        // Also check system temporary directories
        return await _searchSystemTempDirectories();
      }

      // Sort by modification time, most recent first
      files.sort((a, b) {
        final aStats = a.statSync();
        final bStats = b.statSync();
        return bStats.modified.compareTo(aStats.modified);
      });

      // Check files in order of recency
      for (final file in files.take(3)) { // Check top 3 most recent files
        final size = await file.length();
        final modTime = file.statSync().modified;
        final age = DateTime.now().difference(modTime);
        
        debugPrint('🎤 Found audio file: ${file.path} (${size} bytes, ${age.inSeconds}s old)');
        
        // Only consider files created in the last 30 seconds
        if (size > 0 && age.inSeconds < 30) {
          debugPrint('🎤 Using recent audio file as recording result');
          return file.path;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('🎤 Error searching for alternative recording file: $e');
      return null;
    }
  }

  /// Search system temporary directories for recording files
  Future<String?> _searchSystemTempDirectories() async {
    if (!Platform.isMacOS) return null;
    
    try {
      // Common macOS temp directories where AVFoundation might save files
      final tempPaths = [
        '/tmp', // Our fallback directory
        Directory.systemTemp.path,
        '${Platform.environment['HOME']}/Library/Caches',
        '${Platform.environment['HOME']}/Library/Application Support',
        '/var/folders', // macOS system temp folders
      ];
      
      for (final tempPath in tempPaths) {
        try {
          final tempDir = Directory(tempPath);
          if (!await tempDir.exists()) continue;
          
          debugPrint('🎤 Searching temp directory: $tempPath');
          
          await for (final entity in tempDir.list()) {
            if (entity is File) {
              final path = entity.path.toLowerCase();
              if (path.contains('recording') && (path.endsWith('.wav') || path.endsWith('.m4a') || path.endsWith('.aac') || path.endsWith('.caf'))) {
                final stats = entity.statSync();
                final age = DateTime.now().difference(stats.modified);
                
                // Only consider very recent files (last 30 seconds)
                if (age.inSeconds < 30) {
                  final size = await entity.length();
                  if (size > 0) {
                    debugPrint('🎤 Found recent temp recording: ${entity.path} (${size} bytes)');
                    return entity.path;
                  }
                }
              }
            }
          }
        } catch (e) {
          // Silently continue if we can't access a directory
          debugPrint('🎤 Cannot access temp directory $tempPath: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('🎤 Error searching system temp directories: $e');
    }
    
    return null;
  }

  /// Handle timeout recovery
  Future<String?> _handleTimeoutRecovery() async {
    debugPrint('🎤 Handling timeout recovery');
    await _updateStateAfterStop();
    
    // Try to salvage any existing recording
    return await _tryReturnStoredRecording();
  }

  /// Handle stop recording errors
  Future<String?> _handleStopRecordingError() async {
    debugPrint('🎤 Handling stop recording error');
    await _updateStateAfterStop();
    
    // Try to salvage any existing recording
    return await _tryReturnStoredRecording();
  }

  /// Alternative file search method for when normal path checking fails
  Future<String?> _findRecordingFileAlternative() async {
    try {
      // Search in Documents directory for recent .m4a files
      final documentsDir = await getApplicationDocumentsDirectory();
      
      debugPrint('🎤 Searching for recent recordings in: ${documentsDir.path}');
      
      final directory = Directory(documentsDir.path);
      if (!await directory.exists()) {
        debugPrint('🎤 Documents directory does not exist');
        return null;
      }

      // Get all files in the directory
      final entities = await directory.list().toList();
      final recentFiles = <File>[];
      final cutoffTime = DateTime.now().subtract(const Duration(minutes: 5));

      for (final entity in entities) {
        if (entity is File) {
          final fileName = entity.path.toLowerCase();
          
          // Look for .m4a files
          if (fileName.endsWith('.m4a')) {
            try {
              final stat = await entity.stat();
              // Check if file was modified recently
              if (stat.modified.isAfter(cutoffTime)) {
                final size = await entity.length();
                if (size > 0) {
                  recentFiles.add(entity);
                  debugPrint('🎤 Found recent recording candidate: ${entity.path} (${size} bytes)');
                }
              }
            } catch (e) {
              debugPrint('🎤 Error checking file ${entity.path}: $e');
            }
          }
        }
      }

      if (recentFiles.isNotEmpty) {
        // Sort by modification time, newest first
        recentFiles.sort((a, b) {
          try {
            final statA = a.statSync();
            final statB = b.statSync();
            return statB.modified.compareTo(statA.modified);
          } catch (e) {
            debugPrint('🎤 Error sorting files: $e');
            return 0;
          }
        });
        
        final mostRecent = recentFiles.first;
        final size = await mostRecent.length();
        debugPrint('🎤 Selected most recent recording: ${mostRecent.path} (${size} bytes)');
        return mostRecent.path;
      }

      debugPrint('🎤 No recent recording files found in Documents directory');
      return null;
    } catch (e) {
      debugPrint('🎤 Error in alternative file search: $e');
      return null;
    }
  }

  /// Quick file search for when the expected path doesn't work (legacy method)
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
            final uuidPattern = RegExp(r'^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}');
            if (fileName.endsWith('.m4a') || fileName.endsWith('.aac') ||
                fileName.endsWith('.wav') || fileName.endsWith('.caf') ||
                fileName.contains('recording') || fileName.contains('audio') ||
                fileName.contains('temp') || uuidPattern.hasMatch(fileName)) {
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
            final allFiles = await dir
                .list()
                .where((entity) => entity is File)
                .cast<File>()
                .toList();

            final recentFiles = <File>[];
            for (final file in allFiles) {
              try {
                final stat = await file.stat();
                if (stat.modified.isAfter(cutoffTime) && await file.length() > 1024) {
                  recentFiles.add(file);
                }
              } catch (e) {
                // File might be deleted or inaccessible, continue
              }
            }

            if (recentFiles.isNotEmpty) {
              debugPrint('🎤 Found ${recentFiles.length} recent files in ${dir.path}');
              // Return the most recently modified file as a fallback
              File? fallbackFile;
              DateTime? mostRecentTime;
              
              for (final file in recentFiles) {
                try {
                  final stat = await file.stat();
                  if (mostRecentTime == null || stat.modified.isAfter(mostRecentTime)) {
                    mostRecentTime = stat.modified;
                    fallbackFile = file;
                  }
                } catch (e) {
                  // Continue with other files
                }
              }

              if (fallbackFile != null) {
                debugPrint('🎤 Using fallback file: ${fallbackFile.path}');
                _currentRecordingPath = fallbackFile.path;
                return fallbackFile.path;
              }
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

  /// Quick validation of a recording file
  Future<bool> validateRecording(String? filePath) async {
    if (filePath == null || filePath.isEmpty) {
      debugPrint('🎤 Validation failed: No file path provided');
      return false;
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('🎤 Validation failed: File does not exist at $filePath');
        return false;
      }

      final fileSize = await file.length();
      if (fileSize < 1024) { // Less than 1KB is probably not a valid recording
        debugPrint('🎤 Validation failed: File too small ($fileSize bytes)');
        return false;
      }

      debugPrint('🎤 Recording validation passed: ${fileSize ~/ 1024}KB');
      return true;
    } catch (e) {
      debugPrint('🎤 Validation error: $e');
      return false;
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
