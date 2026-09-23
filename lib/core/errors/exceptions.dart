class ServerException implements Exception {
  final String message;
  final String? code;
  const ServerException(this.message, [this.code]);

  @override
  String toString() => 'ServerException: $message ($code)';
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException(this.message, [this.code]);

  @override
  String toString() => 'AuthException: $message ($code)';
}

class PermissionException implements Exception {
  final String message;
  const PermissionException(this.message);

  @override
  String toString() => 'PermissionException: $message';
}
