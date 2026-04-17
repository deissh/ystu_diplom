import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../schedule/data/models/group_institute_model.dart';
import '../../../schedule/data/models/teacher_model.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../domain/entities/profile.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileNotifierProvider);

    final Color bg =
        AppColors.resolve(context, AppColors.bgLight, AppColors.bgDark);
    final Color label =
        AppColors.resolve(context, AppColors.labelLight, AppColors.labelDark);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: Text('Ошибка загрузки профиля',
                  style: AppTextStyles.meta.copyWith(color: label))),
          data: (profile) => profile == null
              ? _NoProfileView(label: label)
              : _ProfileView(profile: profile),
        ),
      ),
    );
  }
}

// ── Нет профиля ───────────────────────────────────────────────────────────────

class _NoProfileView extends StatelessWidget {
  const _NoProfileView({required this.label});
  final Color label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Профиль не настроен',
        style: AppTextStyles.meta.copyWith(color: label),
      ),
    );
  }
}

// ── Отображение профиля ───────────────────────────────────────────────────────

class _ProfileView extends ConsumerStatefulWidget {
  const _ProfileView({required this.profile});
  final Profile profile;

  @override
  ConsumerState<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<_ProfileView> {
  bool _editMode = false;
  late Profile _editProfile;

  @override
  void initState() {
    super.initState();
    _editProfile = widget.profile;
  }

  @override
  void didUpdateWidget(_ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editMode) _editProfile = widget.profile;
  }

  @override
  Widget build(BuildContext context) {
    final Color bg =
        AppColors.resolve(context, AppColors.bgLight, AppColors.bgDark);
    final Color label =
        AppColors.resolve(context, AppColors.labelLight, AppColors.labelDark);
    final Color label3 = AppColors.resolve(
        context, AppColors.label3Light, AppColors.label3Dark);
    final Color accent =
        AppColors.resolve(context, AppColors.accentLight, AppColors.accentDark);
    final Color surface = AppColors.resolve(
        context, AppColors.surfaceLight, AppColors.surfaceDark);

    final profileAsync = ref.watch(profileNotifierProvider);
    final isSaving = profileAsync.isLoading;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: bg,
          floating: true,
          title: Text('Профиль',
              style: AppTextStyles.screenTitle.copyWith(color: label)),
          actions: [
            if (!_editMode)
              TextButton(
                onPressed: () => setState(() => _editMode = true),
                child: Text('Изменить',
                    style: AppTextStyles.meta.copyWith(color: accent)),
              )
            else ...[
              TextButton(
                onPressed: isSaving
                    ? null
                    : () => setState(() {
                          _editMode = false;
                          _editProfile = widget.profile;
                        }),
                child: Text('Отмена',
                    style: AppTextStyles.meta.copyWith(color: label3)),
              ),
              TextButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        await ref
                            .read(profileNotifierProvider.notifier)
                            .save(_editProfile);
                        if (mounted) setState(() => _editMode = false);
                      },
                child: isSaving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: accent))
                    : Text('Сохранить',
                        style: AppTextStyles.meta.copyWith(color: accent)),
              ),
            ],
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildModeSection(context, label, label3, surface, accent),
              const SizedBox(height: 16),
              if (_editProfile.mode == ProfileMode.student)
                _buildStudentSection(context, label, label3, surface, accent)
              else
                _buildTeacherSection(context, label, label3, surface, accent),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Секция режима ──────────────────────────────────────────────────────────

  Widget _buildModeSection(BuildContext context, Color label, Color label3,
      Color surface, Color accent) {
    return _Section(
      title: 'Режим',
      surface: surface,
      children: [
        _FieldTile(
          fieldLabel: 'Тип',
          value: _editProfile.mode == ProfileMode.student
              ? 'Студент'
              : 'Преподаватель',
          icon: _editProfile.mode == ProfileMode.student
              ? Icons.group_rounded
              : Icons.person_rounded,
          accent: accent,
          labelColor: label,
          label3: label3,
          isEditing: _editMode,
          onTap: _editMode ? () => _showModePicker(context) : null,
        ),
      ],
    );
  }

  // ── Студент ────────────────────────────────────────────────────────────────

  Widget _buildStudentSection(BuildContext context, Color label, Color label3,
      Color surface, Color accent) {
    return _Section(
      title: 'Данные',
      surface: surface,
      children: [
        _FieldTile(
          fieldLabel: 'Группа',
          value: _editProfile.groupName ?? '—',
          icon: Icons.class_rounded,
          accent: accent,
          labelColor: label,
          label3: label3,
          isEditing: _editMode,
          onTap: _editMode ? () => _showGroupPicker(context) : null,
        ),
        _divider(context),
        _FieldTile(
          fieldLabel: 'Подгруппа',
          value: _editProfile.subgroup != null
              ? '${_editProfile.subgroup}'
              : '—',
          icon: Icons.people_alt_rounded,
          accent: accent,
          labelColor: label,
          label3: label3,
          isEditing: _editMode,
          onTap: _editMode ? () => _showSubgroupPicker(context) : null,
        ),
        _divider(context),
        _NameTile(
          displayName: _editProfile.displayName,
          isEditing: _editMode,
          label: label,
          label3: label3,
          accent: accent,
          onChanged: (v) => setState(() {
            _editProfile = Profile(
              mode: _editProfile.mode,
              groupName: _editProfile.groupName,
              subgroup: _editProfile.subgroup,
              displayName: v.trim().isEmpty ? null : v.trim(),
              teacherId: _editProfile.teacherId,
              teacherName: _editProfile.teacherName,
            );
          }),
        ),
      ],
    );
  }

  // ── Преподаватель ──────────────────────────────────────────────────────────

  Widget _buildTeacherSection(BuildContext context, Color label, Color label3,
      Color surface, Color accent) {
    return _Section(
      title: 'Данные',
      surface: surface,
      children: [
        _FieldTile(
          fieldLabel: 'Преподаватель',
          value: _editProfile.teacherName ?? '—',
          icon: Icons.person_rounded,
          accent: accent,
          labelColor: label,
          label3: label3,
          isEditing: _editMode,
          onTap: _editMode ? () => _showTeacherPicker(context) : null,
        ),
      ],
    );
  }

  // ── Диалоги выбора ─────────────────────────────────────────────────────────

  Future<void> _showModePicker(BuildContext context) async {
    final mode = await showModalBottomSheet<ProfileMode>(
      context: context,
      builder: (_) => const _ModePickerSheet(),
    );
    if (mode != null && mode != _editProfile.mode) {
      setState(() {
        // При смене режима сбрасываем поля старого режима
        _editProfile = Profile(mode: mode);
      });
    }
  }

  Future<void> _showGroupPicker(BuildContext context) async {
    final group = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GroupPickerSheet(
        groupsRepo: ref.read(groupsRepositoryProvider),
      ),
    );
    if (group != null) {
      setState(() {
        _editProfile = Profile(
          mode: _editProfile.mode,
          groupName: group,
          subgroup: _editProfile.subgroup,
          displayName: _editProfile.displayName,
        );
      });
    }
  }

  Future<void> _showSubgroupPicker(BuildContext context) async {
    final subgroup = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => const _SubgroupPickerSheet(),
    );
    if (subgroup != null) {
      setState(() {
        _editProfile = Profile(
          mode: _editProfile.mode,
          groupName: _editProfile.groupName,
          subgroup: subgroup,
          displayName: _editProfile.displayName,
        );
      });
    }
  }

  Future<void> _showTeacherPicker(BuildContext context) async {
    final teacher = await showModalBottomSheet<TeacherModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TeacherPickerSheet(
        teachersRepo: ref.read(teachersRepositoryProvider),
      ),
    );
    if (teacher != null) {
      setState(() {
        _editProfile = Profile(
          mode: _editProfile.mode,
          teacherId: teacher.id,
          teacherName: teacher.name,
        );
      });
    }
  }

  Widget _divider(BuildContext context) => Divider(
        height: 1,
        color: AppColors.resolve(
            context, AppColors.separatorLight, AppColors.separatorDark),
        indent: 16,
      );
}

// ── Переиспользуемые виджеты ──────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.surface,
    required this.children,
  });

  final String title;
  final Color surface;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final Color label3 = AppColors.resolve(
        context, AppColors.label3Light, AppColors.label3Dark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.sectionHeader.copyWith(color: label3),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.fieldLabel,
    required this.value,
    required this.icon,
    required this.accent,
    required this.labelColor,
    required this.label3,
    required this.isEditing,
    required this.onTap,
  });

  final String fieldLabel;
  final String value;
  final IconData icon;
  final Color accent;
  final Color labelColor;
  final Color label3;
  final bool isEditing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: accent, size: 22),
      title: Text(fieldLabel,
          style: AppTextStyles.meta.copyWith(color: label3)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: AppTextStyles.subjectName.copyWith(color: labelColor)),
          if (isEditing) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: label3, size: 18),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

class _NameTile extends StatefulWidget {
  const _NameTile({
    required this.displayName,
    required this.isEditing,
    required this.label,
    required this.label3,
    required this.accent,
    required this.onChanged,
  });

  final String? displayName;
  final bool isEditing;
  final Color label;
  final Color label3;
  final Color accent;
  final ValueChanged<String> onChanged;

  @override
  State<_NameTile> createState() => _NameTileState();
}

class _NameTileState extends State<_NameTile> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.displayName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.badge_rounded, color: widget.accent, size: 22),
      title: Text('Имя',
          style: AppTextStyles.meta.copyWith(color: widget.label3)),
      trailing: widget.isEditing
          ? SizedBox(
              width: 160,
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.right,
                style:
                    AppTextStyles.subjectName.copyWith(color: widget.label),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Необязательно',
                ),
                onChanged: widget.onChanged,
              ),
            )
          : Text(
              widget.displayName ?? '—',
              style:
                  AppTextStyles.subjectName.copyWith(color: widget.label),
            ),
    );
  }
}

// ── Bottom sheets ─────────────────────────────────────────────────────────────

class _ModePickerSheet extends StatelessWidget {
  const _ModePickerSheet();

  @override
  Widget build(BuildContext context) {
    final Color label =
        AppColors.resolve(context, AppColors.labelLight, AppColors.labelDark);
    final Color label3 = AppColors.resolve(
        context, AppColors.label3Light, AppColors.label3Dark);
    final Color accent =
        AppColors.resolve(context, AppColors.accentLight, AppColors.accentDark);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text('Выберите режим',
                  style: AppTextStyles.subjectName.copyWith(color: label)),
            ),
            ListTile(
              leading: Icon(Icons.group_rounded, color: accent),
              title: Text('Студент',
                  style: AppTextStyles.subjectName.copyWith(color: label)),
              subtitle: Text('Расписание по группе',
                  style: AppTextStyles.meta.copyWith(color: label3)),
              onTap: () => Navigator.pop(context, ProfileMode.student),
            ),
            ListTile(
              leading: Icon(Icons.person_rounded, color: accent),
              title: Text('Преподаватель',
                  style: AppTextStyles.subjectName.copyWith(color: label)),
              subtitle: Text('Расписание по преподавателю',
                  style: AppTextStyles.meta.copyWith(color: label3)),
              onTap: () => Navigator.pop(context, ProfileMode.teacher),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubgroupPickerSheet extends StatelessWidget {
  const _SubgroupPickerSheet();

  @override
  Widget build(BuildContext context) {
    final Color label =
        AppColors.resolve(context, AppColors.labelLight, AppColors.labelDark);
    final Color accent =
        AppColors.resolve(context, AppColors.accentLight, AppColors.accentDark);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text('Выберите подгруппу',
                  style: AppTextStyles.subjectName.copyWith(color: label)),
            ),
            for (final i in [1, 2])
              ListTile(
                title: Text('Подгруппа $i',
                    style: AppTextStyles.subjectName.copyWith(color: label)),
                leading: Icon(Icons.people_alt_rounded, color: accent),
                onTap: () => Navigator.pop(context, i),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupPickerSheet extends StatefulWidget {
  const _GroupPickerSheet({required this.groupsRepo});

  final dynamic groupsRepo;

  @override
  State<_GroupPickerSheet> createState() => _GroupPickerSheetState();
}

class _GroupPickerSheetState extends State<_GroupPickerSheet> {
  List<GroupInstituteModel> _groups = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groups = await widget.groupsRepo.getGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color label =
        AppColors.resolve(context, AppColors.labelLight, AppColors.labelDark);
    final Color label3 = AppColors.resolve(
        context, AppColors.label3Light, AppColors.label3Dark);
    final Color surface = AppColors.resolve(
        context, AppColors.surfaceLight, AppColors.surfaceDark);

    if (_loading) {
      return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()));
    }

    final filtered = _groups
        .map((i) => (
              instituteName: i.instituteName,
              groups: i.groups
                  .where((g) =>
                      _query.isEmpty ||
                      g.toLowerCase().contains(_query.toLowerCase()))
                  .toList()
            ))
        .where((i) => i.groups.isNotEmpty)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Поиск группы...',
                hintStyle: AppTextStyles.meta.copyWith(color: label3),
                prefixIcon:
                    Icon(Icons.search_rounded, color: label3, size: 20),
                filled: true,
                fillColor: surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final inst = filtered[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Text(
                        inst.instituteName.toUpperCase(),
                        style: AppTextStyles.sectionHeader
                            .copyWith(color: label3),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          for (int j = 0; j < inst.groups.length; j++) ...[
                            if (j > 0)
                              Divider(
                                height: 1,
                                color: AppColors.resolve(
                                    context,
                                    AppColors.separatorLight,
                                    AppColors.separatorDark),
                                indent: 16,
                              ),
                            ListTile(
                              title: Text(inst.groups[j],
                                  style: AppTextStyles.subjectName
                                      .copyWith(color: label)),
                              onTap: () =>
                                  Navigator.pop(context, inst.groups[j]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherPickerSheet extends StatefulWidget {
  const _TeacherPickerSheet({required this.teachersRepo});

  final dynamic teachersRepo;

  @override
  State<_TeacherPickerSheet> createState() => _TeacherPickerSheetState();
}

class _TeacherPickerSheetState extends State<_TeacherPickerSheet> {
  List<TeacherModel> _teachers = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final teachers = await widget.teachersRepo.getTeachers();
    if (mounted) {
      setState(() {
        _teachers = teachers;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color label =
        AppColors.resolve(context, AppColors.labelLight, AppColors.labelDark);
    final Color label3 = AppColors.resolve(
        context, AppColors.label3Light, AppColors.label3Dark);
    final Color surface = AppColors.resolve(
        context, AppColors.surfaceLight, AppColors.surfaceDark);

    if (_loading) {
      return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()));
    }

    final filtered = _teachers
        .where((t) =>
            _query.isEmpty ||
            t.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Поиск преподавателя...',
                hintStyle: AppTextStyles.meta.copyWith(color: label3),
                prefixIcon:
                    Icon(Icons.search_rounded, color: label3, size: 20),
                filled: true,
                fillColor: surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              controller: controller,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppColors.resolve(
                    context,
                    AppColors.separatorLight,
                    AppColors.separatorDark),
                indent: 16,
              ),
              itemBuilder: (_, i) {
                final t = filtered[i];
                return ListTile(
                  tileColor: surface,
                  shape: i == 0
                      ? const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12)))
                      : i == filtered.length - 1
                          ? const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(12)))
                          : null,
                  title: Text(t.name,
                      style:
                          AppTextStyles.subjectName.copyWith(color: label)),
                  onTap: () => Navigator.pop(context, t),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
