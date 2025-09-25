import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  final String email;
  @JsonKey(name: 'l1_language')
  final String? l1Language;
  @JsonKey(name: 'target_accent')
  final String? targetAccent;
  @JsonKey(name: 'preferred_session_duration')
  final int? preferredSessionDuration;
  @JsonKey(name: 'difficulty_level')
  final int? difficultyLevel;
  @JsonKey(name: 'total_practice_time')
  final int? totalPracticeTime;
  @JsonKey(name: 'streak_days')
  final int? streakDays;
  @JsonKey(name: 'last_practice_date')
  final String? lastPracticeDate;
  @JsonKey(name: 'email_notifications')
  final bool? emailNotifications;
  @JsonKey(name: 'push_notifications')
  final bool? pushNotifications;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const User({
    required this.email,
    this.l1Language,
    this.targetAccent,
    this.preferredSessionDuration,
    this.difficultyLevel,
    this.totalPracticeTime,
    this.streakDays,
    this.lastPracticeDate,
    this.emailNotifications,
    this.pushNotifications,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get displayName => email.split('@').first;
}

@JsonSerializable()
class AuthTokens {
  final String access;
  final String refresh;

  const AuthTokens({
    required this.access,
    required this.refresh,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => _$AuthTokensFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTokensToJson(this);
}

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String email;
  final String password;
  @JsonKey(name: 'password_confirm')
  final String passwordConfirm;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.passwordConfirm,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class JWTResponse {
  final String message;
  final String access;
  final String refresh;
  final User user;

  const JWTResponse({
    required this.message,
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory JWTResponse.fromJson(Map<String, dynamic> json) => _$JWTResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JWTResponseToJson(this);
}
