part of 'attendance_bloc.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

/// First load of the screen.
class AttendanceFetched extends AttendanceEvent {
  const AttendanceFetched();
}

/// Pull-to-refresh / retry after an error.
class AttendanceRefreshed extends AttendanceEvent {
  const AttendanceRefreshed();
}
