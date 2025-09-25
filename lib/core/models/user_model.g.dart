// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      email: json['email'] as String,
      l1Language: json['l1_language'] as String?,
      targetAccent: json['target_accent'] as String?,
      preferredSessionDuration:
          (json['preferred_session_duration'] as num?)?.toInt(),
      difficultyLevel: (json['difficulty_level'] as num?)?.toInt(),
      totalPracticeTime: (json['total_practice_time'] as num?)?.toInt(),
      streakDays: (json['streak_days'] as num?)?.toInt(),
      lastPracticeDate: json['last_practice_date'] as String?,
      emailNotifications: json['email_notifications'] as bool?,
      pushNotifications: json['push_notifications'] as bool?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'email': instance.email,
      'l1_language': instance.l1Language,
      'target_accent': instance.targetAccent,
      'preferred_session_duration': instance.preferredSessionDuration,
      'difficulty_level': instance.difficultyLevel,
      'total_practice_time': instance.totalPracticeTime,
      'streak_days': instance.streakDays,
      'last_practice_date': instance.lastPracticeDate,
      'email_notifications': instance.emailNotifications,
      'push_notifications': instance.pushNotifications,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) => AuthTokens(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
    );

Map<String, dynamic> _$AuthTokensToJson(AuthTokens instance) =>
    <String, dynamic>{
      'access': instance.access,
      'refresh': instance.refresh,
    };

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
    };

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      passwordConfirm: json['password_confirm'] as String,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'password_confirm': instance.passwordConfirm,
    };

JWTResponse _$JWTResponseFromJson(Map<String, dynamic> json) => JWTResponse(
      message: json['message'] as String,
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JWTResponseToJson(JWTResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'access': instance.access,
      'refresh': instance.refresh,
      'user': instance.user,
    };
