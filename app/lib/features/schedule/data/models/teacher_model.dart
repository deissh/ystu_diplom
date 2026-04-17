class TeacherModel {
  const TeacherModel({required this.id, required this.name});

  final int id;
  final String name;

  factory TeacherModel.fromJson(Map<String, dynamic> json) => TeacherModel(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}
