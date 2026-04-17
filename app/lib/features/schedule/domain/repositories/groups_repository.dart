import '../../data/models/group_institute_model.dart';

abstract interface class GroupsRepository {
  Future<List<GroupInstituteModel>> getGroups();
  Stream<List<GroupInstituteModel>> watchGroups();
}
