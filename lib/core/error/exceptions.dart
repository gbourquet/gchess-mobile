class ServerException implements Exception {
  final String message;

  ServerException([this.message = 'Server error occurred']);

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  final String message;

  NetworkException([this.message = 'Network connection failed']);

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;

  CacheException([this.message = 'Cache error occurred']);

  @override
  String toString() => 'CacheException: $message';
}

class AuthenticationException implements Exception {
  final String message;

  AuthenticationException([this.message = 'Authentication failed']);

  @override
  String toString() => 'AuthenticationException: $message';
}

class ValidationException implements Exception {
  final String message;

  ValidationException([this.message = 'Validation error']);

  @override
  String toString() => 'ValidationException: $message';
}

class WebSocketException implements Exception {
  final String message;

  WebSocketException([this.message = 'WebSocket connection failed']);

  @override
  String toString() => 'WebSocketException: $message';
}

class ConflictException implements Exception {
  final String message;

  ConflictException([this.message = 'Resource already exists']);

  @override
  String toString() => 'ConflictException: $message';
}
