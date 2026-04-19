import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/layout/app_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// Personalized greeting header shown at the top of the schedule screen.
///
/// Displays "Привет, [Name]! 👋" with the current date and a bell icon.
/// The name is taken from [profileNotifierProvider]'s [Profile.displayName].
/// Falls back to "Привет! 👋" when profile is unavailable or name is empty.
class ScheduleHeader extends ConsumerWidget {
  const ScheduleHeader({super.key});

  static const List<String> _weekdaysFull = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  static const List<String> _monthsGenitive = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileNotifierProvider).valueOrNull;
    final name = profile?.displayName?.trim();
    final greeting =
        (name != null && name.isNotEmpty) ? 'Привет, $name! 👋' : 'Привет! 👋';

    final now = DateTime.now();
    final dateText =
        '${_weekdaysFull[now.weekday - 1]}, ${now.day} ${_monthsGenitive[now.month - 1]}';

    final Color label2 = AppColors.resolve(
      context,
      AppColors.label2Light,
      AppColors.label2Dark,
    );
    final Color label3 = AppColors.resolve(
      context,
      AppColors.label3Light,
      AppColors.label3Dark,
    );
    final double hPad = AppLayout.hPad(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTextStyles.screenTitle.copyWith(color: label2),
                ),
                const SizedBox(height: 2),
                Text(
                  dateText,
                  style: AppTextStyles.meta.copyWith(color: label3),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: null,
            child: Icon(CupertinoIcons.bell, color: label2),
          ),
        ],
      ),
    );
  }
}
