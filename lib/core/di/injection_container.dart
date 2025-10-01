import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/auth_api_service.dart';
import '../services/voice_api_service.dart';
import 'dio_interceptors.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  static ServiceLocator get instance => _instance;

  late final Dio _dio;
  late final SharedPreferences _prefs;
  late final FlutterSecureStorage _secureStorage;
  late final AuthApiService _authApiService;
  late final VoiceApiService _voiceApiService;

  Dio get dio => _dio;
  SharedPreferences get prefs => _prefs;
  FlutterSecureStorage get secureStorage => _secureStorage;
  AuthApiService get authApi => _authApiService;
  VoiceApiService get voiceApi => _voiceApiService;
}

Future<void> init() async {
  final sl = ServiceLocator.instance;

  // External dependencies
  sl._prefs = await SharedPreferences.getInstance();
  sl._secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Dio setup with production Railway URL
  sl._dio = Dio(BaseOptions(
    baseUrl: 'https://iloqi-production.up.railway.app/api/',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Add interceptors
  sl._dio.interceptors.add(AuthInterceptor());
  sl._dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) => print(obj.toString()),
  ));

  // API services
  sl._authApiService = AuthApiService(sl._dio);
  sl._voiceApiService = VoiceApiService(sl._dio);
}
