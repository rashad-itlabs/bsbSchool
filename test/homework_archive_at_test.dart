import 'package:bsbschool/features/homework/data/models/homework_model.dart';
import 'package:bsbschool/features/homework/domain/entities/homework.dart';
import 'package:bsbschool/features/homework/presentation/bloc/homework_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _ids(List<Homework> list) => [for (final hw in list) hw.id];

void main() {
  group('archive_at decides the tab', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Both are due today — only the server's moment tells them apart.
    final homeworks = [
      Homework(
        id: 1,
        name: 'Keçib',
        submitDate: today,
        archiveAt: now.subtract(const Duration(minutes: 1)),
      ),
      Homework(
        id: 2,
        name: 'Hələ gəlməyib',
        submitDate: today,
        archiveAt: now.add(const Duration(minutes: 1)),
      ),
    ];

    test('a passed moment is inactive even on the deadline day', () {
      final past = HomeworkState(
        status: HomeworkStatus.loaded,
        homeworks: homeworks,
        tab: HomeworkTab.past,
      );
      expect(_ids(past.tabHomeworks), [1]);
    });

    test('a moment still ahead stays active', () {
      final active = HomeworkState(
        status: HomeworkStatus.loaded,
        homeworks: homeworks,
      );
      expect(_ids(active.tabHomeworks), [2]);
    });

    test('the exact moment already counts as passed', () {
      final at = DateTime(2026, 10, 17, 8);
      final hw = Homework(id: 3, name: 'x', archiveAt: at);
      expect(HomeworkState.isExpired(hw, at), isTrue);
      expect(
        HomeworkState.isExpired(hw, at.subtract(const Duration(seconds: 1))),
        isFalse,
      );
    });

    test('without archive_at the old day rule still applies', () {
      final hw = Homework(id: 4, name: 'x', submitDate: today);
      expect(HomeworkState.isExpired(hw, now), isFalse);
      expect(
        HomeworkState.isExpired(hw, today.add(const Duration(days: 1))),
        isTrue,
      );
    });
  });

  group('HomeworkModel.fromJson', () {
    test('reads created_at as school time and archive_at as an instant', () {
      final hw = HomeworkModel.fromJson({
        'id': 5246,
        'homework_name': 'Test',
        'submit_date': '2026-10-17',
        'created_at': '2026-10-15 22:44:12',
        'archive_at': '2026-10-17T08:00:00+04:00',
      });

      // Shown as written: the school's wall clock, whatever the phone's zone.
      expect(hw.createdAt, DateTime(2026, 10, 15, 22, 44, 12));
      // 08:00 in Baku is 04:00 UTC — compared as a real moment.
      expect(hw.archiveAt, DateTime.utc(2026, 10, 17, 4));
    });

    test('an older server without the fields leaves them null', () {
      final hw = HomeworkModel.fromJson({'id': 1, 'homework_name': 'Test'});
      expect(hw.createdAt, isNull);
      expect(hw.archiveAt, isNull);
    });
  });
}
