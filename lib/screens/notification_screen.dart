import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'settings_screen.dart'; // Add import for SettingsScreen

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterType = 'All';
  final List<String> _filterOptions = [
    'All',
    'Unread',
    'Workout',
    'Achievement',
    'System'
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifications = await AppNotification.fetchUserNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load notifications: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await AppNotification.markAllAsRead();
      if (success) {
        await _loadNotifications();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    try {
      final updatedNotification = notification.copyWith(isRead: true);
      final success = await updatedNotification.markAsRead();

      if (success && mounted) {
        setState(() {
          // Update the notification in the list
          final index =
              _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = updatedNotification;
          }
        });
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  List<AppNotification> _getFilteredNotifications() {
    if (_filterType == 'All') {
      return _notifications;
    } else if (_filterType == 'Unread') {
      return _notifications
          .where((notification) => !notification.isRead)
          .toList();
    } else {
      // Filter by notification type (lowercase to match the model's type)
      final type = _filterType.toLowerCase();
      return _notifications
          .where(
              (notification) => notification.type.toLowerCase().contains(type))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = themeProvider.isDarkMode
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final textPrimaryColor = themeProvider.isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondaryColor = themeProvider.isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final cardBackgroundColor = themeProvider.isDarkMode
        ? AppColors.darkCardBackground
        : AppColors.lightCardBackground;

    final hasUnread =
        _notifications.any((notification) => !notification.isRead);
    final filteredNotifications = _getFilteredNotifications();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: textPrimaryColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        actions: [
          if (hasUnread)
            IconButton(
              icon: Icon(Icons.done_all, color: textPrimaryColor),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textPrimaryColor),
            onSelected: (value) {
              if (value == 'refresh') {
                _loadNotifications();
              } else if (value == 'settings') {
                // Navigate to settings screen
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                )
                    .then((_) {
                  // Refresh notifications when returning from settings
                  _loadNotifications();
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Notification Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: textPrimaryColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: _filterOptions.map((option) {
                          final isSelected = _filterType == option;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(option),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _filterType = option;
                                });
                              },
                              backgroundColor: cardBackgroundColor,
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              checkmarkColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : textPrimaryColor,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Notifications or empty state
                    Expanded(
                      child: filteredNotifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off,
                                    size: 64,
                                    color: textSecondaryColor.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No notifications found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _filterType == 'All'
                                        ? 'You have no notifications at this time'
                                        : 'No $_filterType notifications found',
                                    style: TextStyle(
                                      color: textSecondaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _loadNotifications,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Refresh'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadNotifications,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                itemCount: filteredNotifications.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                  height: 1,
                                  indent: 70,
                                ),
                                itemBuilder: (context, index) {
                                  final notification =
                                      filteredNotifications[index];
                                  return _buildNotificationTile(
                                    notification,
                                    cardBackgroundColor,
                                    textPrimaryColor,
                                    textSecondaryColor,
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildNotificationTile(
    AppNotification notification,
    Color cardBackgroundColor,
    Color textPrimaryColor,
    Color textSecondaryColor,
  ) {
    final bool isToday =
        DateTime.now().difference(notification.timestamp).inDays < 1;

    // Format the date according to whether it's today or not
    final String formattedDate = isToday
        ? DateFormat('h:mm a').format(notification.timestamp)
        : DateFormat('MMM d, y').format(notification.timestamp);

    return InkWell(
      onTap: () => _markAsRead(notification),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              notification.isRead ? null : AppColors.primary.withOpacity(0.1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: notification.getColor(context).withOpacity(0.2),
              ),
              child: Icon(
                notification.getIcon(),
                color: notification.getColor(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: textPrimaryColor,
                          fontSize: 16,
                        ),
                      ),
                      // Timestamp
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  // If there's additional action button based on notification type
                  if (notification.type == 'workout_reminder')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              // Handle workout view action
                              _markAsRead(notification);
                              // Navigate to workout details
                              if (notification.additionalData?['workout_id'] !=
                                  null) {
                                // You could navigate to workout details here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Navigating to workout...')),
                                );
                              }
                            },
                            child: const Text('View Workout'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
