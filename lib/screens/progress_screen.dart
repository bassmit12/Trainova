import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';
import '../models/workout_history.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Weekly', 'Monthly', 'Yearly'];

  // Workout data
  List<WorkoutHistory> _workoutHistory = [];
  bool _isLoading = true;
  String? _errorMessage;
  UserModel? _user;

  // Weekly activity data
  List<Map<String, dynamic>> _weeklyWorkouts = [];

  // Goals data
  Map<String, dynamic> _goals = {
    'weeklyWorkouts': {'current': 0, 'target': 5},
    'weeklyMinutes': {'current': 0, 'target': 300},
    'monthlyCalories': {'current': 0, 'target': 10000},
  };

  // Recent workouts
  List<Map<String, dynamic>> _recentWorkouts = [];

  // Body stats
  Map<String, dynamic> _bodyStats = {
    'weight': {'value': '0', 'unit': 'kg', 'change': 'No data'},
    'bodyFat': {'value': '0', 'unit': '%', 'change': 'No data'},
    'muscleMass': {'value': '0', 'unit': '%', 'change': 'No data'},
    'bmi': {'value': '0', 'unit': '', 'change': 'No data'}
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _loadUserProfile();
      await _loadWorkoutHistory();
      _processWorkoutData();
      _calculateGoals();
      _prepareBodyStats();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.getCurrentUserProfile();
      setState(() {
        _user = authService.currentUser;
      });
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      // Continue even if user profile fails to load
    }
  }

  Future<void> _loadWorkoutHistory() async {
    try {
      final history = await WorkoutHistory.fetchUserWorkoutHistory();
      setState(() {
        _workoutHistory = history;
      });
    } catch (e) {
      debugPrint('Error loading workout history: $e');
      // Return empty list if fails
      setState(() {
        _workoutHistory = [];
      });
    }
  }

  void _processWorkoutData() {
    // Process workout history into weekly data
    _prepareWeeklyActivityData();

    // Prepare recent workouts data
    _prepareRecentWorkouts();
  }

  void _prepareWeeklyActivityData() {
    // Initialize the weekly data structure with days of the week
    final now = DateTime.now();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Get start of current week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Initialize weekly workout data with zeros
    _weeklyWorkouts = List.generate(7, (index) {
      final day = startOfWeek.add(Duration(days: index));
      return {
        'day': dayNames[index],
        'date': day,
        'minutes': 0,
        'calories': 0,
      };
    });

    // Fill in actual workout data
    for (var workout in _workoutHistory) {
      // Only consider this week's workouts
      if (workout.completedAt.isAfter(startOfWeek) &&
          workout.completedAt
              .isBefore(startOfWeek.add(const Duration(days: 7)))) {
        // Get day of week (0 = Monday, 6 = Sunday)
        final dayOfWeek = workout.completedAt.weekday - 1;

        // Add workout data to the appropriate day
        _weeklyWorkouts[dayOfWeek]['minutes'] += workout.durationMinutes;
        _weeklyWorkouts[dayOfWeek]['calories'] += workout.caloriesBurned;
      }
    }
  }

  void _prepareRecentWorkouts() {
    _recentWorkouts = [];

    // Sort by completion date (most recent first)
    final sortedWorkouts = List.from(_workoutHistory);
    sortedWorkouts.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    // Take the 4 most recent workouts
    final recentWorkouts = sortedWorkouts.take(4).toList();

    // Format the workout data for display
    for (var workout in recentWorkouts) {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // Format the date nicely
      String dateText;
      if (workout.completedAt.year == today.year &&
          workout.completedAt.month == today.month &&
          workout.completedAt.day == today.day) {
        dateText = 'Today';
      } else if (workout.completedAt.year == yesterday.year &&
          workout.completedAt.month == yesterday.month &&
          workout.completedAt.day == yesterday.day) {
        dateText = 'Yesterday';
      } else {
        // Calculate days ago if within a week
        final daysAgo = today.difference(workout.completedAt).inDays;
        if (daysAgo < 7) {
          dateText = '$daysAgo days ago';
        } else {
          // Format date as MMM dd (e.g., Apr 12)
          dateText = DateFormat('MMM dd').format(workout.completedAt);
        }
      }

      _recentWorkouts.add({
        'name': workout.workoutName,
        'date': dateText,
        'time': '${workout.durationMinutes} min',
        'calories': workout.caloriesBurned,
        'completed': true, // All historical workouts are completed
      });
    }

    // If we have less than 4 workouts, fill with some placeholder upcoming workouts
    if (_recentWorkouts.length < 4) {
      final placeholder = {
        'name': 'Scheduled Workout',
        'date': 'Upcoming',
        'time': '30 min',
        'calories': 250,
        'completed': false,
      };

      while (_recentWorkouts.length < 4) {
        _recentWorkouts.add(placeholder);
      }
    }
  }

  void _calculateGoals() {
    // Get user's target workouts per week (default to 5 if not set)
    final targetWorkoutsPerWeek = _user?.workoutsPerWeek ?? 5;

    // Count workouts in the current week
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    int weeklyWorkoutCount = 0;
    int weeklyMinutes = 0;
    int monthlyCalories = 0;

    // Calculate weekly workouts and minutes
    for (var workout in _workoutHistory) {
      if (workout.completedAt.isAfter(startOfWeek)) {
        weeklyWorkoutCount++;
        weeklyMinutes += workout.durationMinutes;
      }

      // Calculate monthly calories (last 30 days)
      if (workout.completedAt.isAfter(now.subtract(const Duration(days: 30)))) {
        monthlyCalories += workout.caloriesBurned;
      }
    }

    // Update goals based on real data
    _goals = {
      'weeklyWorkouts': {
        'current': weeklyWorkoutCount,
        'target': targetWorkoutsPerWeek,
      },
      'weeklyMinutes': {
        'current': weeklyMinutes,
        'target': 150, // WHO recommended weekly active minutes
      },
      'monthlyCalories': {
        'current': monthlyCalories,
        'target': 10000, // Sample target
      },
    };
  }

  void _prepareBodyStats() {
    // Use real user data when available
    if (_user != null) {
      final weight = _user!.weight ?? 0.0;
      final weightUnit = _user!.weightUnit ?? 'kg';

      // Calculate BMI if both weight and height are available
      String bmiValue = '0';
      String bmiStatus = 'No data';

      if (_user!.weight != null && _user!.height != null) {
        final heightInMeters = _user!.heightUnit == 'cm'
            ? _user!.height! / 100
            : _user!.height! * 0.3048; // Convert feet to meters

        if (heightInMeters > 0) {
          final bmi = _user!.weight! / (heightInMeters * heightInMeters);
          bmiValue = bmi.toStringAsFixed(1);

          // Determine BMI status
          if (bmi < 18.5) {
            bmiStatus = 'Underweight';
          } else if (bmi < 25) {
            bmiStatus = 'Normal range';
          } else if (bmi < 30) {
            bmiStatus = 'Overweight';
          } else {
            bmiStatus = 'Obese';
          }
        }
      }

      // Update body stats with real data
      _bodyStats = {
        'weight': {
          'value': weight.toStringAsFixed(1),
          'unit': weightUnit,
          'change': 'Current weight'
        },
        'bodyFat': {'value': '18.2', 'unit': '%', 'change': 'Tap to track'},
        'muscleMass': {'value': '52.4', 'unit': '%', 'change': 'Tap to track'},
        'bmi': {'value': bmiValue, 'unit': '', 'change': bmiStatus},
      };
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final backgroundColor = themeProvider.isDarkMode
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final cardBackgroundColor = themeProvider.isDarkMode
        ? AppColors.darkCardBackground
        : AppColors.lightCardBackground;
    final textPrimaryColor = themeProvider.isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondaryColor = themeProvider.isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final shadowColor = themeProvider.isDarkMode
        ? Colors.black.withOpacity(0.2)
        : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text('Loading your progress...',
                        style: TextStyle(color: textPrimaryColor)),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: $_errorMessage',
                            style: TextStyle(color: textPrimaryColor)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary),
                          child: const Text('Retry',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.primary,
                    child: CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          floating: true,
                          pinned: true,
                          backgroundColor: backgroundColor,
                          elevation: 0,
                          title: Text(
                            'Progress',
                            style: TextStyle(
                              color: textPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: Icon(
                                Icons.calendar_today,
                                color: textPrimaryColor,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Calendar view coming soon!'),
                                  ),
                                );
                              },
                            ),
                          ],
                          bottom: TabBar(
                            controller: _tabController,
                            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                            indicatorColor: AppColors.primary,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: textSecondaryColor,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildActivityChart(
                                    cardBackgroundColor,
                                    textPrimaryColor,
                                    textSecondaryColor,
                                    shadowColor),
                                const SizedBox(height: 24),
                                _buildGoalProgress(
                                    cardBackgroundColor,
                                    textPrimaryColor,
                                    textSecondaryColor,
                                    shadowColor),
                                const SizedBox(height: 24),
                                _buildWorkoutHistory(
                                    cardBackgroundColor,
                                    textPrimaryColor,
                                    textSecondaryColor,
                                    shadowColor),
                                const SizedBox(height: 24),
                                _buildBodyStats(
                                    cardBackgroundColor,
                                    textPrimaryColor,
                                    textSecondaryColor,
                                    shadowColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildActivityChart(Color cardBackgroundColor, Color textPrimaryColor,
      Color textSecondaryColor, Color shadowColor) {
    // Find the maximum minutes for scaling
    final int maxMinutes = _weeklyWorkouts
        .map((w) => w['minutes'] as int)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          height: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Workout Minutes',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'This Week',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _weeklyWorkouts.map((workout) {
                    // Simple proportion calculation that won't cause layout issues
                    final double barHeight = maxMinutes > 0
                        ? (workout['minutes'] as int) / maxMinutes * 120
                        : 0.0;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: (workout['minutes'] as int) > 0
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          workout['day'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalProgress(Color cardBackgroundColor, Color textPrimaryColor,
      Color textSecondaryColor, Color shadowColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal Progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildGoalCard(
                'Weekly Workouts',
                _goals['weeklyWorkouts']['current'],
                _goals['weeklyWorkouts']['target'],
                Icons.fitness_center,
                cardBackgroundColor,
                textPrimaryColor,
                textSecondaryColor,
                shadowColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildGoalCard(
                'Weekly Minutes',
                _goals['weeklyMinutes']['current'],
                _goals['weeklyMinutes']['target'],
                Icons.timer,
                cardBackgroundColor,
                textPrimaryColor,
                textSecondaryColor,
                shadowColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalCard(
    String title,
    int current,
    int target,
    IconData icon,
    Color cardBackgroundColor,
    Color textPrimaryColor,
    Color textSecondaryColor,
    Color shadowColor,
  ) {
    final double progress = target > 0 ? min(current / target, 1.0) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$current',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
              Text(
                '$target',
                style: TextStyle(fontSize: 16, color: textSecondaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutHistory(
    Color cardBackgroundColor,
    Color textPrimaryColor,
    Color textSecondaryColor,
    Color shadowColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Workouts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ..._recentWorkouts
            .map((workout) => _buildWorkoutItem(workout, cardBackgroundColor,
                textPrimaryColor, textSecondaryColor, shadowColor))
            .toList(),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/workout-history');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text(
              'VIEW ALL WORKOUTS',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutItem(
    Map<String, dynamic> workout,
    Color cardBackgroundColor,
    Color textPrimaryColor,
    Color textSecondaryColor,
    Color shadowColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fitness_center, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${workout['date']} • ${workout['time']} • ${workout['calories']} kcal',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: workout['completed']
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                workout['completed'] ? 'Completed' : 'Scheduled',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: workout['completed'] ? AppColors.primary : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyStats(
    Color cardBackgroundColor,
    Color textPrimaryColor,
    Color textSecondaryColor,
    Color shadowColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Body Measurements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 4),
                  Text('UPDATE'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Weight',
                _bodyStats['weight']['value'],
                _bodyStats['weight']['unit'],
                _bodyStats['weight']['change'],
                cardBackgroundColor,
                textPrimaryColor,
                textSecondaryColor,
                shadowColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Body Fat',
                _bodyStats['bodyFat']['value'],
                _bodyStats['bodyFat']['unit'],
                _bodyStats['bodyFat']['change'],
                cardBackgroundColor,
                textPrimaryColor,
                textSecondaryColor,
                shadowColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Muscle Mass',
                _bodyStats['muscleMass']['value'],
                _bodyStats['muscleMass']['unit'],
                _bodyStats['muscleMass']['change'],
                cardBackgroundColor,
                textPrimaryColor,
                textSecondaryColor,
                shadowColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'BMI',
                _bodyStats['bmi']['value'],
                _bodyStats['bmi']['unit'],
                _bodyStats['bmi']['change'],
                cardBackgroundColor,
                textPrimaryColor,
                textSecondaryColor,
                shadowColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String unit,
    String change,
    Color cardBackgroundColor,
    Color textPrimaryColor,
    Color textSecondaryColor,
    Color shadowColor,
  ) {
    Color changeColor = textSecondaryColor;
    if (change.contains('+')) {
      changeColor = Colors.green;
    } else if (change.contains('-')) {
      changeColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            title,
            style: TextStyle(fontSize: 14, color: textSecondaryColor),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            change,
            style: TextStyle(
              fontSize: 12,
              color: changeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
