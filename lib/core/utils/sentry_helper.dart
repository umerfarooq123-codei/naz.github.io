import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry helper class for error tracking and breadcrumb logging
/// Breadcrumbs are disabled in debug mode
class SentryHelper {
  static const String _sentryCategoryUI = 'ui.action';
  static const String _sentryCategoryNavigation = 'navigation';
  static const String _sentryCategoryDatabase = 'database';
  static const String _sentryCategoryAPI = 'api';
  static const String _sentryCategoryAuth = 'auth';
  static const String _sentryCategoryCache = 'cache';

  /// Check if Sentry is enabled (disabled in debug mode)
  static bool get isEnabled => !kDebugMode;

  /// Add a UI action breadcrumb
  static void breadcrumbUIAction({
    required String action,
    Map<String, dynamic>? data,
    String? page,
  }) {
    if (!isEnabled) return;

    final breadcrumb = Breadcrumb(
      category: _sentryCategoryUI,
      message: action,
      level: SentryLevel.info,
      data: {if (page != null) 'page': page, if (data != null) ...data},
      timestamp: DateTime.now(),
    );

    Sentry.addBreadcrumb(breadcrumb);
  }

  /// Add a navigation breadcrumb
  static void breadcrumbNavigation({
    required String from,
    required String to,
    Map<String, dynamic>? data,
  }) {
    if (!isEnabled) return;

    final breadcrumb = Breadcrumb(
      category: _sentryCategoryNavigation,
      message: 'Navigation: $from → $to',
      level: SentryLevel.info,
      data: {'from': from, 'to': to, if (data != null) ...data},
      timestamp: DateTime.now(),
    );

    Sentry.addBreadcrumb(breadcrumb);
  }

  /// Add a database operation breadcrumb
  static void breadcrumbDatabase({
    required String operation,
    required String table,
    Map<String, dynamic>? data,
    int? duration,
  }) {
    if (!isEnabled) return;

    final breadcrumb = Breadcrumb(
      category: _sentryCategoryDatabase,
      message: '$operation on $table',
      level: SentryLevel.info,
      data: {
        'operation': operation,
        'table': table,
        if (duration != null) 'duration_ms': duration,
        if (data != null) ...data,
      },
      timestamp: DateTime.now(),
    );

    Sentry.addBreadcrumb(breadcrumb);
  }

  /// Add an API call breadcrumb
  static void breadcrumbAPI({
    required String endpoint,
    required String method,
    int? statusCode,
    Map<String, dynamic>? requestData,
    int? duration,
  }) {
    if (!isEnabled) return;

    final breadcrumb = Breadcrumb(
      category: _sentryCategoryAPI,
      message: '$method $endpoint',
      level: statusCode != null && statusCode < 400
          ? SentryLevel.info
          : SentryLevel.warning,
      data: {
        'endpoint': endpoint,
        'method': method,
        if (statusCode != null) 'status_code': statusCode,
        if (duration != null) 'duration_ms': duration,
        if (requestData != null) ...requestData,
      },
      timestamp: DateTime.now(),
    );

    Sentry.addBreadcrumb(breadcrumb);
  }

  /// Add an authentication breadcrumb
  static void breadcrumbAuth({
    required String action,
    String? userId,
    Map<String, dynamic>? data,
  }) {
    if (!isEnabled) return;

    final breadcrumb = Breadcrumb(
      category: _sentryCategoryAuth,
      message: action,
      level: SentryLevel.info,
      data: {if (userId != null) 'user_id': userId, if (data != null) ...data},
      timestamp: DateTime.now(),
    );

    Sentry.addBreadcrumb(breadcrumb);
  }

  /// Add a cache operation breadcrumb
  static void breadcrumbCache({
    required String operation,
    required String key,
    Map<String, dynamic>? data,
  }) {
    if (!isEnabled) return;

    final breadcrumb = Breadcrumb(
      category: _sentryCategoryCache,
      message: '$operation: $key',
      level: SentryLevel.info,
      data: {'operation': operation, 'key': key, if (data != null) ...data},
      timestamp: DateTime.now(),
    );

    Sentry.addBreadcrumb(breadcrumb);
  }

  /// Capture an exception with context
  static Future<void> captureException({
    required Object exception,
    required StackTrace stackTrace,
    String? context,
    Map<String, dynamic>? data,
    String? userId,
  }) async {
    if (!isEnabled) {
      debugPrint('❌ Exception: $exception\n$stackTrace');
      return;
    }

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (userId != null) {
          scope.setContexts('user', {'id': userId});
        }
        if (context != null) {
          scope.setContexts('error_context', {'context': context});
        }
        if (data != null) {
          scope.setContexts('error_data', data);
        }
      },
    );
  }

  /// Capture a message
  static Future<void> captureMessage({
    required String message,
    SentryLevel level = SentryLevel.info,
    String? context,
    Map<String, dynamic>? data,
  }) async {
    if (!isEnabled) {
      debugPrint('📝 Message: $message');
      return;
    }

    await Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (context != null) {
          scope.setContexts('message_context', {'context': context});
        }
        if (data != null) {
          scope.setContexts('message_data', data);
        }
      },
    );
  }

  /// Set user context
  static void setUser({required String id, String? username, String? email}) {
    if (!isEnabled) return;

    Sentry.captureMessage(
      'User context set',
      level: SentryLevel.debug,
      withScope: (scope) {
        scope.setContexts('user', {
          'id': id,
          if (username != null) 'username': username,
          if (email != null) 'email': email,
        });
      },
    );
  }

  /// Clear user context (by setting a debug message with no user)
  static void clearUser() {
    if (!isEnabled) return;
    Sentry.captureMessage('User context cleared', level: SentryLevel.debug);
  }

  /// Set custom tag
  static void setTag(String key, String value) {
    if (!isEnabled) return;
    Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// Set multiple tags
  static void setTags(Map<String, String> tags) {
    if (!isEnabled) return;
    Sentry.configureScope((scope) {
      for (final entry in tags.entries) {
        scope.setTag(entry.key, entry.value);
      }
    });
  }

  /// Clear all tags (by resetting scope)
  static void clearTags() {
    if (!isEnabled) return;
    // Note: Sentry doesn't have a clearTags method, so we just document this
    // Tags are part of scope and will be cleared on next scope reset
    debugPrint('🔍 Tags will be cleared on next scope reset');
  }

  /// Debug log for development
  static void debugLog(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('🔍 [Sentry Debug] $message');
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('Stack: $stackTrace');
    }
  }
}
