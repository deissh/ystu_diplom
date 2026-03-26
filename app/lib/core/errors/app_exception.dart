sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class ParseException extends AppException {
  const ParseException(super.message);
}

class CacheException extends AppException {
  const CacheException(super.message);
}
