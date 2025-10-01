/// API Configuration
/// 
/// Centralized configuration for all API endpoints.
/// Change the base URL here to switch between environments.
class ApiConfig {
  // 🔧 CHANGE THIS URL TO SWITCH ENVIRONMENTS
  static const String baseUrl = 'http://172.20.10.13:8000/api/';
  
  // Alternative URLs for easy switching:
  // static const String baseUrl = 'https://iloqi-production.up.railway.app/api/'; // Production
  // static const String baseUrl = 'http://localhost:8000/api/'; // Local localhost
  // static const String baseUrl = 'http://172.20.10.13:8000/api/'; // Local network IP
  
  /// Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  /// Default headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  /// Get full URL for a specific endpoint
  static String getUrl(String endpoint) {
    return baseUrl + endpoint.replaceFirst(RegExp(r'^/'), '');
  }
  
  /// Environment info
  static bool get isProduction => baseUrl.contains('railway.app');
  static bool get isLocal => baseUrl.contains('localhost') || baseUrl.contains('172.20.10.13');
  
  /// Debug info
  static String get environmentName {
    if (isProduction) return 'Production (Railway)';
    if (isLocal) return 'Local Development';
    return 'Unknown';
  }
}
