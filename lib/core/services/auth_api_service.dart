import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/user_model.dart';

part 'auth_api_service.g.dart';

@RestApi(baseUrl: 'http://127.0.0.1:8000/api/')
abstract class AuthApiService {
  factory AuthApiService(Dio dio, {String baseUrl}) = _AuthApiService;

  @POST('auth/login/')
  Future<JWTResponse> login(@Body() LoginRequest request);

  @POST('auth/register/')
  Future<JWTResponse> register(@Body() RegisterRequest request);

  @POST('auth/token/refresh/')
  Future<AuthTokens> refreshToken(@Body() Map<String, String> refreshToken);

  @POST('auth/token/verify/')
  Future<void> verifyToken(@Body() Map<String, String> token);

  @GET('auth/profile/')
  Future<User> getCurrentUser();

  @PUT('auth/profile/update/')
  Future<User> updateUser(@Body() Map<String, dynamic> userData);

  @DELETE('auth/user/')
  Future<void> deleteUser();

  @POST('auth/logout/')
  Future<void> logout();
}
