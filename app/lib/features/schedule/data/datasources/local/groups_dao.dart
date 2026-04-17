import 'package:drift/drift.dart';

import '../../models/group_institute_model.dart';
import 'drift_database.dart';

part 'groups_dao.g.dart';

@DriftAccessor(tables: [Groups])
class GroupsDao extends DatabaseAccessor<AppDatabase> with _$GroupsDaoMixin {
  GroupsDao(super.db);

  Future<List<GroupData>> getAllGroups() => select(groups).get();

  Stream<List<GroupData>> watchAllGroups() => select(groups).watch();

  Future<void> upsertGroups(List<GroupInstituteModel> institutes) => batch(
        (b) => b.insertAllOnConflictUpdate(
          groups,
          [
            for (final inst in institutes)
              for (final groupName in inst.groups)
                GroupsCompanion.insert(
                  instituteName: inst.instituteName,
                  groupName: groupName,
                ),
          ],
        ),
      );
}
