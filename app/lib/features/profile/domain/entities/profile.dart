enum ProfileMode { student, teacher }

class Profile {
  final ProfileMode mode;

  // Student fields
  final String? groupName;
  final int? subgroup;
  final String? displayName;

  // Teacher fields
  final int? teacherId;
  final String? teacherName;

  const Profile({
    required this.mode,
    this.groupName,
    this.subgroup,
    this.displayName,
    this.teacherId,
    this.teacherName,
  });
}
