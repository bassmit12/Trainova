import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/workout.dart';
import '../models/workout_history.dart';
import '../providers/theme_provider.dart';
import '../widgets/workout_card.dart';
import '../utils/app_colors.dart';
import 'workout_details_screen.dart';
import 'workout_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Workout> _workouts = [];
  bool _isLoading = true;

  // Workout history related variables
  List<WorkoutHistory> _workoutHistory = [];
  bool _isLoadingHistory = true;

  // Workout statistics
  Map<String, dynamic> _workoutStats = {
    'workoutCount': 0,
    'caloriesBurned': 0,
    'hoursSpent': 0.0,
    'timeRange': 30
  };
  bool _isLoadingStats = true;

  // Weekly plan data
  List<Map<String, dynamic>> _weeklyPlan = [];
  Map<String, bool> _weeklyCompletionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    _loadWorkoutHistory();
    _loadWorkoutStats();
  }

  Future<void> _loadWorkouts() async {
    try {
      final workouts = await Workout.fetchWorkouts();
      if (mounted) {
        setState(() {
          _workouts = workouts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWorkoutHistory() async {
    try {
      final history = await WorkoutHistory.fetchUserWorkoutHistory();
      if (mounted) {
        setState(() {
          _workoutHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
      debugPrint('Error loading workout history: $e');
    }
  }

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

  // Helper method to find workout type by ID
  String? _findWorkoutTypeById(String workoutId) {
    for (var workout in _workouts) {
      if (workout.id == workoutId) {
        return workout.type;
      }
    }
    return null;
  }

  // Helper to find a workout by type
  Workout? _findWorkoutByType(String type) {
    // Shuffle the workouts to get variety in recommendations
    final shuffled = List<Workout>.from(_workouts)..shuffle();
    for (var workout in shuffled) {
      if (workout.type.toLowerCase() == type.toLowerCase()) {
        return workout;
      }
    }
    // If no matching type is found, return any workout
    return _workouts.isNotEmpty ? _workouts.first : null;
  }

  // Calculate current workout streak
  int _calculateCurrentStreak() {
    if (_workoutHistory.isEmpty) {
      return 0;
    }

    // Sort history by date, newest first
    final sorted = List<WorkoutHistory>.from(_workoutHistory)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    int streak = 0;
    DateTime? lastDate;

    for (var history in sorted) {
      final workoutDate = DateTime(
        history.completedAt.year,
        history.completedAt.month,
        history.completedAt.day,
      );

      if (lastDate == null) {
        // First workout in the streak
        lastDate = workoutDate;
        streak = 1;
      } else {
        // Check if this workout was on the previous day
        final expectedPrevDay = lastDate.subtract(const Duration(days: 1));

        if (workoutDate.year == expectedPrevDay.year &&
            workoutDate.month == expectedPrevDay.month &&
            workoutDate.day == expectedPrevDay.day) {
          // Workout on consecutive days, increase streak
          streak++;
          lastDate = workoutDate;
        } else if (workoutDate.year == lastDate.year &&
            workoutDate.month == lastDate.month &&
            workoutDate.day == lastDate.day) {
          // Multiple workouts on same day, don't increase streak but update date
          lastDate = workoutDate;
        } else {
          // Streak is broken
          break;
        }
      }
    }

    return streak;
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No workouts found',
                style: TextStyle(fontSize: 18, color: textPrimaryColor)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWorkouts,
              child: const Text('Refresh'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadWorkouts,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: false,
              backgroundColor: backgroundColor,
              elevation: 0,
              title: Row(
                children: [
                  Image.asset(
                    'assets/images/brands/trainova_v3.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.fitness_center,
                        color: AppColors.primary,
                        size: 28),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trainova',
                    style: TextStyle(
                      color: textPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.notifications_none, color: textPrimaryColor),
                  onPressed: () {
                    // TODO: Implement notifications functionality
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User welcome message with Trainova branding
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 24,
                          color: textPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: 'Welcome to ',
                          ),
                          TextSpan(
                            text: 'Trainova',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your personalized fitness journey starts here',
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured Workout',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeaturedWorkout(
                        _workouts.isNotEmpty ? _workouts.first : null, context),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Your Weekly Plan', textPrimaryColor),
                    const SizedBox(height: 12),
                    _buildWeeklyProgress(cardBackgroundColor, backgroundColor,
                        textPrimaryColor, textSecondaryColor),
                    const SizedBox(height: 24),
                    _buildSectionTitle(
                        'Your Workout Statistics', textPrimaryColor),
                    const SizedBox(height: 12),
                    _buildWorkoutStatistics(cardBackgroundColor,
                        textPrimaryColor, textSecondaryColor),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Workouts For You', textPrimaryColor),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recommended Workouts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to workouts tab
                        DefaultTabController.of(context)?.animateTo(1);
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => WorkoutCard(
                  workout: _workouts[index % _workouts.length],
                  onTap: () => _openWorkoutDetails(
                      context, _workouts[index % _workouts.length]),
                ),
                childCount: _workouts.length > 3 ? 3 : _workouts.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  void _openWorkoutDetails(BuildContext context, Workout workout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailsScreen(workout: workout),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textPrimaryColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
    );
  }

  Widget _buildFeaturedWorkout(Workout? workout, BuildContext context) {
    if (workout == null) {
      return const SizedBox.shrink();
    }

    // Handle image path - ensure it's a valid network URL or use local asset properly
    Widget backgroundImage;
    try {
      if (workout.imageUrl.startsWith('http')) {
        backgroundImage = Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(workout.imageUrl),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3),
                BlendMode.darken,
              ),
            ),
          ),
        );
      } else {
        backgroundImage = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
        );
      }
    } catch (e) {
      backgroundImage = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
      );
    }

    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background
            Positioned.fill(child: backgroundImage),

            // Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openWorkoutDetails(context, workout),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Label
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Trainova Original',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Workout name
                      Text(
                        workout.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Workout description - with maximum 1 line
                      Text(
                        workout.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),

                      const Spacer(),

                      // Button
                      ElevatedButton(
                        onPressed: () => _openWorkoutDetails(context, workout),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(100, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Start Now',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress(Color cardBackgroundColor, Color backgroundColor,
      Color textPrimaryColor, Color textSecondaryColor) {
    final shadowColor = Provider.of<ThemeProvider>(context).isDarkMode
        ? Colors.black.withOpacity(0.2)
        : Colors.black.withOpacity(0.05);

    // Create a fixed-size weekly plan visualization
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : _buildWeeklyPlanContent(
              textPrimaryColor, textSecondaryColor, backgroundColor),
    );
  }

  Widget _buildWeeklyPlanContent(
      Color textPrimaryColor, Color textSecondaryColor, Color backgroundColor) {
    final now = DateTime.now();

    // Calculate the start date (Monday) of the current week
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Generate dates for the week (Monday to Sunday)
    final weekDates =
        List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    // Compute the completion status for each day
    final completedDays = _getCompletedDaysInWeek(weekDates);

    // Count completed workouts this week
    final completedCount =
        completedDays.values.where((completed) => completed).length;
    final streak = _calculateCurrentStreak();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weekly progress title
        Text(
          '$completedCount of 7 workouts completed',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),

        // Day indicators row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final date = weekDates[index];
            final dayLetter = _getDayLetterFromWeekday(date.weekday);
            final isToday = _isSameDay(date, now);
            final isCompleted = completedDays[date.weekday] ?? false;

            return _buildDayCell(
              dayLetter,
              isCompleted,
              isToday: isToday,
              backgroundColor: backgroundColor,
              textSecondaryColor: textSecondaryColor,
            );
          }),
        ),

        const SizedBox(height: 16),

        // Today's workout recommendation
        if (_workouts.isNotEmpty)
          _buildTodayWorkoutRecommendation(
              textPrimaryColor, textSecondaryColor),

        const SizedBox(height: 16),

        // Streak info
        Row(
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '$streak day streak',
              style: TextStyle(
                fontSize: 14,
                color: textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Navigate to workout history screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkoutHistoryScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('View All'),
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to convert weekday (1-7) to letter (M-S)
  String _getDayLetterFromWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return 'M';
      case 2:
        return 'T';
      case 3:
        return 'W';
      case 4:
        return 'T';
      case 5:
        return 'F';
      case 6:
        return 'S';
      case 7:
        return 'S';
      default:
        return '';
    }
  }

  // Check if two dates are the same day (ignoring time)
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Find which days in the week have completed workouts
  Map<int, bool> _getCompletedDaysInWeek(List<DateTime> weekDates) {
    final Map<int, bool> completedDays = {};

    // Initialize all days as not completed
    for (int i = 1; i <= 7; i++) {
      completedDays[i] = false;
    }

    for (var history in _workoutHistory) {
      // Check if this workout history falls within the current week
      for (var date in weekDates) {
        if (_isSameDay(history.completedAt, date)) {
          // Mark this day as having a completed workout
          completedDays[date.weekday] = true;
          break;
        }
      }
    }

    return completedDays;
  }

  // Build a recommendation for today (or next workout)
  Widget _buildTodayWorkoutRecommendation(
      Color textPrimaryColor, Color textSecondaryColor) {
    // Find most suitable workout to recommend
    final Workout? workout = _getRecommendedWorkout();

    if (workout == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s recommended workout:',
          style: TextStyle(
            fontSize: 14,
            color: textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _openWorkoutDetails(context, workout),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    _getWorkoutTypeIcon(workout.type),
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textPrimaryColor,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${workout.duration} · ${workout.difficulty}',
                      style: TextStyle(
                        color: textSecondaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: textSecondaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Get a recommended workout based on recent history
  Workout? _getRecommendedWorkout() {
    if (_workouts.isEmpty) {
      return null;
    }

    // Get counts of each workout type completed in the past 2 weeks
    Map<String, int> recentTypeCount = {};

    final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
    final recentWorkouts = _workoutHistory
        .where((history) => history.completedAt.isAfter(twoWeeksAgo))
        .toList();

    for (var history in recentWorkouts) {
      final type = _findWorkoutTypeById(history.workoutId);
      if (type != null) {
        recentTypeCount[type] = (recentTypeCount[type] ?? 0) + 1;
      }
    }

    // Find least frequently used workout type
    List<String> types = ['Strength', 'Cardio', 'HIIT', 'Yoga', 'Recovery'];
    types.shuffle(); // Add some randomness

    // First try types not used at all
    for (var type in types) {
      if (!recentTypeCount.containsKey(type)) {
        final match = _findWorkoutByType(type);
        if (match != null) {
          return match;
        }
      }
    }

    // Otherwise pick the least frequently used
    if (recentTypeCount.isNotEmpty) {
      final sortedEntries = recentTypeCount.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      if (sortedEntries.isNotEmpty) {
        return _findWorkoutByType(sortedEntries.first.key);
      }
    }

    // Fall back to first workout
    return _workouts.first;
  }

  // Build a day cell for the weekly plan display
  Widget _buildDayCell(
    String day,
    bool completed, {
    bool isToday = false,
    required Color backgroundColor,
    required Color textSecondaryColor,
  }) {
    return Column(
      children: [
        // The day circle
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: completed
                ? AppColors.primary
                : isToday
                    ? AppColors.primary.withOpacity(0.2)
                    : backgroundColor,
            shape: BoxShape.circle,
            border: isToday
                ? Border.all(color: AppColors.primary, width: 2)
                : completed
                    ? null
                    : Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
        const SizedBox(height: 6),
        // The day label
        Text(
          day,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? AppColors.primary : textSecondaryColor,
          ),
        ),
      ],
    );
  }

  // Helper function to get icon for workout type
  IconData _getWorkoutTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'strength':
        return Icons.fitness_center;
      case 'cardio':
        return Icons.directions_run;
      case 'hiit':
        return Icons.timer;
      case 'yoga':
        return Icons.self_improvement;
      case 'recovery':
        return Icons.healing;
      default:
        return Icons.sports_gymnastics;
    }
  }

  Widget _buildWorkoutStatistics(Color cardBackgroundColor,
      Color textPrimaryColor, Color textSecondaryColor) {
    final shadowColor = Provider.of<ThemeProvider>(context).isDarkMode
        ? Colors.black.withOpacity(0.2)
        : Colors.black.withOpacity(0.05);

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: _isLoadingStats
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your 30-Day Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      Icons.fitness_center,
                      '${_workoutStats['workoutCount']}',
                      'Workouts',
                      AppColors.primary,
                      textPrimaryColor,
                      textSecondaryColor,
                    ),
                    _buildStatItem(
                      Icons.local_fire_department,
                      '${NumberFormat("#,###").format(_workoutStats['caloriesBurned'])}',
                      'Calories',
                      Colors.orange,
                      textPrimaryColor,
                      textSecondaryColor,
                    ),
                    _buildStatItem(
                      Icons.timer,
                      '${_workoutStats['hoursSpent'].toStringAsFixed(1)}',
                      'Hours',
                      Colors.blue,
                      textPrimaryColor,
                      textSecondaryColor,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color iconColor,
    Color textPrimaryColor,
    Color textSecondaryColor,
  ) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
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
}
