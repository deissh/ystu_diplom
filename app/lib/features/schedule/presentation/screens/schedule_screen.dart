import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/errors/failure.dart';
import '../providers/schedule_provider.dart';
import '../utils/schedule_ui_helpers.dart';
import '../widgets/schedule_header.dart';
import '../widgets/sync_status_bar.dart';
import '../widgets/week_strip.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final scheduleAsync = ref.watch(scheduleProvider);

    final Color bg = AppColors.resolve(
      context,
      AppColors.bgLight,
      AppColors.bgDark,
    );

    return CupertinoPageScaffold(
      child: ColoredBox(
        color: bg,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const SyncStatusBar(),
              const SizedBox(height: 12),
              const ScheduleHeader(),
              const SizedBox(height: 8),
              const WeekStrip(),
              const SizedBox(height: 12),
              Expanded(
                child: scheduleAsync.when(
                  data: (days) {
                    final subject = ref.read(selectedSubjectProvider);
                    if (subject == null) {
                      return const _NoGroupState();
                    }
                    if (selectedDay.weekday > DateTime.friday) {
                      return const _WeekendState();
                    }
                    final lessons = lessonsForDay(days, selectedDay);
                    if (lessons.isEmpty) {
                      return const _FreeDayState();
                    }
                    final now = ref.watch(nowProvider).valueOrNull;
                    final today = DateTime.now();
                    final isToday = selectedDay.year == today.year &&
                        selectedDay.month == today.month &&
                        selectedDay.day == today.day;
                    final hPad = AppLayout.hPad(context);
                    final bottomPad = _kTabBarHeight +
                        MediaQuery.of(context).padding.bottom;

                    final String sectionLabel = isToday
                        ? 'СЕГОДНЯ • ${lessons.length} ${_lessonsWord(lessons.length)}'
                        : '${_kDayAbbr[selectedDay.weekday - 1]}, ${selectedDay.day} ${_kMonthGenitive[selectedDay.month - 1]} • ${lessons.length} ${_lessonsWord(lessons.length)}';

                    final Color label3 = AppColors.resolve(
                      context,
                      AppColors.label3Light,
                      AppColors.label3Dark,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 8),
                          child: Text(
                            sectionLabel,
                            style: AppTextStyles.sectionHeader.copyWith(
                              color: label3,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding:
                                EdgeInsets.fromLTRB(hPad, 0, hPad, bottomPad),
                            children: buildScheduleItems(
                              lessons,
                              now: isToday ? now : null,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CupertinoActivityIndicator()),
                  error: (error, _) => _ErrorState(
                    error: error,
                    onRetry: () => ref.invalidate(scheduleProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Height of the custom iOS tab bar (matches _kTabBarHeight in app_router.dart).
const double _kTabBarHeight = 49.0;

const List<String> _kDayAbbr = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

const List<String> _kMonthGenitive = [
  'ЯНВАРЯ',
  'ФЕВРАЛЯ',
  'МАРТА',
  'АПРЕЛЯ',
  'МАЯ',
  'ИЮНЯ',
  'ИЮЛЯ',
  'АВГУСТА',
  'СЕНТЯБРЯ',
  'ОКТЯБРЯ',
  'НОЯБРЯ',
  'ДЕКАБРЯ',
];

/// Returns the correct Russian genitive form of "пара" for a given count.
///
/// 1, 21 → "ПАРА"; 2–4, 22–24 → "ПАРЫ"; 5–20, 25–30… → "ПАР".
String _lessonsWord(int n) {
  final mod100 = n % 100;
  final mod10 = n % 10;
  if (mod100 >= 11 && mod100 <= 14) return 'ПАР';
  if (mod10 == 1) return 'ПАРА';
  if (mod10 >= 2 && mod10 <= 4) return 'ПАРЫ';
  return 'ПАР';
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _NoGroupState extends StatelessWidget {
  const _NoGroupState();

  @override
  Widget build(BuildContext context) =>
      _StateMessage(message: 'Выберите группу в Настройках');
}

class _WeekendState extends StatelessWidget {
  const _WeekendState();

  @override
  Widget build(BuildContext context) =>
      _StateMessage(message: 'Выходной - отдыхай!');
}

class _FreeDayState extends StatelessWidget {
  const _FreeDayState();

  @override
  Widget build(BuildContext context) =>
      _StateMessage(message: 'Нет пар - свободный день');
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Color label3 = AppColors.resolve(
      context,
      AppColors.label3Light,
      AppColors.label3Dark,
    );

    final message = switch (error) {
      NetworkFailure() => 'Не удалось загрузить расписание: проблемы с сетью',
      ParseFailure() => 'Не удалось обработать данные расписания',
      CacheFailure() => 'Не удалось прочитать сохранённое расписание',
      _ => 'Ошибка загрузки расписания',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.meta.copyWith(color: label3),
            ),
            const SizedBox(height: 12),
            CupertinoButton.filled(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final Color label3 = AppColors.resolve(
      context,
      AppColors.label3Light,
      AppColors.label3Dark,
    );
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.meta.copyWith(color: label3),
      ),
    );
  }
}
