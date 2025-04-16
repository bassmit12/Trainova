import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:confetti/confetti.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' show pi;

import '../models/user.dart';
import '../models/workout_history.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../providers/theme_provider.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  // User data
  UserModel? _user;

  // Workout history data
  List<WorkoutHistory> _workoutHistory = [];

  // Goals data
  Map<String, dynamic> _currentGoals = {};
  Map<String, dynamic> _weeklyProgress = {};
  List<Map<String, dynamic>> _achievedGoals = [];

  // Confetti controller for celebrations
  late ConfettiController _confettiController;

  // Month names for date formatting
  final List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _loadUserData();
    _loadWorkoutHistory();
    _loadGoalsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.getCurrentUserProfile(forceRefresh: true);

      setState(() {
        _user = authService.currentUser;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load user data: $e';
      });
    }
  }

  Future<void> _loadWorkoutHistory() async {
    try {
      final history = await WorkoutHistory.fetchUserWorkoutHistory();
      setState(() {
        _workoutHistory = history;
      });
    } catch (e) {
      print('Error loading workout history: $e');
    }
  }

  Future<void> _loadGoalsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load real goals data from Supabase or create placeholder data for demo
      await Future.delayed(
          const Duration(milliseconds: 800)); // Simulating network request

      // Calculate weekly progress based on workout history
      _calculateWeeklyProgress();

      // Setup goals based on user profile
      _setupUserGoals();

      // Generate sample achieved goals
      _generateAchievedGoals();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load goals data: $e';
        _isLoading = false;
      });
    }
  }

  void _calculateWeeklyProgress() {
    // Get current week's workouts
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    // Filter workouts from current week
    final thisWeekWorkouts = _workoutHistory.where((workout) {
      final date = workout.completedAt;
      return date != null &&
          date.isAfter(startOfWeek) &&
          date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();

    // Calculate total workouts, minutes, and calories
    final totalWorkouts = thisWeekWorkouts.length;
    int totalMinutes = 0;
    int totalCalories = 0;

    for (var workout in thisWeekWorkouts) {
      // Calculate minutes based on workout sets
      int workoutMinutes = 0;
      for (var set in workout.sets) {
        // Rough estimate: 1-2 minutes per set
        workoutMinutes += 2;
      }

      totalMinutes += workoutMinutes;

      // Estimate calories: Approximately 8-10 calories per minute for average workout
      totalCalories += workoutMinutes * 9;
    }

    // Set weekly progress
    _weeklyProgress = {
      'workouts': {
        'current': totalWorkouts,
        'target': _user?.workoutsPerWeek ?? 3,
      },
      'minutes': {
        'current': totalMinutes,
        'target': 150, // WHO recommends 150 minutes per week
      },
      'calories': {
        'current': totalCalories,
        'target': 1500, // Sample target
      }
    };
  }

  void _setupUserGoals() {
    // Create goals based on user's fitness goal
    final fitnessGoal = _user?.fitnessGoal ?? 'general_fitness';

    switch (fitnessGoal) {
      case 'weight_loss':
        _currentGoals = {
          'primary': {
            'title': 'Weight Loss',
            'description': 'Lose 0.5 kg per week',
            'icon': Icons.monitor_weight,
            'progress': 0.4,
            'metrics': '2 kg / 5 kg',
            'dueDate': _getFormattedDate(30),
          },
          'secondary': [
            {
              'title': 'Cardio Sessions',
              'description': 'Complete cardio workouts',
              'icon': Icons.directions_run,
              'progress': 0.6,
              'metrics': '6 / 10 workouts',
              'dueDate': _getFormattedDate(14),
            },
            {
              'title': 'Calorie Deficit',
              'description': 'Maintain daily calorie deficit',
              'icon': Icons.local_fire_department,
              'progress': 0.7,
              'metrics': '5 / 7 days',
              'dueDate': 'This week',
            }
          ]
        };
        break;

      case 'muscle_gain':
        _currentGoals = {
          'primary': {
            'title': 'Muscle Gain',
            'description': 'Increase strength by 15%',
            'icon': Icons.fitness_center,
            'progress': 0.3,
            'metrics': '4.5% / 15%',
            'dueDate': _getFormattedDate(60),
          },
          'secondary': [
            {
              'title': 'Protein Intake',
              'description': 'Meet daily protein goals',
              'icon': Icons.restaurant,
              'progress': 0.8,
              'metrics': '24 / 30 days',
              'dueDate': _getFormattedDate(6),
            },
            {
              'title': 'Strength Training',
              'description': 'Complete strength workouts',
              'icon': Icons.fitness_center,
              'progress': 0.5,
              'metrics': '6 / 12 sessions',
              'dueDate': _getFormattedDate(20),
            }
          ]
        };
        break;

      case 'endurance':
        _currentGoals = {
          'primary': {
            'title': 'Endurance Building',
            'description': 'Run 5K without stopping',
            'icon': Icons.directions_run,
            'progress': 0.6,
            'metrics': '3K / 5K',
            'dueDate': _getFormattedDate(20),
          },
          'secondary': [
            {
              'title': 'Running Sessions',
              'description': 'Weekly running workouts',
              'icon': Icons.timer,
              'progress': 0.75,
              'metrics': '3 / 4 sessions',
              'dueDate': 'This week',
            },
            {
              'title': 'Recovery',
              'description': 'Complete recovery sessions',
              'icon': Icons.self_improvement,
              'progress': 0.33,
              'metrics': '1 / 3 sessions',
              'dueDate': _getFormattedDate(10),
            }
          ]
        };
        break;

      case 'flexibility':
        _currentGoals = {
          'primary': {
            'title': 'Flexibility Improvement',
            'description': 'Touch your toes with straight legs',
            'icon': Icons.self_improvement,
            'progress': 0.7,
            'metrics': '70% flexibility',
            'dueDate': _getFormattedDate(15),
          },
          'secondary': [
            {
              'title': 'Yoga Sessions',
              'description': 'Complete yoga workouts',
              'icon': Icons.self_improvement,
              'progress': 0.6,
              'metrics': '6 / 10 sessions',
              'dueDate': _getFormattedDate(14),
            },
            {
              'title': 'Daily Stretching',
              'description': 'Stretch for 10 minutes daily',
              'icon': Icons.accessibility_new,
              'progress': 0.43,
              'metrics': '3 / 7 days',
              'dueDate': 'This week',
            }
          ]
        };
        break;

      case 'general_fitness':
      default:
        _currentGoals = {
          'primary': {
            'title': 'Overall Fitness',
            'description': 'Improve general fitness level',
            'icon': Icons.trending_up,
            'progress': 0.5,
            'metrics': '50% complete',
            'dueDate': _getFormattedDate(30),
          },
          'secondary': [
            {
              'title': 'Weekly Workouts',
              'description': 'Complete regular workouts',
              'icon': Icons.fitness_center,
              'progress': 0.6,
              'metrics':
                  '${_weeklyProgress['workouts']?['current'] ?? 0} / ${_weeklyProgress['workouts']?['target'] ?? 3}',
              'dueDate': 'This week',
            },
            {
              'title': 'Active Minutes',
              'description': 'Weekly active minutes',
              'icon': Icons.timer,
              'progress': 0.4,
              'metrics':
                  '${_weeklyProgress['minutes']?['current'] ?? 0} / ${_weeklyProgress['minutes']?['target'] ?? 150} min',
              'dueDate': 'This week',
            }
          ]
        };
    }
  }

  void _generateAchievedGoals() {
    _achievedGoals = [
      {
        'title': 'First Workout',
        'description': 'Completed your first workout',
        'icon': Icons.fitness_center,
        'date': 'April 3, 2025',
        'reward': '+50 XP',
      },
      {
        'title': 'Workout Streak',
        'description': 'Completed 3 workouts in one week',
        'icon': Icons.local_fire_department,
        'date': 'April 8, 2025',
        'reward': '+100 XP',
      },
      {
        'title': 'Fitness Assessment',
        'description': 'Completed initial fitness assessment',
        'icon': Icons.assignment_turned_in,
        'date': 'March 30, 2025',
        'reward': '+75 XP',
      }
    ];
  }

  String _getFormattedDate(int daysFromNow) {
    final date = DateTime.now().add(Duration(days: daysFromNow));
    return '${_monthNames[date.month - 1]} ${date.day}';
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Your Goals'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddGoalDialog(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: textSecondaryColor,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Weekly'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? _buildErrorView(_error!)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCurrentGoalsTab(context, cardBackgroundColor,
                            textPrimaryColor, textSecondaryColor),
                        _buildWeeklyProgressTab(context, cardBackgroundColor,
                            textPrimaryColor, textSecondaryColor),
                        _buildAchievementsTab(context, cardBackgroundColor,
                            textPrimaryColor, textSecondaryColor),
                      ],
                    ),

          // Confetti effect when goals are achieved
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // straight up
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 10,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditGoalsDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadGoalsData,
            child: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentGoalsTab(BuildContext context, Color cardBackgroundColor,
      Color textPrimaryColor, Color textSecondaryColor) {
    // Extract primary goal and secondary goals
    final primaryGoal = _currentGoals['primary'];
    final secondaryGoals =
        _currentGoals['secondary'] as List<Map<String, dynamic>>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User's fitness goal section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryLight,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
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
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        primaryGoal['icon'] ?? Icons.fitness_center,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primaryGoal['title'] ?? 'Primary Goal',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          primaryGoal['description'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LinearPercentIndicator(
                  lineHeight: 12,
                  percent: primaryGoal['progress'] ?? 0.0,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  progressColor: Colors.white,
                  barRadius: const Radius.circular(8),
                  padding: EdgeInsets.zero,
                  animation: true,
                  animationDuration: 1000,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      primaryGoal['metrics'] ?? '0%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${primaryGoal['dueDate'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Supporting Goals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimaryColor,
            ),
          ),

          const SizedBox(height: 16),

          // Secondary goals
          ...secondaryGoals
              .map((goal) => _buildGoalCard(
                    goal: goal,
                    cardBackgroundColor: cardBackgroundColor,
                    textPrimaryColor: textPrimaryColor,
                    textSecondaryColor: textSecondaryColor,
                  ))
              .toList(),

          const SizedBox(height: 16),

          // Motivation quote
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Motivation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Progress takes time. Trust the process and stay consistent with your workouts.',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Extra bottom padding for FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildGoalCard({
    required Map<String, dynamic> goal,
    required Color cardBackgroundColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    goal['icon'] ?? Icons.star,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal['title'] ?? 'Goal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        goal['description'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: textSecondaryColor),
                  onSelected: (value) {
                    if (value == 'edit') {
                      // Edit goal (placeholder for now)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Edit goal feature coming soon')),
                      );
                    } else if (value == 'complete') {
                      _completeGoal(goal);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 18),
                          SizedBox(width: 8),
                          Text('Mark complete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearPercentIndicator(
              lineHeight: 10,
              percent: goal['progress'] ?? 0.0,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              progressColor: AppColors.primary,
              barRadius: const Radius.circular(8),
              padding: EdgeInsets.zero,
              animation: true,
              animationDuration: 1000,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  goal['metrics'] ?? '0%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimaryColor,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${goal['dueDate'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _completeGoal(Map<String, dynamic> goal) {
    // Show celebration and set progress to 100%
    _confettiController.play();

    // Show congratulatory message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Congratulations! You completed: ${goal['title']}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    // In a real app, you would update the database here
    // For demo purposes, we'll just modify the local state
    setState(() {
      goal['progress'] = 1.0;
      goal['metrics'] = 'Completed!';
    });
  }

  Widget _buildWeeklyProgressTab(
      BuildContext context,
      Color cardBackgroundColor,
      Color textPrimaryColor,
      Color textSecondaryColor) {
    // Extract weekly progress data
    final workouts = _weeklyProgress['workouts'] ?? {'current': 0, 'target': 0};
    final minutes = _weeklyProgress['minutes'] ?? {'current': 0, 'target': 0};
    final calories = _weeklyProgress['calories'] ?? {'current': 0, 'target': 0};

    // Calculate progress percentages (capped at 1.0)
    final workoutProgress =
        (workouts['current'] / workouts['target']).clamp(0.0, 1.0);
    final minutesProgress =
        (minutes['current'] / minutes['target']).clamp(0.0, 1.0);
    final caloriesProgress =
        (calories['current'] / calories['target']).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week\'s Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Track your progress toward weekly goals',
            style: TextStyle(
              fontSize: 14,
              color: textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),

          // Weekly workout goal progress
          _buildWeeklyGoalCard(
            title: 'Weekly Workouts',
            icon: Icons.fitness_center,
            currentValue: workouts['current'],
            targetValue: workouts['target'],
            progress: workoutProgress,
            unit: 'workouts',
            cardBackgroundColor: cardBackgroundColor,
            textPrimaryColor: textPrimaryColor,
            textSecondaryColor: textSecondaryColor,
          ),

          // Weekly active minutes progress
          _buildWeeklyGoalCard(
            title: 'Active Minutes',
            icon: Icons.timer,
            currentValue: minutes['current'],
            targetValue: minutes['target'],
            progress: minutesProgress,
            unit: 'minutes',
            cardBackgroundColor: cardBackgroundColor,
            textPrimaryColor: textPrimaryColor,
            textSecondaryColor: textSecondaryColor,
          ),

          // Weekly calories burned progress
          _buildWeeklyGoalCard(
            title: 'Calories Burned',
            icon: Icons.local_fire_department,
            currentValue: calories['current'],
            targetValue: calories['target'],
            progress: caloriesProgress,
            unit: 'calories',
            cardBackgroundColor: cardBackgroundColor,
            textPrimaryColor: textPrimaryColor,
            textSecondaryColor: textSecondaryColor,
          ),

          const SizedBox(height: 24),

          // Week activity breakdown
          Text(
            'Daily Activity',
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Day indicators row with activities
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _buildDayActivityIndicators(textSecondaryColor),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Workout',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${workouts['current']} / 7 days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tips for reaching goals
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryLight,
                  AppColors.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Tips for Success',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTipItem('Schedule your workouts in advance'),
                _buildTipItem('Find a workout buddy for accountability'),
                _buildTipItem(
                    'Start with shorter sessions and build up gradually'),
              ],
            ),
          ),

          // Extra bottom padding for FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDayActivityIndicators(Color textSecondaryColor) {
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final today = now.weekday; // 1 = Monday, 7 = Sunday

    // Mock data for which days had workouts
    final workoutDays = [1, 3, 5]; // Monday, Wednesday, Friday

    return List.generate(7, (index) {
      // 1-indexed weekday
      final weekday = index + 1;

      // Check if this day is today, a day with workout, or neither
      final isToday = weekday == today;
      final hasWorkout = workoutDays.contains(weekday);

      return Column(
        children: [
          Text(
            weekdays[index],
            style: TextStyle(
              fontSize: 14,
              color: textSecondaryColor,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasWorkout
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.1),
              border: isToday
                  ? Border.all(
                      color: AppColors.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: hasWorkout
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
          ),
        ],
      );
    });
  }

  Widget _buildWeeklyGoalCard({
    required String title,
    required IconData icon,
    required int currentValue,
    required int targetValue,
    required double progress,
    required String unit,
    required Color cardBackgroundColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: progress >= 1.0
                      ? Colors.green.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  progress >= 1.0
                      ? 'Complete!'
                      : '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: progress >= 1.0 ? Colors.green : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CircularPercentIndicator(
            radius: 60,
            lineWidth: 12,
            percent: progress,
            animation: true,
            animationDuration: 1000,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$currentValue',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
                Text(
                  'of $targetValue',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondaryColor,
                  ),
                ),
              ],
            ),
            progressColor: progress >= 1.0 ? Colors.green : AppColors.primary,
            backgroundColor:
                (progress >= 1.0 ? Colors.green : AppColors.primary)
                    .withOpacity(0.1),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 16),
          // Progress text
          Center(
            child: Text(
              progress >= 1.0
                  ? 'Goal achieved! Great job!'
                  : 'You need ${targetValue - currentValue} more $unit to reach your goal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(BuildContext context, Color cardBackgroundColor,
      Color textPrimaryColor, Color textSecondaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Achievements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Track your fitness journey milestones',
            style: TextStyle(
              fontSize: 14,
              color: textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),

          // Completed goals section
          ..._achievedGoals
              .map((goal) => _buildAchievementCard(
                    goal: goal,
                    cardBackgroundColor: cardBackgroundColor,
                    textPrimaryColor: textPrimaryColor,
                    textSecondaryColor: textSecondaryColor,
                  ))
              .toList(),

          const SizedBox(height: 24),

          // Upcoming achievements
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildUpcomingAchievement(
            title: 'Consistency King',
            description: 'Complete workouts for 7 days in a row',
            progress: '3/7 days',
            cardBackgroundColor: cardBackgroundColor,
            textPrimaryColor: textPrimaryColor,
            textSecondaryColor: textSecondaryColor,
          ),
          _buildUpcomingAchievement(
            title: 'Strength Milestone',
            description: 'Increase weights in all strength exercises by 10%',
            progress: '40% complete',
            cardBackgroundColor: cardBackgroundColor,
            textPrimaryColor: textPrimaryColor,
            textSecondaryColor: textSecondaryColor,
          ),

          const SizedBox(height: 80), // Extra spacing for FAB
        ],
      ),
    );
  }

  Widget _buildAchievementCard({
    required Map<String, dynamic> goal,
    required Color cardBackgroundColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.amber.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              goal['icon'] ?? Icons.emoji_events,
              color: Colors.amber,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal['title'] ?? 'Achievement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  goal['description'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          goal['date'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        goal['reward'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAchievement({
    required String title,
    required String description,
    required String progress,
    required Color cardBackgroundColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 14,
                      color: textSecondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      progress,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'In Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Goal'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Create a custom goal to track your progress.'),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Goal Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Target Value',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 5 workouts',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Goal adding feature coming soon')),
                );
              },
              child: const Text('Create Goal'),
            ),
          ],
        );
      },
    );
  }

  void _showEditGoalsDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            final themeProvider = Provider.of<ThemeProvider>(context);
            final textPrimaryColor = themeProvider.isDarkMode
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Fitness Goals',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Primary fitness goal selection
                      const Text(
                        'Primary Fitness Goal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'What do you want to achieve with your workouts?',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Goal options
                      _buildGoalOption(
                        title: 'Weight Loss',
                        icon: Icons.monitor_weight,
                        isSelected: _user?.fitnessGoal == 'weight_loss',
                        onTap: () => _updatePrimaryGoal('weight_loss'),
                      ),
                      _buildGoalOption(
                        title: 'Muscle Gain',
                        icon: Icons.fitness_center,
                        isSelected: _user?.fitnessGoal == 'muscle_gain',
                        onTap: () => _updatePrimaryGoal('muscle_gain'),
                      ),
                      _buildGoalOption(
                        title: 'Improve Endurance',
                        icon: Icons.directions_run,
                        isSelected: _user?.fitnessGoal == 'endurance',
                        onTap: () => _updatePrimaryGoal('endurance'),
                      ),
                      _buildGoalOption(
                        title: 'Increase Flexibility',
                        icon: Icons.self_improvement,
                        isSelected: _user?.fitnessGoal == 'flexibility',
                        onTap: () => _updatePrimaryGoal('flexibility'),
                      ),
                      _buildGoalOption(
                        title: 'General Fitness',
                        icon: Icons.favorite,
                        isSelected: _user?.fitnessGoal == 'general_fitness',
                        onTap: () => _updatePrimaryGoal('general_fitness'),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // Workout frequency
                      const Text(
                        'Weekly Workout Frequency',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'How many times per week do you want to workout?',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Slider for workout frequency
                      Slider(
                        value: (_user?.workoutsPerWeek ?? 3).toDouble(),
                        min: 1,
                        max: 7,
                        divisions: 6,
                        label: '${_user?.workoutsPerWeek ?? 3} days',
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          // This would be implemented with real data persistence
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Frequency update coming soon'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      Center(
                        child: Text(
                          '${_user?.workoutsPerWeek ?? 3} days per week',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Call method to update goals in database
                            _saveGoalsChanges();
                          },
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGoalOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  void _updatePrimaryGoal(String goalType) {
    // For demonstration purposes only
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goal update feature coming soon')),
    );
  }

  Future<void> _saveGoalsChanges() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved successfully')),
    );

    // In a real implementation, you would save to database here
    // Then reload goals data
    _loadGoalsData();
  }
}
