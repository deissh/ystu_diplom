import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/domain/entities/profile.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/group_picker_page.dart';
import '../widgets/mode_selection_page.dart';
import '../widgets/name_entry_page.dart';
import '../widgets/subgroup_picker_page.dart';
import '../widgets/teacher_picker_page.dart';

/// Мультишаговый онбординг-wizard.
///
/// Использует [PageView] с [NeverScrollableScrollPhysics] — навигация только
/// программная. Кнопка «Назад» возвращает на предыдущую страницу.
///
/// Страницы:
///   0 — Выбор режима (Student / Teacher)
///   1 — Выбор группы (student) или преподавателя (teacher)
///   2 — Выбор подгруппы (student only)
///   3 — Ввод имени (student only)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    setState(() => _currentPage = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _back() {
    if (_currentPage > 0) _goTo(_currentPage - 1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    final Color bg =
        AppColors.resolve(context, AppColors.bgLight, AppColors.bgDark);

    final pages = _buildPages(state);

    return CupertinoPageScaffold(
      backgroundColor: bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentPage > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: CupertinoButton(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  onPressed: _back,
                  child: const Icon(CupertinoIcons.back),
                ),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: pages,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPages(OnboardingState state) {
    final modePage = ModeSelectionPage(
      onModeSelected: () => _goTo(1),
    );

    Widget listPage;
    if (state.mode == ProfileMode.teacher) {
      listPage = TeacherPickerPage(
        onTeacherSelected: () {
          ref.read(onboardingProvider.notifier).complete();
        },
      );
    } else {
      listPage = GroupPickerPage(
        onGroupSelected: () => _goTo(2),
      );
    }

    if (state.mode == ProfileMode.teacher) {
      return [modePage, listPage];
    }

    final subgroupPage = SubgroupPickerPage(
      onSubgroupSelected: () => _goTo(3),
    );

    final namePage = NameEntryPage(
      onFinish: () => ref.read(onboardingProvider.notifier).complete(),
    );

    return [modePage, listPage, subgroupPage, namePage];
  }
}
