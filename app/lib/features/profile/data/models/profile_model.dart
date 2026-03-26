import '../../domain/entities/profile.dart';

class ProfileModel {
  final String id;
  final String name;
  final String groupId;
  final String groupName;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.groupId,
    required this.groupName,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        id: json['id'] as String,
        name: json['name'] as String,
        groupId: json['group_id'] as String,
        groupName: json['group_name'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'group_id': groupId,
        'group_name': groupName,
      };

  factory ProfileModel.fromEntity(Profile profile) => ProfileModel(
        id: profile.id,
        name: profile.name,
        groupId: profile.groupId,
        groupName: profile.groupName,
      );

  Profile toEntity() => Profile(
        id: id,
        name: name,
        groupId: groupId,
        groupName: groupName,
      );
}
