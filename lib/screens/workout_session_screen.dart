import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_set.dart';
import '../models/weight_prediction.dart';
import '../utils/app_colors.dart';
import '../services/workout_session_service.dart';
import '../services/progressive_overload_service.dart';
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
  late final ProgressiveOverloadService _predictionService;
  final Map<String, List<WorkoutSet>> _exerciseSets = {};
  final Map<String, WeightPrediction?> _exercisePredictions = {};
  int _currentExerciseIndex = 0;
  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sessionService = Provider.of<WorkoutSessionService>(
      context,
      listen: false,
    );
    _predictionService = ProgressiveOverloadService();
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

        // First fetch recommended weight for this exercise
        await _fetchRecommendedWeight(exercise);

        // Then add initial set with the prediction data
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

    // Get prediction if available, otherwise use exercise defaults
    double initialWeight = 0;
    int initialReps = exercise.reps;

    final prediction = _exercisePredictions[exercise.id];
    if (prediction != null) {
      // Use the predicted weight
      initialWeight = prediction.predictedWeight;

      // Use the suggested reps if available for this set number
      if (prediction.suggestedReps != null &&
          prediction.suggestedReps!.isNotEmpty &&
          setNumber <= prediction.suggestedReps!.length) {
        initialReps = prediction.suggestedReps![setNumber - 1];
      }
    }

    final workoutSet = WorkoutSet(
      exerciseId: exercise.id,
      setNumber: setNumber,
      weight: initialWeight,
      reps: initialReps,
    );

    await _sessionService.addSet(workoutSet);

    // Save the predicted weight to the set for feedback purposes
    if (prediction != null) {
      await _sessionService.savePredictedWeight(
        workoutSet.id,
        prediction.predictedWeight,
      );
    }

    setState(() {
      sets.add(workoutSet);
    });
  }

  void _updateSet(
    WorkoutSet set, {
    double? weight,
    int? reps,
    bool? isCompleted,
    int? rir,
  }) async {
    await _sessionService.updateSet(
      set.id,
      weight: weight,
      reps: reps,
      isCompleted: isCompleted,
      rir: rir,
    );

    // Update UI state
    setState(() {
      final index = _exerciseSets[set.exerciseId]?.indexWhere(
        (s) => s.id == set.id,
      );
      if (index != null && index != -1) {
        _exerciseSets[set.exerciseId]![index] =
            _exerciseSets[set.exerciseId]![index].copyWith(
              weight: weight ?? _exerciseSets[set.exerciseId]![index].weight,
              reps: reps ?? _exerciseSets[set.exerciseId]![index].reps,
              isCompleted:
                  isCompleted ??
                  _exerciseSets[set.exerciseId]![index].isCompleted,
              rir: rir ?? _exerciseSets[set.exerciseId]![index].rir,
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
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Finish Workout?'),
                  content: const Text(
                    'Not all sets are marked as completed. Do you still want to finish this workout?',
                  ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Workout completed!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to complete workout: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final backgroundColor =
        themeProvider.isDarkMode
            ? AppColors.darkBackground
            : AppColors.lightBackground;
    final cardBackgroundColor =
        themeProvider.isDarkMode
            ? AppColors.darkCardBackground
            : AppColors.lightCardBackground;
    final textPrimaryColor =
        themeProvider.isDarkMode
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;
    final textSecondaryColor =
        themeProvider.isDarkMode
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;

    if (_isInitializing) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            'Starting Workout',
            style: TextStyle(color: textPrimaryColor),
          ),
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
          title: Text(
            'Workout Error',
            style: TextStyle(color: textPrimaryColor),
          ),
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
                      style: TextStyle(fontSize: 14, color: textSecondaryColor),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Instructions'),
                      onPressed:
                          () => _showExerciseInstructions(currentExercise),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: currentExercise.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: AppColors.primary.withOpacity(0.1),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color: AppColors.primary.withOpacity(0.1),
                                      child: const Icon(
                                        Icons.fitness_center,
                                        color: AppColors.primary,
                                      ),
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

                        // Display weight prediction if available
                        if (_exercisePredictions.containsKey(
                              currentExercise.id,
                            ) &&
                            _exercisePredictions[currentExercise.id] != null)
                          _buildWeightPredictionCard(
                            _exercisePredictions[currentExercise.id]!,
                            textPrimaryColor,
                            textSecondaryColor,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

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
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                // Previous exercise button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _currentExerciseIndex > 0
                            ? _goToPreviousExercise
                            : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color:
                            _currentExerciseIndex > 0
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
                    onPressed:
                        _currentExerciseIndex <
                                widget.workout.exercises.length - 1
                            ? _goToNextExercise
                            : _finishWorkout,
                    icon: Icon(
                      _currentExerciseIndex <
                              widget.workout.exercises.length - 1
                          ? Icons.arrow_forward
                          : Icons.check,
                    ),
                    label: Text(
                      _currentExerciseIndex <
                              widget.workout.exercises.length - 1
                          ? 'Next'
                          : 'Finish',
                    ),
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

  // Build a single set row with weight, reps, and RIR input
  Widget _buildSetRow(WorkoutSet set, Color textColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Theme-aware colors for input fields
    final inputFillColor =
        themeProvider.isDarkMode
            ? AppColors.darkCardBackground.withOpacity(0.8)
            : Colors.grey.shade100;
    final labelColor =
        themeProvider.isDarkMode
            ? AppColors.darkTextSecondary
            : Colors.grey.shade600;
    final hintColor =
        themeProvider.isDarkMode
            ? AppColors.darkTextSecondary.withOpacity(0.6)
            : Colors.grey.shade400;

    final weightController = TextEditingController(
      text: set.weight > 0 ? set.weight.toString() : '',
    );
    final repsController = TextEditingController(
      text: set.reps > 0 ? set.reps.toString() : '',
    );
    final rirController = TextEditingController(
      text: set.rir != null ? set.rir.toString() : '',
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Set number and completion status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Set ${set.setNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                // Complete set toggle
                GestureDetector(
                  onTap: () {
                    _updateSet(set, isCompleted: !set.isCompleted);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          set.isCompleted
                              ? AppColors.primary
                              : (themeProvider.isDarkMode
                                  ? AppColors.darkCardBackground.withOpacity(
                                    0.7,
                                  )
                                  : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      set.isCompleted ? 'Completed' : 'Mark Complete',
                      style: TextStyle(
                        color:
                            set.isCompleted
                                ? Colors.white
                                : (themeProvider.isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : Colors.grey.shade700),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weight input with +/- buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WEIGHT (kg)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Decrement button
                    _buildWeightButton(
                      icon: Icons.remove,
                      onPressed: () {
                        final currentWeight =
                            double.tryParse(weightController.text) ?? 0;
                        if (currentWeight >= 2.5) {
                          final newWeight = (currentWeight - 2.5)
                              .toStringAsFixed(1);
                          weightController.text = newWeight;
                          _updateSet(set, weight: currentWeight - 2.5);
                        }
                      },
                    ),
                    const SizedBox(width: 12),

                    // Weight input field
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: inputFillColor,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          final weight = double.tryParse(value);
                          if (weight != null) {
                            _updateSet(set, weight: weight);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Increment button
                    _buildWeightButton(
                      icon: Icons.add,
                      onPressed: () {
                        final currentWeight =
                            double.tryParse(weightController.text) ?? 0;
                        final newWeight = (currentWeight + 2.5).toStringAsFixed(
                          1,
                        );
                        weightController.text = newWeight;
                        _updateSet(set, weight: currentWeight + 2.5);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reps input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REPS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Decrement button
                    _buildWeightButton(
                      icon: Icons.remove,
                      onPressed: () {
                        final currentReps =
                            int.tryParse(repsController.text) ?? 0;
                        if (currentReps > 1) {
                          repsController.text = (currentReps - 1).toString();
                          _updateSet(set, reps: currentReps - 1);
                        }
                      },
                    ),
                    const SizedBox(width: 12),

                    // Reps input field
                    Expanded(
                      child: TextField(
                        controller: repsController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: inputFillColor,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          final reps = int.tryParse(value);
                          if (reps != null) {
                            _updateSet(set, reps: reps);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Increment button
                    _buildWeightButton(
                      icon: Icons.add,
                      onPressed: () {
                        final currentReps =
                            int.tryParse(repsController.text) ?? 0;
                        repsController.text = (currentReps + 1).toString();
                        _updateSet(set, reps: currentReps + 1);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // RIR (Reps in Reserve) input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'REPS IN RESERVE (RIR)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message:
                          'RIR represents how many more reps you could have done',
                      child: Icon(
                        Icons.info_outline,
                        size: 14,
                        color: labelColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Decrement button
                    _buildWeightButton(
                      icon: Icons.remove,
                      onPressed: () {
                        final currentRir =
                            int.tryParse(rirController.text) ?? 0;
                        if (currentRir > 0) {
                          rirController.text = (currentRir - 1).toString();
                          _updateSet(set, rir: currentRir - 1);
                        }
                      },
                    ),
                    const SizedBox(width: 12),

                    // RIR input field
                    Expanded(
                      child: TextField(
                        controller: rirController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: inputFillColor,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          hintText: '0-5',
                          hintStyle: TextStyle(color: hintColor, fontSize: 16),
                        ),
                        onChanged: (value) {
                          final rir = int.tryParse(value);
                          if (rir != null) {
                            _updateSet(set, rir: rir);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Increment button
                    _buildWeightButton(
                      icon: Icons.add,
                      onPressed: () {
                        final currentRir =
                            int.tryParse(rirController.text) ?? 0;
                        if (currentRir < 10) {
                          // Set reasonable upper limit
                          rirController.text = (currentRir + 1).toString();
                          _updateSet(set, rir: currentRir + 1);
                        }
                      },
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

  // Helper to build weight increment/decrement buttons
  Widget _buildWeightButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
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
        final cardBackgroundColor =
            themeProvider.isDarkMode
                ? AppColors.darkCardBackground
                : AppColors.lightCardBackground;
        final textPrimaryColor =
            themeProvider.isDarkMode
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
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
                                  placeholder:
                                      (context, url) => Container(
                                        height: 200,
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Container(
                                        height: 200,
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                        child: const Icon(
                                          Icons.fitness_center,
                                          size: 48,
                                          color: AppColors.primary,
                                        ),
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
                            children:
                                exercise.targetMuscles.map((muscle) {
                                  return Chip(
                                    label: Text(muscle),
                                    backgroundColor: AppColors.primary,
                                    labelStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  );
                                }).toList(),
                          ),
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

  Future<void> _fetchRecommendedWeight(Exercise exercise) async {
    try {
      final prediction = await _predictionService.getRecommendedWeight(
        exercise.id,
      );
      if (mounted) {
        setState(() {
          _exercisePredictions[exercise.id] = prediction;
        });
      }
    } catch (e) {
      // Just store null for this exercise's prediction, which will
      // cause the UI to fall back to default weights
      if (mounted) {
        setState(() {
          _exercisePredictions[exercise.id] = null;
        });
      }
      // Log error but don't fail the entire workout initialization
      print('Error fetching weight prediction for ${exercise.name}: $e');
    }
  }

  // This new method stores the predicted weight with the workout set for feedback purposes
  Future<void> _savePredictedWeightToSet(
    String setId,
    Exercise exercise,
  ) async {
    final prediction = _exercisePredictions[exercise.id];
    if (prediction != null) {
      try {
        await _sessionService.savePredictedWeight(
          setId,
          prediction.predictedWeight,
        );
        debugPrint(
          'Saved predicted weight ${prediction.predictedWeight} for set $setId',
        );
      } catch (e) {
        debugPrint('Failed to save predicted weight: $e');
      }
    }
  }

  Widget _buildWeightPredictionCard(
    WeightPrediction prediction,
    Color textPrimaryColor,
    Color textSecondaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Card(
        color: AppColors.primary.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Recommendation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(prediction.confidence! * 100).toStringAsFixed(0)}% confidence',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggested Weight',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            prediction.predictedWeight.toString(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'kg',
                            style: TextStyle(
                              fontSize: 16,
                              color: textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (prediction.suggestedReps != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Suggested Reps',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children:
                              prediction.suggestedReps!.map((reps) {
                                return Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$reps',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                ],
              ),
              if (prediction.message != null) ...[
                const SizedBox(height: 12),
                Text(
                  prediction.message!,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: textSecondaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
