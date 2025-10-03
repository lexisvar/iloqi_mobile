import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Cross-platform permission helper
/// Handles platform-specific permission requests and checks
class PermissionHelper {
  
  /// Check microphone permission status in a cross-platform way
  static Future<PermissionStatus> checkMicrophonePermission() async {
    try {
      // On macOS, permission_handler may not be available
      if (Platform.isMacOS) {
        // For macOS, we'll assume permission is granted since it's handled by the system
        // The system will show its own permission dialog when needed
        return PermissionStatus.granted;
      }
      
      // For iOS and Android, use permission_handler
      return await Permission.microphone.status;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Permission check error (might be expected on some platforms): $e');
      }
      // If permission_handler fails, assume granted and let the system handle it
      return PermissionStatus.granted;
    }
  }
  
  /// Request microphone permission in a cross-platform way
  static Future<PermissionStatus> requestMicrophonePermission() async {
    try {
      // On macOS, permission_handler may not be available
      if (Platform.isMacOS) {
        // For macOS, we'll assume permission is granted since it's handled by the system
        // The actual permission will be requested when recording starts
        return PermissionStatus.granted;
      }
      
      // For iOS and Android, use permission_handler
      return await Permission.microphone.request();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Permission request error (might be expected on some platforms): $e');
      }
      // If permission_handler fails, assume granted and let the system handle it
      return PermissionStatus.granted;
    }
  }
  
  /// Check if microphone permission is granted
  static Future<bool> isMicrophonePermissionGranted() async {
    final status = await checkMicrophonePermission();
    return status == PermissionStatus.granted;
  }
  
  /// Get platform-specific permission status display text
  static String getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Permission granted';
      case PermissionStatus.denied:
        return 'Permission denied';
      case PermissionStatus.restricted:
        return 'Permission restricted';
      case PermissionStatus.limited:
        return 'Permission limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permission permanently denied';
      default:
        return 'Permission status unknown';
    }
  }
  
  /// Check if we should show permission rationale (iOS/Android specific)
  static Future<bool> shouldShowRequestPermissionRationale() async {
    try {
      if (Platform.isMacOS) {
        return false; // macOS handles this differently
      }
      
      if (Platform.isAndroid) {
        // On Android, check if we should show rationale
        final status = await Permission.microphone.status;
        return status == PermissionStatus.denied;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Open app settings for permission management
  static Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not open app settings: $e');
      }
      return false;
    }
  }
}
