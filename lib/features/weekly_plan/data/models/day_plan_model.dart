import '../../domain/entities/day_plan.dart';

class LessonModel extends Lesson {
  const LessonModel({
    required super.order,
    required super.time,
    required super.subject,
    required super.teacher,
    required super.room,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) => LessonModel(
        order: json['order'] as int,
        time: json['time'] as String,
        subject: json['subject'] as String,
        teacher: json['teacher'] as String,
        room: json['room'] as String,
      );

  Map<String, dynamic> toJson() => {
        'order': order,
        'time': time,
        'subject': subject,
        'teacher': teacher,
        'room': room,
      };
}

class DayPlanModel extends DayPlan {
  const DayPlanModel({required super.day, required super.lessons});

  factory DayPlanModel.fromJson(Map<String, dynamic> json) => DayPlanModel(
        day: json['day'] as String,
        lessons: (json['lessons'] as List<dynamic>)
            .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'day': day,
        'lessons': lessons
            .map((l) => (l as LessonModel).toJson())
            .toList(),
      };
}
