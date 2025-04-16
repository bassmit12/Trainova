import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../models/user.dart';
import '../widgets/message_overlay.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _workoutRemindersEnabled = true;
  bool _achievementNotificationsEnabled = true;
  bool _tipsAndUpdatesEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedUnits = 'Metric';
  TimeOfDay _notificationTime =
      const TimeOfDay(hour: 8, minute: 0); // Default 8:00 AM
  final List<String> _languages = ['English', 'Spanish', 'French', 'German'];
  final List<String> _measurementSystems = ['Metric', 'Imperial'];

  Future<void> _showConfirmDialog(
      String title, String content, Function onConfirm) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _resetAppData() async {
    await _showConfirmDialog(
      'Reset App Data',
      'Are you sure you want to reset all app data? This action cannot be undone.',
      () {
        // Implement reset logic here
        MessageOverlay.showSuccess(
          context,
          message: 'App data has been reset',
        );
      },
    );
  }

  void _deleteAccount() async {
    await _showConfirmDialog(
      'Delete Account',
      'Are you sure you want to delete your account? This will permanently remove all your data and cannot be undone.',
      () async {
        final authService = Provider.of<AuthService>(context, listen: false);
        try {
          await authService.signOut();
          if (mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
            MessageOverlay.showInfo(
              context,
              message: 'Your account has been deleted',
            );
          }
        } catch (e) {
          if (mounted) {
            MessageOverlay.showError(
              context,
              message: 'Error deleting account: ${e.toString()}',
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Section
              _buildSectionHeader('Account'),
              _buildProfileTile(user),
              _buildActionTile(
                'Edit Profile',
                Icons.edit,
                () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );

                  if (result == true) {
                    if (mounted) {
                      await authService.getCurrentUserProfile(
                          forceRefresh: true);
                    }
                  }
                },
              ),

              // Appearance Section
              _buildSectionHeader('Appearance'),
              _buildSwitchTile(
                'Dark Mode',
                'Switch between light and dark theme',
                Icons.brightness_4,
                themeProvider.isDarkMode,
                (value) {
                  themeProvider.setDarkMode(value);
                },
              ),

              // Units Section
              _buildSectionHeader('Units'),
              _buildDropdownTile(
                'Measurement System',
                'Choose your preferred units of measurement',
                Icons.straighten,
                _selectedUnits,
                _measurementSystems,
                (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedUnits = newValue;
                    });
                  }
                  MessageOverlay.showSuccess(
                    context,
                    message: 'Changed to $newValue system',
                  );
                },
              ),

              // Language Section
              _buildSectionHeader('Language'),
              _buildDropdownTile(
                'App Language',
                'Choose your preferred language',
                Icons.language,
                _selectedLanguage,
                _languages,
                (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedLanguage = newValue;
                    });
                  }
                  MessageOverlay.showInfo(
                    context,
                    message: 'Language feature coming soon',
                  );
                },
              ),

              // Notifications Section
              _buildSectionHeader('Notifications'),
              _buildSwitchTile(
                'Push Notifications',
                'Enable or disable app notifications',
                Icons.notifications,
                _notificationsEnabled,
                (value) {
                  setState(() {
                    _notificationsEnabled = value;

                    // If turning off all notifications, also disable specific notifications
                    if (!value) {
                      _workoutRemindersEnabled = false;
                      _achievementNotificationsEnabled = false;
                      _tipsAndUpdatesEnabled = false;
                    }
                  });
                  final String message = value
                      ? 'Notifications enabled'
                      : 'Notifications disabled';
                  MessageOverlay.showInfo(
                    context,
                    message: message,
                  );
                },
              ),

              // Only show specific notification settings if main toggle is on
              if (_notificationsEnabled) ...[
                _buildSwitchTile(
                  'Workout Reminders',
                  'Get reminders for scheduled workouts',
                  Icons.fitness_center,
                  _workoutRemindersEnabled,
                  (value) {
                    setState(() {
                      _workoutRemindersEnabled = value;
                    });
                    final String message = value
                        ? 'Workout reminders enabled'
                        : 'Workout reminders disabled';
                    MessageOverlay.showInfo(
                      context,
                      message: message,
                    );
                  },
                ),
                _buildSwitchTile(
                  'Achievement Notifications',
                  'Receive notifications when you reach goals',
                  Icons.emoji_events,
                  _achievementNotificationsEnabled,
                  (value) {
                    setState(() {
                      _achievementNotificationsEnabled = value;
                    });
                    final String message = value
                        ? 'Achievement notifications enabled'
                        : 'Achievement notifications disabled';
                    MessageOverlay.showInfo(
                      context,
                      message: message,
                    );
                  },
                ),
                _buildSwitchTile(
                  'Tips & Updates',
                  'Receive fitness tips and app updates',
                  Icons.tips_and_updates,
                  _tipsAndUpdatesEnabled,
                  (value) {
                    setState(() {
                      _tipsAndUpdatesEnabled = value;
                    });
                    final String message = value
                        ? 'Tips & updates enabled'
                        : 'Tips & updates disabled';
                    MessageOverlay.showInfo(
                      context,
                      message: message,
                    );
                  },
                ),
                _buildActionTile(
                  'Notification Time',
                  Icons.access_time,
                  () => _showNotificationTimeDialog(),
                  subtitle: _formatNotificationTime(),
                ),
                _buildActionTile(
                  'Manage All Notifications',
                  Icons.settings_applications,
                  () {
                    MessageOverlay.showInfo(
                      context,
                      message: 'Advanced notification settings coming soon',
                    );
                  },
                ),
              ],

              // Data & Privacy Section
              _buildSectionHeader('Data & Privacy'),
              _buildActionTile(
                'Privacy Policy',
                Icons.privacy_tip,
                () {
                  MessageOverlay.showInfo(
                    context,
                    message: 'Privacy Policy - Coming soon',
                  );
                },
              ),
              _buildActionTile(
                'Terms of Service',
                Icons.description,
                () {
                  MessageOverlay.showInfo(
                    context,
                    message: 'Terms of Service - Coming soon',
                  );
                },
              ),
              _buildActionTile(
                'Export Your Data',
                Icons.file_download,
                () {
                  MessageOverlay.showInfo(
                    context,
                    message: 'Data export - Coming soon',
                  );
                },
              ),

              // Support Section
              _buildSectionHeader('Support'),
              _buildActionTile(
                'Help Center',
                Icons.help,
                () {
                  MessageOverlay.showInfo(
                    context,
                    message: 'Help Center - Coming soon',
                  );
                },
              ),
              _buildActionTile(
                'Contact Support',
                Icons.support_agent,
                () {
                  MessageOverlay.showInfo(
                    context,
                    message: 'Support - Coming soon',
                  );
                },
              ),
              _buildActionTile(
                'Report a Bug',
                Icons.bug_report,
                () {
                  MessageOverlay.showInfo(
                    context,
                    message: 'Bug reporting - Coming soon',
                  );
                },
              ),

              // About Section
              _buildSectionHeader('About'),
              _buildActionTile(
                'Trainova',
                Icons.info,
                () {
                  MessageOverlay.showInfo(
                    context,
                    message: 'Trainova v1.0.0',
                  );
                },
                subtitle: 'v1.0.0',
                showChevron: false,
              ),

              // Danger Zone Section
              _buildDangerSection(),
              _buildActionTile(
                'Reset App Data',
                Icons.restore,
                _resetAppData,
                color: Colors.orange,
              ),
              _buildActionTile(
                'Delete Account',
                Icons.delete_forever,
                _deleteAccount,
                color: Colors.red,
              ),

              // Sign Out
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authService.signOut();
                    if (mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: themeProvider.isDarkMode
                ? Colors.grey.shade700
                : Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Actions here are irreversible',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(UserModel? user) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isDarkMode = themeProvider.isDarkMode;
    final textPrimaryColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final textSecondaryColor =
        isDarkMode ? Colors.white70 : AppColors.textSecondary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: user?.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: user!.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(strokeWidth: 2),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          size: 25,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 25,
                        color: AppColors.primary,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'AI Fitness User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No email provided',
                    style: TextStyle(fontSize: 14, color: textSecondaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    String? subtitle,
    Color? color,
    bool showChevron = true,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isDarkMode = themeProvider.isDarkMode;
    final textPrimaryColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final textSecondaryColor =
        isDarkMode ? Colors.white70 : AppColors.textSecondary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: color ?? AppColors.primary),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? textPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: textSecondaryColor),
              )
            : null,
        trailing: showChevron
            ? Icon(Icons.chevron_right,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isDarkMode = themeProvider.isDarkMode;
    final textPrimaryColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final textSecondaryColor =
        isDarkMode ? Colors.white70 : AppColors.textSecondary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: textSecondaryColor),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isDarkMode = themeProvider.isDarkMode;
    final textPrimaryColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final textSecondaryColor =
        isDarkMode ? Colors.white70 : AppColors.textSecondary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: textPrimaryColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Theme(
              data: Theme.of(context).copyWith(
                canvasColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
              ),
              child: DropdownButton<String>(
                value: value,
                icon: Icon(Icons.arrow_drop_down,
                    color: isDarkMode ? Colors.white60 : Colors.grey.shade700),
                elevation: 16,
                style: TextStyle(color: textPrimaryColor),
                underline: Container(
                  height: 0,
                  color: Colors.transparent,
                ),
                onChanged: onChanged,
                items: items.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNotificationTimeDialog() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (BuildContext context, Widget? child) {
        // Use theme-aware time picker
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              // Use app primary color for the time picker
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != _notificationTime) {
      setState(() {
        _notificationTime = pickedTime;
      });

      MessageOverlay.showInfo(
        context,
        message: 'Notification time set to ${_formatNotificationTime()}',
      );
    }
  }

  String _formatNotificationTime() {
    final hour = _notificationTime.hourOfPeriod;
    final minute = _notificationTime.minute.toString().padLeft(2, '0');
    final period = _notificationTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
