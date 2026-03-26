// ignore: depend_on_referenced_packages
import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  static void warning(String message) {
    if (kDebugMode) debugPrint('[WARN] $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) debugPrint('[ERROR] $message${error != null ? ': $error' : ''}');
    if (kDebugMode && stackTrace != null) debugPrintStack(stackTrace: stackTrace);
  }
}
