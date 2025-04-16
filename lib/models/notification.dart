import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // workout_reminder, achievement, system, etc.
  final bool isRead;
  final Map<String, dynamic>? additionalData; // For notification-specific data

  AppNotification({
    String? id,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.additionalData,
  }) : id = id ?? const Uuid().v4();

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      message: map['message'],
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'],
      isRead: map['is_read'] ?? false,
      additionalData: map['additional_data'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'is_read': isRead,
      'additional_data': additionalData,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    DateTime? timestamp,
    String? type,
    bool? isRead,
    Map<String, dynamic>? additionalData,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Get all notifications for the current user
  static Future<List<AppNotification>> fetchUserNotifications() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('No logged in user found.');
        return [];
      }

      final response = await supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      return response
          .map<AppNotification>((data) => AppNotification.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  // Mark a notification as read
  Future<bool> markAsRead() async {
    try {
      if (isRead) return true; // Already read

      final supabase = Supabase.instance.client;

      await supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', id);

      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read for the current user
  static Future<bool> markAllAsRead() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        return false;
      }

      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      return true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Get unread notification count for the current user
  static Future<int> getUnreadCount() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        return 0;
      }

      // Query unread notifications for the current user
      final response = await supabase
          .from('notifications')
          .select('id') // Just select ID to minimize data transfer
          .eq('user_id', userId)
          .eq('is_read', false);

      // Count the number of returned items
      return response.length;
    } catch (e) {
      debugPrint('Error getting unread notification count: $e');
      return 0;
    }
  }

  // Get notification icon based on type
  IconData getIcon() {
    switch (type) {
      case 'workout_reminder':
        return Icons.fitness_center;
      case 'achievement':
        return Icons.emoji_events;
      case 'system':
        return Icons.notifications_active;
      default:
        return Icons.notifications;
    }
  }

  // Get notification color based on type
  Color getColor(BuildContext context) {
    switch (type) {
      case 'workout_reminder':
        return Colors.blue;
      case 'achievement':
        return Colors.amber;
      case 'system':
        return Theme.of(context).primaryColor;
      default:
        return Colors.grey;
    }
  }

  // Helper method to format timestamp relative to now
  String getFormattedTimestamp() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
