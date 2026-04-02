enum LessonType {
  lecture,
  practice,
  lab,
  other;

  String get label => switch (this) {
    LessonType.lecture => 'ЛЕК',
    LessonType.practice => 'ПР',
    LessonType.lab => 'ЛАБ',
    LessonType.other => '?',
  };

  static LessonType fromString(String value) => switch (value.toUpperCase()) {
    'ЛЕК' || 'LECTURE' => LessonType.lecture,
    'ПР' || 'PRACTICE' => LessonType.practice,
    'ЛАБ' || 'LAB' => LessonType.lab,
    _ => LessonType.other,
  };
}
