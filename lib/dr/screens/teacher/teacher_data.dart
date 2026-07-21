import '../../widgets/teacher_widgets.dart';

/// Placeholder fixtures ported from the `teacher_theme` mockups. There is no
/// teacher API yet, so every teacher screen reads from here.

class TeacherClassGroup {
  final String id;
  final String label;
  const TeacherClassGroup(this.id, this.label);
}

const teacherClassGroups = <TeacherClassGroup>[
  TeacherClassGroup('10a', 'Class 10 "A"'),
  TeacherClassGroup('11b', 'Class 11 "B"'),
];

class TeacherExamType {
  final String id;
  final String label;
  const TeacherExamType(this.id, this.label);
}

const teacherExamTypes = <TeacherExamType>[
  TeacherExamType('ksq1', 'KSQ - 1'),
  TeacherExamType('ksq2', 'KSQ - 2'),
  TeacherExamType('bsq1', 'BSQ - 1'),
];

class TeacherStudent {
  final int id;
  final String name;
  final String code;
  final String initials;
  const TeacherStudent(this.id, this.name, this.code, this.initials);
}

const teacherStudents = <String, List<TeacherStudent>>{
  '10a': [
    TeacherStudent(1, 'Samir Aliyev', 'STD-292', 'SA'),
    TeacherStudent(2, 'Nigar Aliyeva', 'STD-293', 'NA'),
    TeacherStudent(3, 'Elhan Hatamov', 'STD-104', 'EH'),
    TeacherStudent(4, 'Maria Smirnova', 'STD-342', 'MS'),
    TeacherStudent(5, 'Alexey Ivanov', 'STD-851', 'AI'),
  ],
  '11b': [
    TeacherStudent(6, 'Jamila Mammadova', 'STD-990', 'JM'),
    TeacherStudent(7, 'Tural Aliyev', 'STD-847', 'TA'),
    TeacherStudent(8, 'Leyla Gasimova', 'STD-542', 'LG'),
    TeacherStudent(9, 'Farid Huseynov', 'STD-112', 'FH'),
  ],
};

/// `{score, behavior, effort}` per student, keyed by class then exam type.
const teacherGrades = <String, Map<String, List<List<int>>>>{
  '10a': {
    'ksq1': [
      [92, 95, 90],
      [88, 90, 85],
      [75, 85, 80],
      [95, 98, 95],
      [80, 80, 75],
    ],
    'ksq2': [
      [95, 97, 94],
      [91, 92, 90],
      [84, 88, 86],
      [98, 99, 97],
      [72, 80, 78],
    ],
    'bsq1': [
      [88, 90, 88],
      [85, 87, 85],
      [68, 75, 72],
      [90, 93, 91],
      [65, 70, 68],
    ],
  },
  '11b': {
    'ksq1': [
      [96, 98, 96],
      [84, 85, 82],
      [91, 93, 90],
      [82, 80, 80],
    ],
    'ksq2': [
      [94, 96, 93],
      [88, 90, 87],
      [89, 91, 88],
      [78, 80, 78],
    ],
    'bsq1': [
      [90, 92, 90],
      [80, 82, 80],
      [85, 88, 85],
      [75, 78, 75],
    ],
  },
};

class TeacherLesson {
  final String time;
  final String duration;
  final String subject;
  final String group;
  final String room;
  final TeacherLessonStatus status;
  const TeacherLesson({
    required this.time,
    required this.duration,
    required this.subject,
    required this.group,
    required this.room,
    required this.status,
  });
}

const teacherWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

const teacherTimetable = <String, List<TeacherLesson>>{
  'Mon': [
    TeacherLesson(
      time: '09:00',
      duration: '45 Mins',
      subject: 'Algebra & Calculus',
      group: "Class 10 'A'",
      room: 'Room 402',
      status: TeacherLessonStatus.completed,
    ),
    TeacherLesson(
      time: '10:00',
      duration: '45 Mins',
      subject: 'Algebra & Calculus',
      group: "Class 11 'B'",
      room: 'Room 402',
      status: TeacherLessonStatus.completed,
    ),
    TeacherLesson(
      time: '11:00',
      duration: '45 Mins',
      subject: 'Geometry',
      group: "Class 10 'A'",
      room: 'Room 403',
      status: TeacherLessonStatus.completed,
    ),
  ],
  'Tue': [
    TeacherLesson(
      time: '09:00',
      duration: '45 Mins',
      subject: 'Geometry',
      group: "Class 11 'B'",
      room: 'Room 403',
      status: TeacherLessonStatus.completed,
    ),
    TeacherLesson(
      time: '10:00',
      duration: '45 Mins',
      subject: 'Algebra & Calculus',
      group: "Class 10 'A'",
      room: 'Room 402',
      status: TeacherLessonStatus.completed,
    ),
  ],
  'Wed': [
    TeacherLesson(
      time: '09:00',
      duration: '45 Mins',
      subject: 'Algebra & Calculus',
      group: "Class 10 'A'",
      room: 'Room 402',
      status: TeacherLessonStatus.completed,
    ),
    TeacherLesson(
      time: '10:00',
      duration: '45 Mins',
      subject: 'Algebra & Calculus',
      group: "Class 11 'B'",
      room: 'Room 402',
      status: TeacherLessonStatus.ongoing,
    ),
    TeacherLesson(
      time: '11:00',
      duration: '45 Mins',
      subject: 'Geometry',
      group: "Class 10 'A'",
      room: 'Room 403',
      status: TeacherLessonStatus.upcoming,
    ),
  ],
  'Thu': [
    TeacherLesson(
      time: '10:00',
      duration: '45 Mins',
      subject: 'Algebra & Calculus',
      group: "Class 10 'A'",
      room: 'Room 402',
      status: TeacherLessonStatus.upcoming,
    ),
    TeacherLesson(
      time: '11:00',
      duration: '45 Mins',
      subject: 'Geometry',
      group: "Class 11 'B'",
      room: 'Room 403',
      status: TeacherLessonStatus.upcoming,
    ),
  ],
  'Fri': [
    TeacherLesson(
      time: '09:00',
      duration: '45 Mins',
      subject: 'Algebra & Calculus',
      group: "Class 11 'B'",
      room: 'Room 402',
      status: TeacherLessonStatus.upcoming,
    ),
    TeacherLesson(
      time: '12:00',
      duration: '45 Mins',
      subject: 'Math Elective',
      group: 'Class 10-11',
      room: 'Room 402',
      status: TeacherLessonStatus.upcoming,
    ),
  ],
};
