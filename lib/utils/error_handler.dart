import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async'; // Add this import for TimeoutException

/// Types of application errors
enum ErrorType {
  network,
  database,
  authentication,
  validation,
  api,
  storage,
  unknown,
}

/// Types of error severity
enum ErrorSeverity {
  low, // User can continue using the app
  medium, // Some functionality is impacted
  high, // Critical functionality is broken
  critical, // App cannot function properly
}

/// Standardized error class for the application
class AppError {
  final ErrorType type;
  final ErrorSeverity severity;
  final String message;
  final String? technicalDetails;
  final String? userAction;
  final DateTime timestamp;
  final StackTrace? stackTrace;

  AppError({
    required this.type,
    required this.severity,
    required this.message,
    this.technicalDetails,
    this.userAction,
    this.stackTrace,
  }) : timestamp = DateTime.now();

  /// Create a network error
  factory AppError.network(
    String message, {
    String? technicalDetails,
    String? userAction,
  }) {
    return AppError(
      type: ErrorType.network,
      severity: ErrorSeverity.medium,
      message: message,
      technicalDetails: technicalDetails,
      userAction:
          userAction ?? 'Please check your internet connection and try again.',
    );
  }

  /// Create a database error
  factory AppError.database(
    String message, {
    String? technicalDetails,
    String? userAction,
  }) {
    return AppError(
      type: ErrorType.database,
      severity: ErrorSeverity.high,
      message: message,
      technicalDetails: technicalDetails,
      userAction: userAction ?? 'Please try again later.',
    );
  }

  /// Create an authentication error
  factory AppError.authentication(
    String message, {
    String? technicalDetails,
    String? userAction,
  }) {
    return AppError(
      type: ErrorType.authentication,
      severity: ErrorSeverity.high,
      message: message,
      technicalDetails: technicalDetails,
      userAction: userAction ?? 'Please sign in again.',
    );
  }

  /// Create a validation error
  factory AppError.validation(
    String message, {
    String? technicalDetails,
    String? userAction,
  }) {
    return AppError(
      type: ErrorType.validation,
      severity: ErrorSeverity.low,
      message: message,
      technicalDetails: technicalDetails,
      userAction: userAction ?? 'Please check your input and try again.',
    );
  }

  /// Create an API error
  factory AppError.api(
    String message, {
    String? technicalDetails,
    String? userAction,
  }) {
    return AppError(
      type: ErrorType.api,
      severity: ErrorSeverity.medium,
      message: message,
      technicalDetails: technicalDetails,
      userAction:
          userAction ??
          'Service temporarily unavailable. Please try again later.',
    );
  }

  /// Create a storage error
  factory AppError.storage(
    String message, {
    String? technicalDetails,
    String? userAction,
  }) {
    return AppError(
      type: ErrorType.storage,
      severity: ErrorSeverity.medium,
      message: message,
      technicalDetails: technicalDetails,
      userAction: userAction ?? 'Storage operation failed. Please try again.',
    );
  }

  @override
  String toString() {
    return 'AppError{type: $type, severity: $severity, message: $message, timestamp: $timestamp}';
  }
}

/// Centralized error handler for the application
class ErrorHandler {
  static ErrorHandler? _instance;
  static ErrorHandler get instance => _instance ??= ErrorHandler._();

  ErrorHandler._();

  final List<AppError> _errorLog = [];

  /// Handle an error and provide appropriate user feedback
  void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    BuildContext? context,
    bool showToUser = true,
  }) {
    final appError = _convertToAppError(error, stackTrace);

    // Log the error
    _logError(appError);

    // Show to user if requested and context is available
    if (showToUser && context != null) {
      _showErrorToUser(context, appError);
    }
  }

  /// Convert any error to AppError
  AppError _convertToAppError(dynamic error, StackTrace? stackTrace) {
    if (error is AppError) {
      return error;
    }

    // Handle common Flutter/Dart exceptions
    if (error is FormatException) {
      return AppError.validation(
        'Invalid data format',
        technicalDetails: error.toString(),
      );
    }

    if (error is TimeoutException) {
      return AppError.network(
        'Operation timed out',
        technicalDetails: error.toString(),
      );
    }

    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException')) {
      return AppError.network(
        'Network connection failed',
        technicalDetails: error.toString(),
      );
    }

    if (error.toString().contains('AuthException') ||
        error.toString().contains('authentication')) {
      return AppError.authentication(
        'Authentication failed',
        technicalDetails: error.toString(),
      );
    }

    if (error.toString().contains('PostgrestException') ||
        error.toString().contains('database')) {
      return AppError.database(
        'Database operation failed',
        technicalDetails: error.toString(),
      );
    }

    // Default to unknown error
    return AppError(
      type: ErrorType.unknown,
      severity: ErrorSeverity.medium,
      message: 'An unexpected error occurred',
      technicalDetails: error.toString(),
      stackTrace: stackTrace,
      userAction:
          'Please try again or contact support if the problem persists.',
    );
  }

  /// Log error for debugging and analytics
  void _logError(AppError error) {
    _errorLog.add(error);

    // Keep only last 100 errors
    if (_errorLog.length > 100) {
      _errorLog.removeAt(0);
    }

    // Debug logging
    debugPrint('=== ERROR LOGGED ===');
    debugPrint('Type: ${error.type}');
    debugPrint('Severity: ${error.severity}');
    debugPrint('Message: ${error.message}');
    if (error.technicalDetails != null) {
      debugPrint('Technical: ${error.technicalDetails}');
    }
    debugPrint('Timestamp: ${error.timestamp}');
    debugPrint('==================');

    // In production, you might want to send this to analytics
    if (kReleaseMode && error.severity == ErrorSeverity.critical) {
      _sendToAnalytics(error);
    }
  }

  /// Show error to user with appropriate UI
  void _showErrorToUser(BuildContext context, AppError error) {
    final color = _getErrorColor(error.severity);
    final icon = _getErrorIcon(error.type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error.message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (error.userAction != null)
                    Text(
                      error.userAction!,
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: Duration(
          seconds: error.severity == ErrorSeverity.critical ? 8 : 4,
        ),
        action:
            error.severity == ErrorSeverity.critical
                ? SnackBarAction(
                  label: 'Details',
                  textColor: Colors.white,
                  onPressed: () => _showErrorDialog(context, error),
                )
                : null,
      ),
    );
  }

  /// Show detailed error dialog for critical errors
  void _showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  _getErrorIcon(error.type),
                  color: _getErrorColor(error.severity),
                ),
                const SizedBox(width: 8),
                const Text('Error Details'),
              ],
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Message: ${error.message}'),
                const SizedBox(height: 8),
                if (error.userAction != null) ...[
                  Text('Suggested Action: ${error.userAction}'),
                  const SizedBox(height: 8),
                ],
                Text('Time: ${error.timestamp.toString()}'),
                if (kDebugMode && error.technicalDetails != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Technical Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(error.technicalDetails!),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  /// Get error color based on severity
  Color _getErrorColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.orange;
      case ErrorSeverity.medium:
        return Colors.red;
      case ErrorSeverity.high:
        return Colors.red.shade700;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
    }
  }

  /// Get error icon based on type
  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.database:
        return Icons.storage;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.api:
        return Icons.api;
      case ErrorType.storage:
        return Icons.folder_off;
      case ErrorType.unknown:
        return Icons.error;
    }
  }

  /// Send error to analytics (placeholder)
  void _sendToAnalytics(AppError error) {
    // Implement analytics reporting here
    debugPrint('Would send to analytics: ${error.message}');
  }

  /// Get recent errors for debugging
  List<AppError> getRecentErrors({int limit = 10}) {
    return _errorLog.reversed.take(limit).toList();
  }

  /// Clear error log
  void clearErrorLog() {
    _errorLog.clear();
  }
}

/// Extension to make error handling easier in widgets
extension ErrorHandling on BuildContext {
  void handleError(dynamic error, {bool showToUser = true}) {
    ErrorHandler.instance.handleError(
      error,
      context: this,
      showToUser: showToUser,
    );
  }
}
