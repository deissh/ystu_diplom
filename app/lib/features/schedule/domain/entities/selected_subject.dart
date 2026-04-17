/// Субъект расписания: группа студентов или преподаватель.
///
/// Используется как ключ для выбора API-эндпоинта и параметра запроса.
sealed class SelectedSubject {
  const SelectedSubject();
}

class GroupSubject extends SelectedSubject {
  final String groupName;
  const GroupSubject(this.groupName);
}

class TeacherSubject extends SelectedSubject {
  final int teacherId;
  final String teacherName;
  const TeacherSubject(this.teacherId, this.teacherName);
}
