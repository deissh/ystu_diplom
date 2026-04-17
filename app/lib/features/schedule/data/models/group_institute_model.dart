class GroupInstituteModel {
  const GroupInstituteModel({
    required this.instituteName,
    required this.groups,
  });

  final String instituteName;
  final List<String> groups;

  factory GroupInstituteModel.fromJson(Map<String, dynamic> json) =>
      GroupInstituteModel(
        instituteName: json['name'] as String,
        groups: List<String>.from(json['groups'] as List),
      );
}
