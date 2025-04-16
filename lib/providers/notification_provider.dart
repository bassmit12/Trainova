import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  Timer? _refreshTimer;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  NotificationProvider() {
    // Initialize by loading notifications
    refreshNotifications();

    // Set up periodic refresh every 2 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      refreshNotifications();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Refresh notifications and update unread count
  Future<void> refreshNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load notifications
      _notifications = await AppNotification.fetchUserNotifications();

      // Update unread count
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint('Error refreshing notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || _notifications[index].isRead) return;

    try {
      final notification = _notifications[index];
      final updatedNotification = notification.copyWith(isRead: true);
      final success = await updatedNotification.markAsRead();

      if (success) {
        _notifications[index] = updatedNotification;
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_unreadCount == 0) return;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await AppNotification.markAllAsRead();
      if (success) {
        _notifications =
            _notifications.map((n) => n.copyWith(isRead: true)).toList();
        _unreadCount = 0;
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a local notification (for demonstration purposes)
  /// In a real app, notifications would usually come from the backend or push notifications
  Future<void> addLocalNotification(AppNotification notification) async {
    try {
      _notifications.insert(0, notification);
      if (!notification.isRead) {
        _unreadCount++;
      }
      notifyListeners();

      // In a real app, you might save this to the database:
      // await saveNotificationToDatabase(notification);
    } catch (e) {
      debugPrint('Error adding local notification: $e');
    }
  }
}
