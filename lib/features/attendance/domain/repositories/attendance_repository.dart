import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/attendance_content.dart';

abstract class AttendanceRepository {
  /// Attendance history and summary for the logged-in student.
  Future<Either<Failure, AttendanceContent>> getAttendance();
}
