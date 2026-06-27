// Internal exceptions caught at the data layer boundary and converted to Failures.
// These must never escape to the domain or presentation layers.

class ServerException implements Exception {
  const ServerException({required this.message, this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class AuthException implements Exception {
  const AuthException({required this.message, this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'AuthException($code): $message';
}

class CacheException implements Exception {
  const CacheException({required this.message});
  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class EncryptionException implements Exception {
  const EncryptionException({required this.message});
  final String message;

  @override
  String toString() => 'EncryptionException: $message';
}

class NetworkException implements Exception {
  const NetworkException({required this.message});
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class PermissionException implements Exception {
  const PermissionException({required this.permission});
  final String permission;

  @override
  String toString() => 'PermissionException: $permission denied';
}

class StorageException implements Exception {
  const StorageException({required this.message});
  final String message;

  @override
  String toString() => 'StorageException: $message';
}
