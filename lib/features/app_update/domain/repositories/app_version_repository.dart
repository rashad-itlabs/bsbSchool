import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_version.dart';

abstract class AppVersionRepository {
  /// What the backend publishes for [platform] (`ios` / `android`).
  ///
  /// Every caller treats a [Failure] as "carry on": a version check that
  /// cannot be made is never a reason to keep a parent out of the app.
  Future<Either<Failure, AppVersion>> fetch({required String platform});
}
