import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _secureStorage = FlutterSecureStorage();
  
  static Future<void> write(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      // Fallback to SharedPreferences if secure storage fails
      print('Secure storage failed, using SharedPreferences: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }
  
  static Future<String?> read(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      // Fallback to SharedPreferences if secure storage fails
      print('Secure storage failed, using SharedPreferences: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }
  
  static Future<void> delete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      // Fallback to SharedPreferences if secure storage fails
      print('Secure storage failed, using SharedPreferences: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }
  
  static Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      // Fallback to SharedPreferences if secure storage fails
      print('Secure storage failed, using SharedPreferences: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }
}
