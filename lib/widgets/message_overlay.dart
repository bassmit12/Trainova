import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'dart:async';

enum MessageType { success, error, info, warning }

class MessageOverlay {
  static void show(
    BuildContext context, {
    required String message,
    MessageType type = MessageType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Hide any existing Snackbar or message overlay
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Create overlay entry
    final overlayState = Overlay.of(context);
    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _MessageOverlayWidget(
        message: message,
        type: type,
        duration: duration,
        onTap: onTap,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }

  // Convenience methods for different message types
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: MessageType.success,
      duration: duration,
      onTap: onTap,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: MessageType.error,
      duration: duration,
      onTap: onTap,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: MessageType.info,
      duration: duration,
      onTap: onTap,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: MessageType.warning,
      duration: duration,
      onTap: onTap,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class _MessageOverlayWidget extends StatefulWidget {
  final String message;
  final MessageType type;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageOverlayWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
    this.onTap,
    this.actionLabel,
    this.onAction,
  });

  @override
  _MessageOverlayWidgetState createState() => _MessageOverlayWidgetState();
}

class _MessageOverlayWidgetState extends State<_MessageOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();

    _timer = Timer(widget.duration, () {
      _dismissMessage();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dismissMessage() async {
    if (mounted) {
      await _controller.reverse();
      widget.onDismiss();
    }
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case MessageType.success:
        return AppColors.secondary;
      case MessageType.error:
        return Colors.redAccent;
      case MessageType.warning:
        return Colors.orangeAccent;
      case MessageType.info:
      default:
        return AppColors.primary;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case MessageType.success:
        return Icons.check_circle_outline;
      case MessageType.error:
        return Icons.error_outline;
      case MessageType.warning:
        return Icons.warning_amber_outlined;
      case MessageType.info:
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Positioned(
      bottom: 16.0 + bottomPadding,
      left: 16.0,
      right: 16.0,
      child: SafeArea(
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(_animation),
          child: FadeTransition(
            opacity: _animation,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap != null
                    ? () {
                        widget.onTap!();
                        _dismissMessage();
                      }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Icon(
                              _getIcon(),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Text(
                                widget.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          if (widget.actionLabel != null &&
                              widget.onAction != null)
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: TextButton(
                                onPressed: () {
                                  widget.onAction!();
                                  _dismissMessage();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  widget.actionLabel!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 20,
                              ),
                              onPressed: _dismissMessage,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
