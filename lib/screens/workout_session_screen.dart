import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_set.dart';
import '../utils/app_colors.dart';
import '../services/workout_session_service.dart';
import '../providers/theme_provider.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutSessionScreen({Key? key, required this.workout})
      : super(key: key);

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late final WorkoutSessionService _sessionService;
  final Map<String, List<WorkoutSet>> _exerciseSets = {};
  int _currentExerciseIndex = 0;
  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sessionService =
        Provider.of<WorkoutSessionService>(context, listen: false);
    _initializeWorkoutSession();
  }

  Future<void> _initializeWorkoutSession() async {
    try {
      // If there's no active session, create one
      if (!_sessionService.hasActiveSession) {
        await _sessionService.startWorkout(widget.workout.id);
      }

      // Initialize sets for each exercise
      for (var exercise in widget.workout.exercises) {
        _exerciseSets[exercise.id] = [];

        // Add initial set for each exercise
        await _addSetForExercise(exercise);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize workout: $e';
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _addSetForExercise(Exercise exercise) async {
    final sets = _exerciseSets[exercise.id];
    if (sets == null) return;

    final setNumber = sets.length + 1;
    final workoutSet = WorkoutSet(
      exerciseId: exercise.id,
      setNumber: setNumber,
      reps: exercise.reps, // Default to the exercise's recommended reps
    );

    await _sessionService.addSet(workoutSet);
    setState(() {
      sets.add(workoutSet);
    });
  }

  void _updateSet(WorkoutSet set,
      {double? weight, int? reps, bool? isCompleted}) async {
    await _sessionService.updateSet(
      set.id,
      weight: weight,
      reps: reps,
      isCompleted: isCompleted,
    );

    // Update UI state
    setState(() {
      final index =
          _exerciseSets[set.exerciseId]?.indexWhere((s) => s.id == set.id);
      if (index != null && index != -1) {
        _exerciseSets[set.exerciseId]![index] =
            _exerciseSets[set.exerciseId]![index].copyWith(
          weight: weight ?? _exerciseSets[set.exerciseId]![index].weight,
          reps: reps ?? _exerciseSets[set.exerciseId]![index].reps,
          isCompleted:
              isCompleted ?? _exerciseSets[set.exerciseId]![index].isCompleted,
        );
      }
    });
  }

  void _goToNextExercise() {
    if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    }
  }

  void _goToPreviousExercise() {
    if (_currentExerciseIndex > 0) {
      setState(() {
        _currentExerciseIndex--;
      });
    }
  }

  Future<void> _finishWorkout() async {
    final bool allSetsCompleted = _exerciseSets.values.every(
      (sets) => sets.every((set) => set.isCompleted),
    );

    if (!allSetsCompleted) {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Finish Workout?'),
              content: const Text(
                  'Not all sets are marked as completed. Do you still want to finish this workout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('FINISH'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) return;
    }

    try {
      await _sessionService.completeWorkout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout completed!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete workout: $e')),
      );
    }
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

    if (_isInitializing) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text('Starting Workout',
              style: TextStyle(color: textPrimaryColor)),
          backgroundColor: backgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimaryColor),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title:
              Text('Workout Error', style: TextStyle(color: textPrimaryColor)),
          backgroundColor: backgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimaryColor),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: textPrimaryColor)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentExercise = widget.workout.exercises[_currentExerciseIndex];
    final sets = _exerciseSets[currentExercise.id] ?? [];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.workout.name,
          style: TextStyle(color: textPrimaryColor),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _finishWorkout,
            tooltip: 'Complete Workout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Exercise progress indicator
          LinearProgressIndicator(
            value:
                (_currentExerciseIndex + 1) / widget.workout.exercises.length,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),

          // Exercise info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Exercise ${_currentExerciseIndex + 1}/${widget.workout.exercises.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondaryColor,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Instructions'),
                      onPressed: () =>
                          _showExerciseInstructions(currentExercise),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Current exercise card
                Card(
                  color: cardBackgroundColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: currentExercise.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.primary.withOpacity(0.1),
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.primary.withOpacity(0.1),
                              child: const Icon(Icons.fitness_center,
                                  color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentExercise.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Target: ${currentExercise.getMuscleGroupString()}',
                                style: TextStyle(color: textSecondaryColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sets table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const SizedBox(width: 48, child: Text('SET')),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'WEIGHT (kg)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'REPS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          const Divider(),

          // Sets list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: sets.length,
              itemBuilder: (context, index) {
                final set = sets[index];
                return _buildSetRow(set, textPrimaryColor);
              },
            ),
          ),

          // Add set button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: () => _addSetForExercise(currentExercise),
              icon: const Icon(Icons.add),
              label: const Text('Add Set'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          // Navigation buttons
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // Previous exercise button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentExerciseIndex > 0
                        ? _goToPreviousExercise
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: _currentExerciseIndex > 0
                            ? AppColors.primary
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Next exercise button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentExerciseIndex <
                            widget.workout.exercises.length - 1
                        ? _goToNextExercise
                        : _finishWorkout,
                    icon: Icon(_currentExerciseIndex <
                            widget.workout.exercises.length - 1
                        ? Icons.arrow_forward
                        : Icons.check),
                    label: Text(_currentExerciseIndex <
                            widget.workout.exercises.length - 1
                        ? 'Next'
                        : 'Finish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build a single set row with weight and reps input
  Widget _buildSetRow(WorkoutSet set, Color textColor) {
    final weightController = TextEditingController(
        text: set.weight > 0 ? set.weight.toString() : '');
    final repsController =
        TextEditingController(text: set.reps > 0 ? set.reps.toString() : '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 48,
            child: Text(
              'Set ${set.setNumber}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Weight input
          Expanded(
            child: TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: TextStyle(color: textColor),
              onChanged: (value) {
                final weight = double.tryParse(value);
                if (weight != null) {
                  _updateSet(set, weight: weight);
                }
              },
            ),
          ),
          const SizedBox(width: 8),

          // Reps input
          Expanded(
            child: TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: TextStyle(color: textColor),
              onChanged: (value) {
                final reps = int.tryParse(value);
                if (reps != null) {
                  _updateSet(set, reps: reps);
                }
              },
            ),
          ),
          const SizedBox(width: 8),

          // Complete set checkbox
          SizedBox(
            width: 40,
            child: IconButton(
              icon: Icon(
                set.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: set.isCompleted ? AppColors.primary : Colors.grey,
              ),
              onPressed: () {
                _updateSet(set, isCompleted: !set.isCompleted);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseInstructions(Exercise exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final cardBackgroundColor = themeProvider.isDarkMode
            ? AppColors.darkCardBackground
            : AppColors.lightCardBackground;
        final textPrimaryColor = themeProvider.isDarkMode
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          exercise.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (exercise.imageUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: exercise.imageUrl,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: 200,
                                    color: AppColors.primary.withOpacity(0.1),
                                    child: const Center(
                                        child: CircularProgressIndicator()),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    height: 200,
                                    color: AppColors.primary.withOpacity(0.1),
                                    child: const Icon(Icons.fitness_center,
                                        size: 48, color: AppColors.primary),
                                  ),
                                ),
                              ),
                            ),
                          Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            exercise.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: textPrimaryColor,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Target Muscles',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: exercise.targetMuscles.map((muscle) {
                              return Chip(
                                label: Text(muscle),
                                backgroundColor: AppColors.primary,
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                              );
                            }).toList(),
                          ),
                          if (exercise.equipment.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Equipment Needed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              exercise.getEquipmentString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: textPrimaryColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
