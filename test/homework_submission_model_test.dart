import 'package:bsbschool/features/homework/data/models/homework_content_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a homework with a submission object is parsed as submitted', () {
    final content = HomeworkContentModel.fromJson({
      'class_id': 157,
      'data': [
        {
          'id': 17,
          'homework_name': 'Introduction',
          'submit_date': '2026-09-15',
          'status': 'submitted',
          'submission': {
            'marked_at': '2026-09-23 15:59:47',
            'notes': 'Test Elvin aliyev',
            'document': null,
            'original_name': null,
            'grade': null,
            'teacher_comment': null,
          },
        },
        {
          'id': 301,
          'homework_name': 'Həqiqi və məcazi məna',
          'submit_date': '2026-09-24',
          'status': 'not_marked',
          'submission': null,
        },
      ],
    });

    final submitted = content.homeworks[0];
    expect(submitted.isSubmitted, isTrue);
    expect(submitted.submission!.markedAt, DateTime(2026, 9, 23, 15, 59, 47));
    expect(submitted.submission!.notes, 'Test Elvin aliyev');
    expect(submitted.submission!.grade, isNull);
    expect(submitted.submission!.documentUrl, isNull);

    expect(content.homeworks[1].isSubmitted, isFalse);
    expect(content.homeworks[1].submission, isNull);
  });
}
