import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add import for SharedPreferences
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../models/user.dart';
import '../models/workout.dart'; // Add import for Workout model
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'workout_history_screen.dart';
import 'goals_screen.dart'; // Add import for GoalsScreen
import '../widgets/message_overlay.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isAdminMode = false; // Add admin mode state
  bool _isLoadingStats = true; // Add loading state for stats
  Map<String, dynamic> _workoutStats = {
    'workoutCount': 0,
    'caloriesBurned': 0,
    'hoursSpent': 0.0,
    'timeRange': 30
  }; // Add workout stats

  @override
  void initState() {
    super.initState();
    // Refresh user data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUserData();
      _loadAdminMode(); // Load admin mode setting
      _loadWorkoutStats(); // Load workout statistics
    });
  }

  // Load admin mode setting from local storage
  Future<void> _loadAdminMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAdminMode = prefs.getBool('admin_mode') ?? false;
    });
  }

  // Save admin mode setting to local storage
  Future<void> _saveAdminMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_mode', value);
    setState(() {
      _isAdminMode = value;
    });
  }

  // Force refresh user data from Supabase
  Future<void> _refreshUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.getCurrentUserProfile();
  }

  // Load workout statistics
  Future<void> _loadWorkoutStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await Workout.calculateWorkoutStatistics();
      if (mounted) {
        setState(() {
          _workoutStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
      debugPrint('Error loading workout stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authService.currentUser;

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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: textPrimaryColor)),
        centerTitle: true,
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textPrimaryColor),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: textPrimaryColor),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              _buildProfileHeader(
                  context, user, textPrimaryColor, textSecondaryColor),
              const SizedBox(height: 32),
              _buildStatsSection(context, cardBackgroundColor, textPrimaryColor,
                  textSecondaryColor),
              const SizedBox(height: 24),
              _buildActionItems(context, authService, cardBackgroundColor,
                  textPrimaryColor, textSecondaryColor),
              const SizedBox(height: 24),
              _buildAdminToggle(context, textPrimaryColor, textSecondaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel? user,
      Color textPrimaryColor, Color textSecondaryColor) {
    return Column(
      children: [
        // Profile picture
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: user?.avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: user!.avatarUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.primary,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        // User name
        Text(
          user?.name ?? 'AI Fitness User',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        // User email
        Text(
          user?.email ?? 'No email provided',
          style: TextStyle(
            fontSize: 16,
            color: textSecondaryColor,
          ),
        ),
        const SizedBox(height: 16),
        // Edit profile button
        OutlinedButton.icon(
          onPressed: () async {
            // Navigate to EditProfileScreen and wait for result
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            );

            // If returned with true (successful update), refresh data
            if (result == true) {
              _refreshUserData();
            }
          },
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Edit Profile'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, Color cardBackgroundColor,
      Color textPrimaryColor, Color textSecondaryColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final shadowColor = themeProvider.isDarkMode
        ? Colors.black.withOpacity(0.2)
        : Colors.black.withOpacity(0.05);

    // Format the workout stats values
    String workoutsValue =
        _isLoadingStats ? '...' : '${_workoutStats['workoutCount']}';

    String caloriesValue = _isLoadingStats
        ? '...'
        : NumberFormat('#,###').format(_workoutStats['caloriesBurned']);

    String hoursValue = _isLoadingStats
        ? '...'
        : _workoutStats['hoursSpent'].toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Your 30-Day Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimaryColor,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(context, workoutsValue, 'Workouts',
                    textPrimaryColor, textSecondaryColor),
                _buildVerticalDivider(themeProvider.isDarkMode),
                _buildStatItem(context, caloriesValue, 'Calories',
                    textPrimaryColor, textSecondaryColor),
                _buildVerticalDivider(themeProvider.isDarkMode),
                _buildStatItem(context, hoursValue, 'Hours', textPrimaryColor,
                    textSecondaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label,
      Color textPrimaryColor, Color textSecondaryColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(bool isDarkMode) {
    return Container(
        height: 40,
        width: 1,
        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300);
  }

  Widget _buildActionItems(
    BuildContext context,
    AuthService authService,
    Color cardBackgroundColor,
    Color textPrimaryColor,
    Color textSecondaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildActionItem(
            context,
            'Your Goals',
            Icons.flag,
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GoalsScreen(),
                ),
              );
            },
            cardBackgroundColor: cardBackgroundColor,
            textPrimaryColor: textPrimaryColor,
            textSecondaryColor: textSecondaryColor,
          ),
          _buildActionItem(
            context,
            'Workout History',
            Icons.history,
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WorkoutHistoryScreen(),
                ),
              );
            },
            cardBackgroundColor: cardBackgroundColor,
            textPrimaryColor: textPrimaryColor,
            textSecondaryColor: textSecondaryColor,
          ),
          _buildActionItem(
            context,
            'Help & Support',
            Icons.help,
            () {
              MessageOverlay.showInfo(
                context,
                message: 'Help & Support - Coming soon',
              );
            },
            cardBackgroundColor: cardBackgroundColor,
            textPrimaryColor: textPrimaryColor,
            textSecondaryColor: textSecondaryColor,
          ),
          _buildActionItem(
            context,
            'Sign Out',
            Icons.logout,
            () async {
              await authService.signOut();
              // Navigate explicitly to the root route for cleaner transition
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            color: Colors.red,
            cardBackgroundColor: cardBackgroundColor,
            textPrimaryColor: textPrimaryColor,
            textSecondaryColor: textSecondaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
    required Color cardBackgroundColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final chevronColor =
        themeProvider.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: cardBackgroundColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: color ?? AppColors.primary, size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color ?? textPrimaryColor,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: chevronColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminToggle(
      BuildContext context, Color textPrimaryColor, Color textSecondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Admin Mode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textPrimaryColor,
            ),
          ),
          Switch(
            value: _isAdminMode,
            onChanged: (value) {
              _saveAdminMode(value);
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
