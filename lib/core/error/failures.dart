import 'package:equatable/equatable.dart';

import '../l10n/l10n.dart';

/// Base type for every error surfaced to the domain & presentation layers.
///
/// The message is stored nullable and resolved on read: a failure raised
/// without one falls back to a translated default, so the wording follows the
/// language the parent picked rather than whichever was loaded when the
/// constant was created.
abstract class Failure extends Equatable {
  final String? _message;

  const Failure([this._message]);

  String get message => _message ?? defaultMessage;

  /// Wording used when the layer that raised this had nothing specific to say.
  String get defaultMessage;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message]);

  @override
  String get defaultMessage => L.s.errServer;
}

class CacheFailure extends Failure {
  const CacheFailure([super.message]);

  @override
  String get defaultMessage => L.s.errCache;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);

  @override
  String get defaultMessage => L.s.errNoInternet;
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message]);

  @override
  String get defaultMessage => L.s.errInvalid;
}
