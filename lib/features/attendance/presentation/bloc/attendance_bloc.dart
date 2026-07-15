import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_summary.dart';
import '../../domain/usecases/get_attendance.dart';

part 'attendance_event.dart';
part 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final GetAttendance getAttendance;

  AttendanceBloc({required this.getAttendance})
      : super(const AttendanceState()) {
    on<AttendanceFetched>(_onFetched);
    on<AttendanceRefreshed>(_onFetched);
  }

  Future<void> _onFetched(
    AttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    // A pull-to-refresh keeps the current list on screen; the first load has
    // nothing to keep, so both paths just flip the status.
    emit(state.copyWith(status: AttendanceStatus.loading));

    final result = await getAttendance(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: AttendanceStatus.error,
        errorMessage: failure.message,
      )),
      // Built fresh rather than via copyWith so a null student id actually
      // clears the previous one.
      (content) => emit(AttendanceState(
        status: AttendanceStatus.loaded,
        studentId: content.studentId,
        summary: content.summary,
        records: content.records,
      )),
    );
  }
}
