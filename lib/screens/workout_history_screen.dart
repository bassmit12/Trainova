import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/workout_history.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart'; // Added import for Exercise
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  List<WorkoutHistory> _workoutHistory = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWorkoutHistory();
  }

  Future<void> _loadWorkoutHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final history = await WorkoutHistory.fetchUserWorkoutHistory();
      setState(() {
        _workoutHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load workout history: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor =
        themeProvider.isDarkMode
            ? AppColors.darkBackground
            : AppColors.lightBackground;
    final textPrimaryColor =
        themeProvider.isDarkMode
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;
    final textSecondaryColor =
        themeProvider.isDarkMode
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;
    final cardBackgroundColor =
        themeProvider.isDarkMode
            ? AppColors.darkCardBackground
            : AppColors.lightCardBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Workout History',
          style: TextStyle(color: textPrimaryColor),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textPrimaryColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textPrimaryColor),
            onPressed: _loadWorkoutHistory,
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error',
                        style: TextStyle(
                          color: textPrimaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: textSecondaryColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWorkoutHistory,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
                : _workoutHistory.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: textSecondaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No workout history yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete a workout to see it here',
                        style: TextStyle(color: textSecondaryColor),
                      ),
                    ],
                  ),
                )
                : _buildWorkoutHistoryList(
                  context,
                  cardBackgroundColor,
                  textPrimaryColor,
                  textSecondaryColor,
                ),
      ),
    );
  }

  Widget _buildWorkoutHistoryList(
    BuildContext context,
    Color cardBackgroundColor,
    Color textPrimaryColor,
    Color textSecondaryColor,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _workoutHistory.length,
      itemBuilder: (context, index) {
        final history = _workoutHistory[index];
        final shadowColor =
            themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
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
            child: InkWell(
              onTap: () => _showWorkoutHistoryDetails(context, history),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          history.workoutName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${history.durationMinutes} min',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateFormat.format(history.completedAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondaryColor,
                          ),
                        ),
                        Text(
                          timeFormat.format(history.completedAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat(
                          'Sets',
                          history.sets.length.toString(),
                          textPrimaryColor,
                          textSecondaryColor,
                        ),
                        _buildStat(
                          'Exercises',
                          _getUniqueExerciseCount(history).toString(),
                          textPrimaryColor,
                          textSecondaryColor,
                        ),
                        _buildStat(
                          'Calories',
                          history.caloriesBurned.toString(),
                          textPrimaryColor,
                          textSecondaryColor,
                        ),
                      ],
                    ),
                    if (history.notes != null && history.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Notes: ${history.notes}',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _getUniqueExerciseCount(WorkoutHistory history) {
    final uniqueExerciseIds = <String>{};
    for (final set in history.sets) {
      uniqueExerciseIds.add(set.exerciseId);
    }
    return uniqueExerciseIds.length;
  }

  Widget _buildStat(
    String label,
    String value,
    Color textPrimaryColor,
    Color textSecondaryColor,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: textSecondaryColor)),
      ],
    );
  }

  void _showWorkoutHistoryDetails(
    BuildContext context,
    WorkoutHistory history,
  ) async {
    // Show loading indicator first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Group sets by exercise
    final Map<String, List<WorkoutSet>> setsByExercise = {};
    for (final set in history.sets) {
      if (!setsByExercise.containsKey(set.exerciseId)) {
        setsByExercise[set.exerciseId] = [];
      }
      setsByExercise[set.exerciseId]!.add(set);
    }

    // Get all unique exercise IDs
    final exerciseIds = setsByExercise.keys.toList();

    // Fetch exercise details for each ID
    Map<String, Exercise> exercisesMap = {};

    try {
      // Fetch exercises and organize them by ID
      final exercisesData = await Exercise.fetchExercisesByIds(exerciseIds);
      // Since we're getting back a Map<String, Exercise>, we can assign it directly
      exercisesMap = exercisesData;
    } catch (e) {
      print('Error fetching exercises: $e');
    }

    // Close loading dialog
    if (context.mounted) {
      Navigator.pop(context);
    }

    if (!context.mounted) return;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final backgroundColor =
        themeProvider.isDarkMode
            ? AppColors.darkBackground
            : AppColors.lightBackground;
    final textPrimaryColor =
        themeProvider.isDarkMode
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;
    final textSecondaryColor =
        themeProvider.isDarkMode
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;
    final cardBackgroundColor =
        themeProvider.isDarkMode
            ? AppColors.darkCardBackground
            : AppColors.lightCardBackground;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: backgroundColor,
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Hero header with gradient background
                  SliverAppBar(
                    expandedHeight: 180,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                history.workoutName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    dateFormat.format(history.completedAt),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.access_time,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    timeFormat.format(history.completedAt),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      titlePadding: EdgeInsets.zero,
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Stats section
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 2),
                            blurRadius: 5,
                          ),
                        ],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildDetailStat(
                                icon: Icons.timer_outlined,
                                value: '${history.durationMinutes}',
                                label: 'Minutes',
                                iconColor: AppColors.primary,
                                textColor: textPrimaryColor,
                                secondaryColor: textSecondaryColor,
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: textSecondaryColor.withOpacity(0.2),
                              ),
                              _buildDetailStat(
                                icon: Icons.local_fire_department_outlined,
                                value: '${history.caloriesBurned}',
                                label: 'Calories',
                                iconColor: Colors.orange,
                                textColor: textPrimaryColor,
                                secondaryColor: textSecondaryColor,
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: textSecondaryColor.withOpacity(0.2),
                              ),
                              _buildDetailStat(
                                icon: Icons.fitness_center,
                                value: '${history.sets.length}',
                                label: 'Total Sets',
                                iconColor: Colors.green,
                                textColor: textPrimaryColor,
                                secondaryColor: textSecondaryColor,
                              ),
                            ],
                          ),

                          // Notes section if present
                          if (history.notes != null &&
                              history.notes!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.note_alt,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Notes',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    history.notes!,
                                    style: TextStyle(
                                      color: textPrimaryColor,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Exercise list header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.format_list_bulleted, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Exercises (${exerciseIds.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Exercise cards - keeping these as you like them
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final exerciseId = exerciseIds[index];
                      final exerciseSets = setsByExercise[exerciseId]!;

                      // Get exercise name from the map, or use fallback
                      final exercise = exercisesMap[exerciseId];
                      final exerciseName =
                          exercise?.name ?? 'Exercise ${index + 1}';
                      final muscleGroups =
                          exercise?.getMuscleGroupString() ?? '';

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBackgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exerciseName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimaryColor,
                                      ),
                                    ),
                                    if (muscleGroups.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          muscleGroups,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: textSecondaryColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: exerciseSets.length,
                                separatorBuilder:
                                    (_, __) => const Divider(height: 1),
                                itemBuilder: (context, setIndex) {
                                  final set = exerciseSets[setIndex];
                                  return ListTile(
                                    title: Text(
                                      'Set ${set.setNumber}',
                                      style: TextStyle(
                                        color: textPrimaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${set.weight} kg × ${set.reps} reps',
                                      style: TextStyle(
                                        color: textSecondaryColor,
                                      ),
                                    ),
                                    trailing:
                                        set.isCompleted
                                            ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                            )
                                            : Icon(
                                              Icons.cancel,
                                              color: Colors.red.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: exerciseIds.length),
                  ),

                  // Bottom padding for better scroll experience
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
      ),
    );
  }

  // Helper method to build stat items in the details screen
  Widget _buildDetailStat({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    required Color textColor,
    required Color secondaryColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: secondaryColor)),
      ],
    );
  }
}
