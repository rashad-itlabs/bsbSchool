import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/extra_fees_content.dart';

abstract class ExtraFeesRepository {
  /// `GET /extra_fees` — the active student's extra fees and their totals.
  Future<Either<Failure, ExtraFeesContent>> getExtraFees();
}
