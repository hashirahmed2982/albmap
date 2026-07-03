/// Exceptions thrown at the data-source level (remote/local).
/// Repositories catch these and convert them into [Failure]s so
/// the domain layer never sees implementation-specific errors.
class ServerException implements Exception {
  ServerException([this.message = 'Server error', this.statusCode]);
  final String message;
  final int? statusCode;
}

class CacheException implements Exception {
  CacheException([this.message = 'Cache error']);
  final String message;
}

class NetworkException implements Exception {
  NetworkException([this.message = 'No internet connection']);
  final String message;
}

class AuthException implements Exception {
  AuthException([this.message = 'Authentication error']);
  final String message;
}

class ValidationException implements Exception {
  ValidationException([this.message = 'Validation error']);
  final String message;
}
