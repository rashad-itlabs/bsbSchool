import 'package:bsbschool/features/homework/domain/entities/homework.dart';
import 'package:bsbschool/features/homework/presentation/bloc/homework_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = () {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}();

DateTime _daysAgo(int days) => _today.subtract(Duration(days: days));

Homework _hw(
  int id, {
  DateTime? due,
  DateTime? assigned,
  String subject = 'Riyaziyyat',
}) =>
    Homework(
      id: id,
      name: 'Tapşırıq $id',
      subject: subject,
      submitDate: due,
      homeworkDate: assigned,
    );

List<int> _ids(List<Homework> list) => [for (final hw in list) hw.id];

void main() {
  // The API order, deliberately oldest first and mixed with active work.
  final homeworks = [
    _hw(1, due: _daysAgo(30), assigned: _daysAgo(37)),
    _hw(2, due: _today.add(const Duration(days: 3))),
    _hw(3, due: _daysAgo(10), assigned: _daysAgo(20)),
    _hw(4, due: _daysAgo(1), assigned: _daysAgo(5), subject: 'Fizika'),
    _hw(5, due: _daysAgo(10), assigned: _daysAgo(12), subject: 'Fizika'),
    _hw(6),
    _hw(7, due: _today),
    _hw(8, due: _daysAgo(10)),
  ];

  group('the past tab', () {
    final state = HomeworkState(
      status: HomeworkStatus.loaded,
      homeworks: homeworks,
      tab: HomeworkTab.past,
    );

    test('lists the newest deadline first, the oldest last', () {
      // 4 closed yesterday; 5, 3 and 8 ten days ago; 1 a month ago.
      expect(_ids(state.tabHomeworks), [4, 5, 3, 8, 1]);
    });

    test('on the same deadline, the more recently assigned leads', () {
      final sameDay = _ids(state.tabHomeworks).where([5, 3, 8].contains);
      // 5 was assigned after 3; 8 has no assigned date and goes last.
      expect(sameDay, [5, 3, 8]);
    });

    test('a subject filter keeps the order', () {
      // No section on these: the subject is what the filter matches by.
      final fizika = state.withFilters(sections: {'Fizika'}, statuses: {});
      expect(_ids(fizika.visibleHomeworks), [4, 5]);
    });
  });

  test('the active tab keeps the order the API sent', () {
    final state = HomeworkState(
      status: HomeworkStatus.loaded,
      homeworks: homeworks,
    );

    // Due today still counts as active, and so does no deadline at all.
    expect(_ids(state.tabHomeworks), [2, 6, 7]);
  });
}
