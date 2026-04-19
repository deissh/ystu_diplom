import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../schedule/data/models/group_institute_model.dart';
import '../../../schedule/data/models/teacher_model.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
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

    return CupertinoPageScaffold(
      backgroundColor: bg,
      child: profileAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Ошибка загрузки профиля',
            style: AppTextStyles.meta.copyWith(color: label),
          ),
        ),
        data: (profile) => profile == null
            ? _NoProfileView(label: label)
            : _ProfileView(profile: profile),
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
  bool _isResetting = false;

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

    final hPad = AppLayout.hPad(context);
    final bottomPad = _kTabBarHeight + MediaQuery.of(context).padding.bottom;

    return ColoredBox(
      color: bg,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Профиль'),
            trailing: _editMode
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: isSaving
                            ? null
                            : () => setState(() {
                                  _editMode = false;
                                  _editProfile = widget.profile;
                                }),
                        child: Text(
                          'Отмена',
                          style: AppTextStyles.meta.copyWith(color: label3),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: isSaving
                            ? null
                            : () async {
                                await ref
                                    .read(profileNotifierProvider.notifier)
                                    .save(_editProfile);
                                if (mounted) setState(() => _editMode = false);
                              },
                        child: isSaving
                            ? const CupertinoActivityIndicator()
                            : Text(
                                'Сохранить',
                                style:
                                    AppTextStyles.meta.copyWith(color: accent),
                              ),
                      ),
                    ],
                  )
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _editMode = true),
                    child: Text(
                      'Изменить',
                      style: AppTextStyles.meta.copyWith(color: accent),
                    ),
                  ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, bottomPad + 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildModeSection(context, label, label3, surface, accent),
                const SizedBox(height: 16),
                if (_editProfile.mode == ProfileMode.student)
                  _buildStudentSection(context, label, label3, surface, accent)
                else
                  _buildTeacherSection(context, label, label3, surface, accent),
                const SizedBox(height: 32),
                _buildThemeSection(context, label, label3, surface),
                const SizedBox(height: 16),
                _buildDataSection(context, label3, surface),
              ]),
            ),
          ),
        ],
      ),
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
              ? CupertinoIcons.person_2
              : CupertinoIcons.person,
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
          icon: CupertinoIcons.book,
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
          icon: CupertinoIcons.person_2,
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
          icon: CupertinoIcons.person,
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
    final mode = await showCupertinoModalPopup<ProfileMode>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Выберите режим'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ProfileMode.student),
            child: const Text('Студент'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ProfileMode.teacher),
            child: const Text('Преподаватель'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Отмена'),
        ),
      ),
    );
    if (mode != null && mode != _editProfile.mode) {
      setState(() {
        _editProfile = Profile(mode: mode);
      });
    }
  }

  Future<void> _showGroupPicker(BuildContext context) async {
    final bg =
        AppColors.resolve(context, AppColors.bgLight, AppColors.bgDark);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final group = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => SizedBox(
        height: screenHeight * 0.85,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ColoredBox(
            color: bg,
            child: _GroupPickerSheet(
              groupsRepo: ref.read(groupsRepositoryProvider),
            ),
          ),
        ),
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
    final subgroup = await showCupertinoModalPopup<int>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Выберите подгруппу'),
        actions: [
          for (final i in [1, 2])
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, i),
              child: Text('Подгруппа $i'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Отмена'),
        ),
      ),
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
    final bg =
        AppColors.resolve(context, AppColors.bgLight, AppColors.bgDark);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final teacher = await showCupertinoModalPopup<TeacherModel>(
      context: context,
      builder: (ctx) => SizedBox(
        height: screenHeight * 0.85,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ColoredBox(
            color: bg,
            child: _TeacherPickerSheet(
              teachersRepo: ref.read(teachersRepositoryProvider),
            ),
          ),
        ),
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

  // ── Тема оформления ───────────────────────────────────────────────────────

  Widget _buildThemeSection(
      BuildContext context, Color label, Color label3, Color surface) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final selected = settingsAsync.valueOrNull?.theme ?? AppTheme.system;

    return _Section(
      title: 'Внешний вид',
      surface: surface,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Тема оформления',
                style: AppTextStyles.meta.copyWith(color: label3),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<AppTheme>(
                  groupValue: selected,
                  children: const {
                    AppTheme.system: Text('Авто'),
                    AppTheme.light: Text('Светлая'),
                    AppTheme.dark: Text('Тёмная'),
                  },
                  onValueChanged: (v) {
                    if (v != null) {
                      ref
                          .read(settingsNotifierProvider.notifier)
                          .setTheme(v);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Сброс данных ──────────────────────────────────────────────────────────

  Widget _buildDataSection(
      BuildContext context, Color label3, Color surface) {
    final Color red =
        AppColors.resolve(context, AppColors.redLight, AppColors.redDark);

    return _Section(
      title: 'Данные',
      surface: surface,
      children: [
        GestureDetector(
          onTap: _isResetting ? null : _confirmReset,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Сбросить данные и настройки',
                    style: TextStyle(
                      color:
                          _isResetting ? red.withValues(alpha: 0.4) : red,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_isResetting)
                  CupertinoActivityIndicator(
                    color: red.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Сбросить данные?'),
        content: const Text(
          'Все данные профиля и кэш расписания будут удалены. '
          'Отменить действие невозможно.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isResetting = true);
    try {
      await ref.read(settingsNotifierProvider.notifier).resetAllData();
    } catch (e, st) {
      AppLogger.error('ProfileScreen._confirmReset: $e\n$st');
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  Widget _divider(BuildContext context) => Container(
        height: 0.5,
        margin: const EdgeInsets.only(left: 16),
        color: AppColors.resolve(
            context, AppColors.separatorLight, AppColors.separatorDark),
      );
}

// ── Переиспользуемые виджеты ──────────────────────────────────────────────────

/// Height of the custom iOS tab bar (matches _kTabBarHeight in app_router.dart).
const double _kTabBarHeight = 49.0;

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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(width: 12),
            Text(fieldLabel,
                style: AppTextStyles.meta.copyWith(color: label3)),
            const Spacer(),
            Text(value,
                style:
                    AppTextStyles.subjectName.copyWith(color: labelColor)),
            if (isEditing) ...[
              const SizedBox(width: 4),
              Icon(CupertinoIcons.chevron_right, color: label3, size: 18),
            ],
          ],
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(CupertinoIcons.tag, color: widget.accent, size: 22),
          const SizedBox(width: 12),
          Text('Имя',
              style: AppTextStyles.meta.copyWith(color: widget.label3)),
          const Spacer(),
          if (widget.isEditing)
            SizedBox(
              width: 160,
              child: CupertinoTextField(
                controller: _controller,
                textAlign: TextAlign.right,
                style: AppTextStyles.subjectName
                    .copyWith(color: widget.label),
                placeholder: 'Необязательно',
                decoration: null,
                onChanged: widget.onChanged,
              ),
            )
          else
            Text(
              widget.displayName ?? '—',
              style:
                  AppTextStyles.subjectName.copyWith(color: widget.label),
            ),
        ],
      ),
    );
  }
}

// ── Bottom sheets (поиск) ─────────────────────────────────────────────────────

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
      return const Center(child: CupertinoActivityIndicator());
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

    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CupertinoSearchTextField(
            onChanged: (v) => setState(() => _query = v),
            placeholder: 'Поиск группы...',
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      style: AppTextStyles.sectionHeader.copyWith(color: label3),
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
                            Container(
                              height: 0.5,
                              margin: const EdgeInsets.only(left: 16),
                              color: AppColors.resolve(context,
                                  AppColors.separatorLight,
                                  AppColors.separatorDark),
                            ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pop(context, inst.groups[j]),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      inst.groups[j],
                                      style: AppTextStyles.subjectName
                                          .copyWith(color: label),
                                    ),
                                  ),
                                  Icon(CupertinoIcons.chevron_right,
                                      color: label3, size: 16),
                                ],
                              ),
                            ),
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
      return const Center(child: CupertinoActivityIndicator());
    }

    final filtered = _teachers
        .where((t) =>
            _query.isEmpty ||
            t.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CupertinoSearchTextField(
            onChanged: (v) => setState(() => _query = v),
            placeholder: 'Поиск преподавателя...',
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final t = filtered[i];
              final isFirst = i == 0;
              final isLast = i == filtered.length - 1;
              return Column(
                children: [
                  if (!isFirst)
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.only(left: 16),
                      color: AppColors.resolve(context,
                          AppColors.separatorLight, AppColors.separatorDark),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: isFirst ? const Radius.circular(12) : Radius.zero,
                      bottom:
                          isLast ? const Radius.circular(12) : Radius.zero,
                    ),
                    child: ColoredBox(
                      color: surface,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, t),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.name,
                                  style: AppTextStyles.subjectName
                                      .copyWith(color: label),
                                ),
                              ),
                              Icon(CupertinoIcons.chevron_right,
                                  color: label3, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
