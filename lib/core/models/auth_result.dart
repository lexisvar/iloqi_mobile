class AuthResult {
  final bool success;
  final String? message;
  final AuthErrorType? errorType;

  const AuthResult({
    required this.success,
    this.message,
    this.errorType,
  });

  factory AuthResult.success([String? message]) {
    return AuthResult(
      success: true,
      message: message ?? 'Operation completed successfully',
    );
  }

  factory AuthResult.failure(String message, [AuthErrorType? errorType]) {
    return AuthResult(
      success: false,
      message: message,
      errorType: errorType,
    );
  }
}

enum AuthErrorType {
  invalidCredentials,
  emailAlreadyExists,
  weakPassword,
  invalidEmail,
  networkError,
  serverError,
  validationError,
  unknown,
}
