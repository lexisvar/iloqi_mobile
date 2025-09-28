import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../models/user_model.dart';
import '../models/auth_result.dart';
import '../services/auth_api_service.dart';
import '../services/storage_service.dart';
import '../di/injection_container.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthApiService _authApi;

  AuthNotifier(this._authApi) : super(const AsyncValue.loading()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await StorageService.read('access_token');
      final refreshToken = await StorageService.read('refresh_token');
      
      if (token != null && refreshToken != null) {
        print('🔐 Found tokens, verifying...');
        // Try to verify token first
        try {
          await _authApi.verifyToken({'token': token});
          print('🔐 Token is valid, getting user profile...');
          
          final user = await _authApi.getCurrentUser();
          state = AsyncValue.data(user);
          print('🔐 Auth state initialized with user: ${user.email}');
        } catch (e) {
          print('🔐 Token verification failed, clearing auth state: $e');
          await StorageService.delete('access_token');
          await StorageService.delete('refresh_token');
          state = const AsyncValue.data(null);
        }
      } else {
        print('🔐 No tokens found, user not authenticated');
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      print('🔐 Error in _checkAuthStatus: $e');
      state = const AsyncValue.data(null);
    }
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final response = await _authApi.login(LoginRequest(email: email, password: password));
      
      await StorageService.write('access_token', response.access);
      await StorageService.write('refresh_token', response.refresh);
      
      state = AsyncValue.data(response.user);
      return AuthResult.success('Welcome! You have successfully logged in.');
    } on DioException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return _handleDioError(e, isLogin: true);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
        AuthErrorType.unknown,
      );
    }
  }

  Future<AuthResult> register(RegisterRequest request) async {
    try {
      state = const AsyncValue.loading();
      final response = await _authApi.register(request);
      
      await StorageService.write('access_token', response.access);
      await StorageService.write('refresh_token', response.refresh);
      
      state = AsyncValue.data(response.user);
      return AuthResult.success('Account created successfully! Welcome to Eloqi.');
    } on DioException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return _handleDioError(e, isLogin: false);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return AuthResult.failure(
        'An unexpected error occurred during registration. Please try again.',
        AuthErrorType.unknown,
      );
    }
  }

  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (e) {
      // Ignore logout errors
    } finally {
      await StorageService.deleteAll();
      state = const AsyncValue.data(null);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    try {
      final updatedUser = await _authApi.updateUser(userData);
      state = AsyncValue.data(updatedUser);
      return true;
    } catch (e) {
      return false;
    }
  }

  AuthResult _handleDioError(DioException error, {required bool isLogin}) {
    if (error.type == DioExceptionType.connectionError) {
      return AuthResult.failure(
        'Unable to connect to the server. Please check your internet connection and try again.',
        AuthErrorType.networkError,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout || 
        error.type == DioExceptionType.receiveTimeout) {
      return AuthResult.failure(
        'Connection timed out. Please check your internet connection and try again.',
        AuthErrorType.networkError,
      );
    }

    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    switch (statusCode) {
      case 400:
        // Bad request - usually validation errors
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('email')) {
            final emailErrors = responseData['email'];
            if (emailErrors is List && emailErrors.isNotEmpty) {
              return AuthResult.failure(
                'Email error: ${emailErrors.first}',
                AuthErrorType.invalidEmail,
              );
            }
          }
          if (responseData.containsKey('password')) {
            final passwordErrors = responseData['password'];
            if (passwordErrors is List && passwordErrors.isNotEmpty) {
              return AuthResult.failure(
                'Password error: ${passwordErrors.first}',
                AuthErrorType.weakPassword,
              );
            }
          }
          if (responseData.containsKey('password_confirm')) {
            final confirmErrors = responseData['password_confirm'];
            if (confirmErrors is List && confirmErrors.isNotEmpty) {
              return AuthResult.failure(
                'Password confirmation error: ${confirmErrors.first}',
                AuthErrorType.validationError,
              );
            }
          }
          if (responseData.containsKey('non_field_errors')) {
            final nonFieldErrors = responseData['non_field_errors'];
            if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
              return AuthResult.failure(
                nonFieldErrors.first.toString(),
                AuthErrorType.validationError,
              );
            }
          }
        }
        return AuthResult.failure(
          isLogin ? 'Invalid login credentials.' : 'Registration data is invalid. Please check your input.',
          AuthErrorType.validationError,
        );

      case 401:
        return AuthResult.failure(
          isLogin 
            ? 'Invalid email or password. Please check your credentials and try again.' 
            : 'Authentication failed during registration.',
          AuthErrorType.invalidCredentials,
        );

      case 409:
        return AuthResult.failure(
          'This email address is already registered. Please use a different email or try logging in.',
          AuthErrorType.emailAlreadyExists,
        );

      case 500:
        return AuthResult.failure(
          'Server error occurred. Please try again later.',
          AuthErrorType.serverError,
        );

      default:
        return AuthResult.failure(
          isLogin 
            ? 'Login failed. Please try again.' 
            : 'Registration failed. Please try again.',
          AuthErrorType.unknown,
        );
    }
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authApi = ServiceLocator.instance.authApi;
  return AuthNotifier(authApi);
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});
