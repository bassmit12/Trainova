import 'package:flutter/material.dart';

/// Loading state types for different operations
enum LoadingType { initial, refresh, loadMore, save, delete, upload, sync }

/// Loading state with progress tracking
class LoadingState {
  final bool isLoading;
  final LoadingType type;
  final String? message;
  final double? progress; // 0.0 to 1.0
  final DateTime startTime;

  LoadingState._({
    required this.isLoading,
    required this.type,
    this.message,
    this.progress,
    required this.startTime,
  });

  factory LoadingState.idle() {
    return LoadingState._(
      isLoading: false,
      type: LoadingType.initial,
      startTime: DateTime.now(),
    );
  }

  factory LoadingState.loading(
    LoadingType type, {
    String? message,
    double? progress,
  }) {
    return LoadingState._(
      isLoading: true,
      type: type,
      message: message,
      progress: progress,
      startTime: DateTime.now(),
    );
  }

  LoadingState copyWith({
    bool? isLoading,
    LoadingType? type,
    String? message,
    double? progress,
  }) {
    return LoadingState._(
      isLoading: isLoading ?? this.isLoading,
      type: type ?? this.type,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      startTime: startTime,
    );
  }

  Duration get duration => DateTime.now().difference(startTime);
}

/// Loading state manager for consistent UI feedback
class LoadingStateManager extends ChangeNotifier {
  final Map<String, LoadingState> _loadingStates = {};

  /// Get loading state for a specific operation
  LoadingState getLoadingState(String operationId) {
    return _loadingStates[operationId] ?? LoadingState.idle();
  }

  /// Check if any operation is loading
  bool get hasAnyLoading =>
      _loadingStates.values.any((state) => state.isLoading);

  /// Check if a specific operation is loading
  bool isLoading(String operationId) {
    return _loadingStates[operationId]?.isLoading ?? false;
  }

  /// Start loading for an operation
  void startLoading(String operationId, LoadingType type, {String? message}) {
    _loadingStates[operationId] = LoadingState.loading(type, message: message);
    notifyListeners();
  }

  /// Update loading progress
  void updateProgress(String operationId, double progress, {String? message}) {
    final currentState = _loadingStates[operationId];
    if (currentState != null && currentState.isLoading) {
      _loadingStates[operationId] = currentState.copyWith(
        progress: progress,
        message: message,
      );
      notifyListeners();
    }
  }

  /// Stop loading for an operation
  void stopLoading(String operationId) {
    _loadingStates[operationId] = LoadingState.idle();
    notifyListeners();
  }

  /// Clear all loading states
  void clearAll() {
    _loadingStates.clear();
    notifyListeners();
  }

  /// Get all active loading operations
  Map<String, LoadingState> get activeOperations {
    return Map.fromEntries(
      _loadingStates.entries.where((entry) => entry.value.isLoading),
    );
  }
}

/// Widget that shows loading UI based on loading state
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final LoadingState loadingState;
  final bool showProgress;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.loadingState,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (loadingState.isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showProgress && loadingState.progress != null)
                        CircularProgressIndicator(value: loadingState.progress)
                      else
                        const CircularProgressIndicator(),
                      if (loadingState.message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          loadingState.message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                      if (showProgress && loadingState.progress != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${(loadingState.progress! * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Mixin for widgets that need loading state management
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  final LoadingStateManager _loadingManager = LoadingStateManager();

  LoadingStateManager get loadingManager => _loadingManager;

  /// Execute an operation with loading state management
  Future<R> executeWithLoading<R>(
    String operationId,
    Future<R> Function() operation, {
    LoadingType type = LoadingType.initial,
    String? loadingMessage,
    void Function(String error)? onError,
  }) async {
    try {
      _loadingManager.startLoading(operationId, type, message: loadingMessage);
      final result = await operation();
      return result;
    } catch (error) {
      onError?.call(error.toString());
      rethrow;
    } finally {
      _loadingManager.stopLoading(operationId);
    }
  }

  /// Execute an operation with progress tracking
  Future<R> executeWithProgress<R>(
    String operationId,
    Future<R> Function(void Function(double, String?) updateProgress)
    operation, {
    LoadingType type = LoadingType.initial,
    String? loadingMessage,
    void Function(String error)? onError,
  }) async {
    try {
      _loadingManager.startLoading(operationId, type, message: loadingMessage);

      void updateProgress(double progress, String? message) {
        _loadingManager.updateProgress(operationId, progress, message: message);
      }

      final result = await operation(updateProgress);
      return result;
    } catch (error) {
      onError?.call(error.toString());
      rethrow;
    } finally {
      _loadingManager.stopLoading(operationId);
    }
  }

  @override
  void dispose() {
    _loadingManager.dispose();
    super.dispose();
  }
}

/// Smart loading button that handles different loading states
class LoadingElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final String? loadingText;
  final LoadingType loadingType;

  const LoadingElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.loadingText,
    this.loadingType = LoadingType.save,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child:
          isLoading
              ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  if (loadingText != null) ...[
                    const SizedBox(width: 8),
                    Text(loadingText!),
                  ],
                ],
              )
              : child,
    );
  }
}

/// Loading indicator for lists
class ListLoadingIndicator extends StatelessWidget {
  final LoadingType type;
  final String? message;

  const ListLoadingIndicator({
    super.key,
    this.type = LoadingType.loadMore,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    String defaultMessage;
    switch (type) {
      case LoadingType.initial:
        defaultMessage = 'Loading...';
        break;
      case LoadingType.refresh:
        defaultMessage = 'Refreshing...';
        break;
      case LoadingType.loadMore:
        defaultMessage = 'Loading more...';
        break;
      default:
        defaultMessage = 'Loading...';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            message ?? defaultMessage,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
