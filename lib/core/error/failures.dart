import 'package:equatable/equatable.dart';

/// Base type for every error surfaced to the domain & presentation layers.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server xətası baş verdi']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Keş xətası baş verdi']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'İnternet bağlantısı yoxdur']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Yanlış əməliyyat']);
}
