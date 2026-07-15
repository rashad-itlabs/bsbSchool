import '../../domain/entities/homework_content.dart';
import 'homework_model.dart';

class HomeworkContentModel extends HomeworkContent {
  const HomeworkContentModel({
    super.classId,
    super.className,
    super.homeworks,
  });

  /// Matches the whole `GET /homework` body:
  /// `{ "class_id": 94, "class_name": "Class Group 7", "data": [ ... ] }`
  factory HomeworkContentModel.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final homeworks = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => HomeworkModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <HomeworkModel>[];

    final classId = json['class_id'];

    return HomeworkContentModel(
      classId: classId is int
          ? classId
          : int.tryParse(classId?.toString() ?? ''),
      className: json['class_name']?.toString(),
      homeworks: homeworks,
    );
  }
}
