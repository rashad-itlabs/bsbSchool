import '../../domain/entities/homework_content.dart';
import '../../domain/entities/homework_status_info.dart';
import 'homework_model.dart';

class HomeworkContentModel extends HomeworkContent {
  const HomeworkContentModel({
    super.classId,
    super.className,
    super.homeworks,
    super.statuses,
  });

  /// Matches the whole `GET /homework` body:
  /// `{ "class_id": 94, "class_name": "Class Group 7", "data": [ ... ],
  ///    "statuses": [ ... ] }` — `statuses` since 16.10.2026; each homework
  /// gets its status's entry attached (`Homework.statusInfo`).
  factory HomeworkContentModel.fromJson(Map<String, dynamic> json) {
    final dictionary = json['statuses'];
    // In the server's order: the filter sheet lists them that way.
    final ordered = (dictionary is List ? dictionary : const [])
        .map(HomeworkModel.statusInfoFromJson)
        .whereType<HomeworkStatusInfo>()
        .toList();
    final statuses = {for (final info in ordered) info.code: info};

    final raw = json['data'];
    final homeworks = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => HomeworkModel.fromJson(Map<String, dynamic>.from(e),
                statuses: statuses))
            .toList()
        : <HomeworkModel>[];

    final classId = json['class_id'];

    return HomeworkContentModel(
      classId: classId is int
          ? classId
          : int.tryParse(classId?.toString() ?? ''),
      className: json['class_name']?.toString(),
      homeworks: homeworks,
      statuses: ordered,
    );
  }
}
