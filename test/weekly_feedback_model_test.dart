import 'package:bsbschool/features/weekly_feedback/data/models/weekly_feedback_content_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the weekly feedback response is parsed', () {
    // The real response, with the weeks array cut down to its first three.
    final content = WeeklyFeedbackContentModel.fromJson({
      'success': true,
      'ready': true,
      'student_id': 3789,
      'student_name': 'Said Aliyev',
      'class_id': 157,
      'class_name': 'Year 6',
      'total_weeks': 40,
      'current_week': 2,
      'selected_week': 2,
      'weeks': [
        {'week': 1, 'count': 0, 'has_feedback': false, 'is_current': false, 'is_future': false},
        {'week': 2, 'count': 1, 'has_feedback': true, 'is_current': true, 'is_future': false},
        {'week': 3, 'count': 0, 'has_feedback': false, 'is_current': false, 'is_future': true},
      ],
      'data': [
        {
          'kind': 'student',
          'kind_label': 'About your child',
          'teacher': 'Felipe Caceres',
          'subjects': 'Mindfulness, Literacy, Numeracy, Science',
          'text': 'Said has a satisfactory behavior in class.',
          'files': [],
          'date': '2026-09-24',
        },
      ],
    });

    expect(content.ready, isTrue);
    expect(content.studentId, 3789);
    expect(content.totalWeeks, 40);
    expect(content.currentWeek, 2);
    expect(content.selectedWeek, 2);

    expect(content.weeks, hasLength(3));
    expect(content.weeks[1].hasFeedback, isTrue);
    expect(content.weeks[1].isCurrent, isTrue);
    expect(content.weeks[1].count, 1);
    expect(content.weeks[2].isFuture, isTrue);

    final feedback = content.feedback.single;
    expect(feedback.kind, 'student');
    expect(feedback.kindLabel, 'About your child');
    expect(feedback.teacher, 'Felipe Caceres');
    expect(feedback.subjects, 'Mindfulness, Literacy, Numeracy, Science');
    expect(feedback.date, DateTime(2026, 9, 24));
    expect(feedback.files, isEmpty);
  });

  test('files are read whether the server sends URLs or objects', () {
    final content = WeeklyFeedbackContentModel.fromJson({
      'data': [
        {
          'text': 'x',
          'files': [
            'https://online.bsb.edu.az/storage/Unit%201%20Slides.pdf',
            {'path': 'storage/feedback/lab.jpg', 'original_name': 'Lab sheet.jpg'},
            {'nothing': 'useful'},
          ],
        },
      ],
    });

    final files = content.feedback.single.files;
    expect(files, hasLength(2));
    expect(files[0].name, 'Unit 1 Slides.pdf');
    expect(files[0].extension, 'pdf');
    // A bare storage path lands on the API's host.
    expect(files[1].url, 'https://online.bsb.edu.az/storage/feedback/lab.jpg');
    expect(files[1].name, 'Lab sheet.jpg');
  });
}
