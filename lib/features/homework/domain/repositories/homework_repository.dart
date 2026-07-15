import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/homework_content.dart';

abstract class HomeworkRepository {
  /// Homework available to the logged-in student's class.
  Future<Either<Failure, HomeworkContent>> getHomeworks();
}
