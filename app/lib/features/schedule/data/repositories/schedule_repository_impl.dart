import '../../domain/entities/lesson.dart';
import '../../domain/entities/schedule_day.dart';
import '../../domain/entities/lesson_type.dart';
import '../../domain/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  const ScheduleRepositoryImpl();

  @override
  Future<List<ScheduleDay>> getSchedule({
    required String groupId,
    required DateTime from,
    required DateTime to,
  }) async {
    // TODO: fetch from remote, fallback to local cache
    return _buildMockDays();
  }

  @override
  Stream<List<ScheduleDay>> watchSchedule({
    required String groupId,
    required DateTime from,
    required DateTime to,
  }) {
    // TODO: replace with real sync from ScheduleDao.watchLessons()
    return Stream.value(_buildMockDays());
  }

  // ── Mock data ─────────────────────────────────────────────────────────────

  static List<ScheduleDay> _buildMockDays() {
    final now = DateTime.now();
    // Start of current week (Monday)
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return [
      _day(monday, _lessonsMonday(monday)),
      _day(
        monday.add(const Duration(days: 1)),
        _lessonsTuesday(monday.add(const Duration(days: 1))),
      ),
      _day(
        monday.add(const Duration(days: 2)),
        _lessonsWednesday(monday.add(const Duration(days: 2))),
      ),
      _day(
        monday.add(const Duration(days: 3)),
        _lessonsThursday(monday.add(const Duration(days: 3))),
      ),
      _day(
        monday.add(const Duration(days: 4)),
        _lessonsFriday(monday.add(const Duration(days: 4))),
      ),
    ];
  }

  static ScheduleDay _day(DateTime date, List<Lesson> lessons) =>
      ScheduleDay(date: date, lessons: lessons);

  static DateTime _t(DateTime base, int hour, int minute) =>
      DateTime(base.year, base.month, base.day, hour, minute);

  static List<Lesson> _lessonsMonday(DateTime d) => [
    Lesson(
      subject: 'Математический анализ',
      teacher: 'Иванов А.В.',
      room: '301',
      type: LessonType.lecture,
      startTime: _t(d, 8, 0),
      endTime: _t(d, 9, 35),
    ),
    Lesson(
      subject: 'Программирование',
      teacher: 'Петрова С.И.',
      room: 'Л-12',
      type: LessonType.practice,
      startTime: _t(d, 9, 50),
      endTime: _t(d, 11, 25),
    ),
    Lesson(
      subject: 'Физика',
      teacher: 'Сидоров В.Н.',
      room: '205',
      type: LessonType.lecture,
      startTime: _t(d, 11, 40),
      endTime: _t(d, 13, 15),
    ),
  ];

  static List<Lesson> _lessonsTuesday(DateTime d) => [
    Lesson(
      subject: 'Английский язык',
      teacher: 'Смирнова О.Ю.',
      room: '115',
      type: LessonType.practice,
      startTime: _t(d, 8, 0),
      endTime: _t(d, 9, 35),
    ),
    Lesson(
      subject: 'История',
      teacher: 'Козлов Д.А.',
      room: '320',
      type: LessonType.lecture,
      startTime: _t(d, 9, 50),
      endTime: _t(d, 11, 25),
    ),
    Lesson(
      subject: 'Линейная алгебра',
      teacher: 'Иванов А.В.',
      room: '301',
      type: LessonType.practice,
      startTime: _t(d, 11, 40),
      endTime: _t(d, 13, 15),
    ),
  ];

  static List<Lesson> _lessonsWednesday(DateTime d) {
    final now = DateTime.now();
    // Make one lesson active right now so ActiveBadge and ProgressBar are visible.
    final activeStart = now.subtract(const Duration(minutes: 30));
    final activeEnd = now.add(const Duration(minutes: 60));

    return [
      Lesson(
        subject: 'Физика',
        teacher: 'Сидоров В.Н.',
        room: '205',
        type: LessonType.lab,
        startTime: _t(d, 8, 0),
        endTime: _t(d, 9, 35),
      ),
      Lesson(
        subject: 'Информатика',
        teacher: 'Петрова С.И.',
        room: 'Л-12',
        type: LessonType.lab,
        startTime: d.weekday == now.weekday ? activeStart : _t(d, 9, 50),
        endTime: d.weekday == now.weekday ? activeEnd : _t(d, 11, 25),
      ),
      Lesson(
        subject: 'Программирование',
        teacher: 'Петрова С.И.',
        room: 'Л-12',
        type: LessonType.lab,
        startTime: _t(d, 11, 40),
        endTime: _t(d, 13, 15),
      ),
      Lesson(
        subject: 'Английский язык',
        teacher: 'Смирнова О.Ю.',
        room: '115',
        type: LessonType.practice,
        startTime: _t(d, 14, 0),
        endTime: _t(d, 15, 35),
      ),
    ];
  }

  static List<Lesson> _lessonsThursday(DateTime d) => [
    Lesson(
      subject: 'Программирование',
      teacher: 'Петрова С.И.',
      room: 'Л-12',
      type: LessonType.lab,
      startTime: _t(d, 8, 0),
      endTime: _t(d, 9, 35),
    ),
    Lesson(
      subject: 'История',
      teacher: 'Козлов Д.А.',
      room: '320',
      type: LessonType.practice,
      startTime: _t(d, 9, 50),
      endTime: _t(d, 11, 25),
    ),
    Lesson(
      subject: 'Математический анализ',
      teacher: 'Иванов А.В.',
      room: '301',
      type: LessonType.lecture,
      startTime: _t(d, 11, 40),
      endTime: _t(d, 13, 15),
    ),
  ];

  static List<Lesson> _lessonsFriday(DateTime d) => [
    Lesson(
      subject: 'Физика',
      teacher: 'Сидоров В.Н.',
      room: '205',
      type: LessonType.lab,
      startTime: _t(d, 8, 0),
      endTime: _t(d, 9, 35),
    ),
    Lesson(
      subject: 'Программирование',
      teacher: 'Петрова С.И.',
      room: 'Л-12',
      type: LessonType.lecture,
      startTime: _t(d, 9, 50),
      endTime: _t(d, 11, 25),
    ),
  ];
}
