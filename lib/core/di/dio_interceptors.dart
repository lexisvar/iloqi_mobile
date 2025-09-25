import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'injection_container.dart';

class AuthInterceptor extends Interceptor {
  final _secureStorage = ServiceLocator.instance.secureStorage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for login/register endpoints
    if (options.path.contains('/auth/login/') || 
        options.path.contains('/auth/register/') ||
        options.path.contains('/auth/token/refresh/')) {
      return handler.next(options);
    }

    // Add auth token to other requests
    final token = await _secureStorage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired, try to refresh
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final dio = ServiceLocator.instance.dio;
          final response = await dio.post(
            '/auth/token/refresh/',
            data: {'refresh': refreshToken},
            options: Options(
              headers: {'Authorization': null}, // Remove old token
            ),
          );

          final newToken = response.data['access'];
          await _secureStorage.write(key: 'access_token', value: newToken);

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
          return handler.resolve(cloneReq);
        } catch (e) {
          // Refresh failed, redirect to login
          await _secureStorage.deleteAll();
          return handler.next(err);
        }
      }
    }
    handler.next(err);
  }
}
