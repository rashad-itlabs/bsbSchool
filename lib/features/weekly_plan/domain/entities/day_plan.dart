import 'package:equatable/equatable.dart';

class Lesson extends Equatable {
  final int order;
  final String time; // "08:30 - 09:15"
  final String subject;
  final String teacher;
  final String room;

  const Lesson({
    required this.order,
    required this.time,
    required this.subject,
    required this.teacher,
    required this.room,
  });

  @override
  List<Object?> get props => [order, time, subject, teacher, room];
}

class DayPlan extends Equatable {
  final String day; // Bazar ertəsi, ...
  final List<Lesson> lessons;

  const DayPlan({required this.day, required this.lessons});

  @override
  List<Object?> get props => [day, lessons];
}
