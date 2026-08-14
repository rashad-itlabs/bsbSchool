import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/tuition_content.dart';

abstract class TuitionRepository {
  /// `GET /tuition` — the active student's schedule, ledger and totals.
  Future<Either<Failure, TuitionContent>> getTuition();
}
