import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';
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

  // Mock data - in a real app this would come from a backend
  final List<Map<String, dynamic>> _weeklyWorkouts = [
    {'day': 'Mon', 'minutes': 45, 'calories': 320},
    {'day': 'Tue', 'minutes': 30, 'calories': 250},
    {'day': 'Wed', 'minutes': 0, 'calories': 0},
    {'day': 'Thu', 'minutes': 60, 'calories': 450},
    {'day': 'Fri', 'minutes': 45, 'calories': 380},
    {'day': 'Sat', 'minutes': 90, 'calories': 650},
    {'day': 'Sun', 'minutes': 0, 'calories': 0},
  ];

  final Map<String, dynamic> _goals = {
    'weeklyWorkouts': {'current': 4, 'target': 5},
    'weeklyMinutes': {'current': 270, 'target': 300},
    'monthlyCalories': {'current': 8500, 'target': 10000},
  };

  final List<Map<String, dynamic>> _recentWorkouts = [
    {
      'name': 'Full Body HIIT',
      'date': 'Today',
      'time': '35 min',
      'calories': 310,
      'completed': true,
    },
    {
      'name': 'Upper Body Strength',
      'date': 'Yesterday',
      'time': '45 min',
      'calories': 280,
      'completed': true,
    },
    {
      'name': 'Core & Stretching',
      'date': '2 days ago',
      'time': '30 min',
      'calories': 180,
      'completed': true,
    },
    {
      'name': 'Cardio Blast',
      'date': '3 days ago',
      'time': '25 min',
      'calories': 220,
      'completed': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
                    // TODO: Implement calendar view
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
                    _buildActivityChart(cardBackgroundColor, textPrimaryColor,
                        textSecondaryColor, shadowColor),
                    const SizedBox(height: 24),
                    _buildGoalProgress(cardBackgroundColor, textPrimaryColor,
                        textSecondaryColor, shadowColor),
                    const SizedBox(height: 24),
                    _buildWorkoutHistory(cardBackgroundColor, textPrimaryColor,
                        textSecondaryColor, shadowColor),
                    const SizedBox(height: 24),
                    _buildBodyStats(cardBackgroundColor, textPrimaryColor,
                        textSecondaryColor, shadowColor),
                  ],
                ),
              ),
            ),
          ],
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('View all workouts coming soon!')),
              );
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
                workout['completed'] ? 'Completed' : 'Missed',
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add measurement coming soon!')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 16),
                  SizedBox(width: 4),
                  Text('ADD'),
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
                '68.5',
                'kg',
                '+0.5 kg this month',
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
                '18.2',
                '%',
                '-1.3% this month',
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
                '52.4',
                '%',
                '+0.8% this month',
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
                '22.1',
                '',
                'Normal range',
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
              color: change.contains('+')
                  ? Colors.green
                  : change.contains('-')
                      ? Colors.red
                      : textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
