import '../../domain/entities/timetable_content.dart';
import 'timetable_day_model.dart';

class TimetableContentModel extends TimetableContent {
  const TimetableContentModel({
    super.classId,
    super.className,
    super.days,
  });

  /// Matches the whole `GET /class-timetable` body:
  /// `{ "class_id": 94, "class_name": "Class Group 7", "data": [ ... ] }`
  factory TimetableContentModel.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final days = raw is List
        ? raw
            .whereType<Map>()
            .map((e) =>
                TimetableDayModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <TimetableDayModel>[];

    final classId = json['class_id'];

    return TimetableContentModel(
      classId:
          classId is int ? classId : int.tryParse(classId?.toString() ?? ''),
      className: json['class_name']?.toString(),
      days: days,
    );
  }
}
