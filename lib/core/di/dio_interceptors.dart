import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'injection_container.dart';

class AuthInterceptor extends Interceptor {
  final _secureStorage = ServiceLocator.instance.secureStorage;
  bool _isRefreshing = false;
  int _refreshAttempts = 0;
  final int _maxRefreshAttempts = 3;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    print('🔐 AuthInterceptor: ${options.method} ${options.path}');
    
    // Skip auth for login/register endpoints
    if (options.path.contains('/auth/login/') || 
        options.path.contains('/auth/register/') ||
        options.path.contains('/auth/token/refresh/')) {
      print('🔐 Skipping auth for: ${options.path}');
      return handler.next(options);
    }

    // Add auth token to other requests
    final token = await _secureStorage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      print('🔐 Added Bearer token: ${token.substring(0, 20)}...');
    } else {
      print('🔐 No access token found!');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    print('🔐 AuthInterceptor onError: ${err.response?.statusCode} - ${err.requestOptions.path}');
    
    // Only handle 401 errors and prevent refresh loops
    if (err.response?.statusCode == 401 && !_isRefreshing && _refreshAttempts < _maxRefreshAttempts) {
      print('🔐 Token expired, attempting refresh (attempt ${_refreshAttempts + 1}/$_maxRefreshAttempts)...');
      _isRefreshing = true;
      _refreshAttempts++;
      
      try {
        final refreshToken = await _secureStorage.read(key: 'refresh_token');
        if (refreshToken != null) {
          print('🔐 Found refresh token, making refresh request...');
          final dio = ServiceLocator.instance.dio;
          
          // Create a new dio instance without interceptors for refresh to prevent loops
          final refreshDio = Dio();
          refreshDio.options.baseUrl = dio.options.baseUrl;
          
          final response = await refreshDio.post(
            '/auth/token/refresh/',
            data: {'refresh': refreshToken},
          );

          final newToken = response.data['access'];
          await _secureStorage.write(key: 'access_token', value: newToken);
          print('🔐 Token refreshed successfully');
          
          // Reset refresh attempts on success
          _refreshAttempts = 0;

          // Retry original request with new token
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          
          final cloneReq = await dio.request(
            opts.path,
            options: Options(
              method: opts.method,
              headers: opts.headers,
              extra: opts.extra,
              responseType: opts.responseType,
            ),
            data: opts.data,
            queryParameters: opts.queryParameters,
          );
          
          _isRefreshing = false;
          return handler.resolve(cloneReq);
        } else {
          print('🔐 No refresh token found');
        }
      } catch (e) {
        print('🔐 Refresh token failed: $e');
        // Refresh failed, clear all tokens and let the app handle login
        await _secureStorage.deleteAll();
        _refreshAttempts = 0;
      } finally {
        _isRefreshing = false;
      }
    } else if (_refreshAttempts >= _maxRefreshAttempts) {
      print('🔐 Max refresh attempts reached, clearing auth state');
      await _secureStorage.deleteAll();
      _refreshAttempts = 0;
      _isRefreshing = false;
    }
    
    handler.next(err);
  }
}
