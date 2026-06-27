import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

// Logs only in debug mode. Never log sensitive data:
// no tokens, no message content, no private keys, no PINs.
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(),
    level: kDebugMode ? Level.trace : Level.off,
  );

  static void debug(String message) {
    if (kDebugMode) _logger.d(message);
  }

  static void info(String message) {
    if (kDebugMode) _logger.i(message);
  }

  static void warning(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (kDebugMode) _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (kDebugMode) _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static void fatal(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (kDebugMode) _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
