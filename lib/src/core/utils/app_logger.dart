import 'package:logger/logger.dart';

/// Centralized logger for the application
/// 
/// Usage:
/// - AppLogger.info('Message') - for informational messages
/// - AppLogger.debug('Message') - for debug information
/// - AppLogger.warning('Message') - for warnings
/// - AppLogger.error('Message', error, stackTrace) - for errors
/// - AppLogger.trace('Message') - for detailed traces
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  /// Log informational message (green)
  static void info(String message) {
    _logger.i(message);
  }

  /// Log debug message (blue)
  static void debug(String message) {
    _logger.d(message);
  }

  /// Log warning message (orange)
  static void warning(String message) {
    _logger.w(message);
  }

  /// Log error message (red)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log trace/verbose message (grey)
  static void trace(String message) {
    _logger.t(message);
  }
}
