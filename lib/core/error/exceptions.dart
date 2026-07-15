/// Thrown when a remote data source (API) returns an error.
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server xətası baş verdi']);
}

/// Thrown when a local data source (cache) fails.
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Keş xətası baş verdi']);
}

/// Thrown when there is no internet connection.
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'İnternet bağlantısı yoxdur']);
}

/// Thrown for invalid business operations (e.g. insufficient balance).
class ValidationException implements Exception {
  final String message;
  const ValidationException([this.message = 'Yanlış əməliyyat']);
}
