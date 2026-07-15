import '../models/day_plan_model.dart';

abstract class WeeklyPlanRemoteDataSource {
  Future<List<DayPlanModel>> getWeeklyPlan();
}

class WeeklyPlanRemoteDataSourceMock implements WeeklyPlanRemoteDataSource {
  @override
  Future<List<DayPlanModel>> getWeeklyPlan() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      DayPlanModel(day: 'Bazar ertəsi', lessons: [
        LessonModel(order: 1, time: '08:30 - 09:15', subject: 'Riyaziyyat', teacher: 'N. Əliyeva', room: '204'),
        LessonModel(order: 2, time: '09:25 - 10:10', subject: 'Fizika', teacher: 'R. Həsənov', room: '110'),
        LessonModel(order: 3, time: '10:20 - 11:05', subject: 'İngilis dili', teacher: 'L. Quliyeva', room: '301'),
      ]),
      DayPlanModel(day: 'Çərşənbə axşamı', lessons: [
        LessonModel(order: 1, time: '08:30 - 09:15', subject: 'Kimya', teacher: 'S. Məmmədov', room: 'Lab-2'),
        LessonModel(order: 2, time: '09:25 - 10:10', subject: 'Ədəbiyyat', teacher: 'A. Kərimli', room: '305'),
      ]),
      DayPlanModel(day: 'Çərşənbə', lessons: [
        LessonModel(order: 1, time: '08:30 - 09:15', subject: 'Tarix', teacher: 'E. Nəbiyev', room: '108'),
        LessonModel(order: 2, time: '09:25 - 10:10', subject: 'Riyaziyyat', teacher: 'N. Əliyeva', room: '204'),
        LessonModel(order: 3, time: '10:20 - 11:05', subject: 'İdman', teacher: 'V. Sadıqov', room: 'Zal'),
      ]),
      DayPlanModel(day: 'Cümə axşamı', lessons: [
        LessonModel(order: 1, time: '08:30 - 09:15', subject: 'Biologiya', teacher: 'G. Hüseynova', room: 'Lab-1'),
        LessonModel(order: 2, time: '09:25 - 10:10', subject: 'İnformatika', teacher: 'T. Abbasov', room: 'IT-1'),
      ]),
      DayPlanModel(day: 'Cümə', lessons: [
        LessonModel(order: 1, time: '08:30 - 09:15', subject: 'Coğrafiya', teacher: 'M. İsmayılova', room: '202'),
        LessonModel(order: 2, time: '09:25 - 10:10', subject: 'İngilis dili', teacher: 'L. Quliyeva', room: '301'),
      ]),
    ];
  }
}
