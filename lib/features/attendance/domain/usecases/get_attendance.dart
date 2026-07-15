import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/attendance_content.dart';
import '../repositories/attendance_repository.dart';

class GetAttendance implements UseCase<AttendanceContent, NoParams> {
  final AttendanceRepository repository;
  const GetAttendance(this.repository);

  @override
  Future<Either<Failure, AttendanceContent>> call(NoParams params) {
    return repository.getAttendance();
  }
}
