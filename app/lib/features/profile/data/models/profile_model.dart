import '../../domain/entities/profile.dart';

class ProfileModel {
  final String mode;
  final String? groupName;
  final int? subgroup;
  final String? displayName;
  final int? teacherId;
  final String? teacherName;

  const ProfileModel({
    required this.mode,
    this.groupName,
    this.subgroup,
    this.displayName,
    this.teacherId,
    this.teacherName,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        mode: json['mode'] as String,
        groupName: json['group_name'] as String?,
        subgroup: json['subgroup'] as int?,
        displayName: json['display_name'] as String?,
        teacherId: json['teacher_id'] as int?,
        teacherName: json['teacher_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'group_name': groupName,
        'subgroup': subgroup,
        'display_name': displayName,
        'teacher_id': teacherId,
        'teacher_name': teacherName,
      };

  factory ProfileModel.fromEntity(Profile profile) => ProfileModel(
        mode: profile.mode.name,
        groupName: profile.groupName,
        subgroup: profile.subgroup,
        displayName: profile.displayName,
        teacherId: profile.teacherId,
        teacherName: profile.teacherName,
      );

  Profile toEntity() => Profile(
        mode: ProfileMode.values.byName(mode),
        groupName: groupName,
        subgroup: subgroup,
        displayName: displayName,
        teacherId: teacherId,
        teacherName: teacherName,
      );
}
