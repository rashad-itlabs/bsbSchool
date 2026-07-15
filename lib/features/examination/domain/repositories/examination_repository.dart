import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/examination_content.dart';

abstract class ExaminationRepository {
  /// Exam results for the logged-in student, grouped by exam group.
  Future<Either<Failure, ExaminationContent>> getExaminations();
}
