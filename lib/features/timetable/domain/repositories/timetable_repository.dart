import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/timetable_content.dart';

abstract class TimetableRepository {
  /// Weekly class timetable for the logged-in student's class.
  Future<Either<Failure, TimetableContent>> getTimetable();
}
