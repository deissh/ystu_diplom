import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/startup/app_startup_notifier.dart';

/// Мост между Riverpod [appStartupProvider] и GoRouter.
///
/// GoRouter использует его как [refreshListenable]: при изменении startup state
/// (например, после завершения онбординга) GoRouter повторно вычисляет redirect.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<AppStartupData>>(
      appStartupProvider,
      (prev, next) => notifyListeners(),
    );
  }

  final Ref _ref;

  /// true если онбординг завершён.
  bool get onboardingComplete =>
      _ref.read(appStartupProvider).valueOrNull?.onboardingComplete ?? false;
}

final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});
