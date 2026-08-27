import '../l10n/l10n.dart';

/// Base for the typed exceptions the data layer throws.
///
/// The message is resolved on read rather than stored at construction, so an
/// exception thrown without one is worded in the language now on screen.
abstract class AppException implements Exception {
  final String? _message;

  const AppException([this._message]);

  String get message => _message ?? defaultMessage;

  /// Wording used when the caller had nothing specific to say.
  String get defaultMessage;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a remote data source (API) returns an error.
class ServerException extends AppException {
  const ServerException([super.message]);

  @override
  String get defaultMessage => L.s.errServer;
}

/// Thrown when a local data source (cache) fails.
class CacheException extends AppException {
  const CacheException([super.message]);

  @override
  String get defaultMessage => L.s.errCache;
}

/// Thrown when there is no internet connection.
class NetworkException extends AppException {
  const NetworkException([super.message]);

  @override
  String get defaultMessage => L.s.errNoInternet;
}

/// Thrown for invalid business operations (e.g. insufficient balance).
class ValidationException extends AppException {
  const ValidationException([super.message]);

  @override
  String get defaultMessage => L.s.errInvalid;
}
