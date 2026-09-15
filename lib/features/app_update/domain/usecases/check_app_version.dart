import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_version.dart';
import '../repositories/app_version_repository.dart';

/// Asks the backend which builds it still supports.
class CheckAppVersion implements UseCase<AppVersion, CheckAppVersionParams> {
  final AppVersionRepository repository;
  const CheckAppVersion(this.repository);

  @override
  Future<Either<Failure, AppVersion>> call(CheckAppVersionParams params) {
    return repository.fetch(platform: params.platform);
  }
}

class CheckAppVersionParams extends Equatable {
  final String platform;

  const CheckAppVersionParams({required this.platform});

  @override
  List<Object?> get props => [platform];
}
