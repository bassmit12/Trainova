import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';
import '../services/workout_session_service.dart';
import 'workout_session_screen.dart';
import 'create_workout_screen.dart';
import '../widgets/message_overlay.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailsScreen({Key? key, required this.workout})
    : super(key: key);

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  late List<Exercise> _currentExercises;
  final ScrollController _scrollController = ScrollController();
  bool _showTitle = false;
  bool _isLoading = false;
  bool _isAdmin = false; // Track admin status
  bool _hasChanges = false; // Track if user made changes

  @override
  void initState() {
    super.initState();
    _currentExercises = List.from(widget.workout.exercises);
    _scrollController.addListener(_onScroll);
    _checkAdminMode();

    // Set preferred orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    // Reset orientation settings
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _onScroll() {
    final showTitle = _scrollController.offset > 140;
    if (showTitle != _showTitle) {
      setState(() {
        _showTitle = showTitle;
      });
    }
  }

  void _replaceExercise(int index, Exercise newExercise) {
    setState(() {
      _currentExercises[index] = newExercise;
      _hasChanges = true;
    });
  }

  void _updateExerciseSetsReps(int index, {int? sets, int? reps}) {
    setState(() {
      final exercise = _currentExercises[index];
      _currentExercises[index] = Exercise(
        id: exercise.id,
        name: exercise.name,
        description: exercise.description,
        sets: sets ?? exercise.sets,
        reps: reps ?? exercise.reps,
        imageUrl: exercise.imageUrl,
        targetMuscles: exercise.targetMuscles,
        difficulty: exercise.difficulty,
        isPublic: exercise.isPublic,
        createdBy: exercise.createdBy,
      );

      // Mark that changes have been made that need to be saved
      _hasChanges = true;
    });
  }

  Widget _buildNumberControl(
    int value,
    Function(int) onChanged, {
    required int min,
    required int max,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(
            Icons.remove_circle,
            size: 20,
            color: AppColors.primary,
          ),
          onPressed: value > min ? () => onChanged(value - 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$value',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.add_circle,
            size: 20,
            color: AppColors.primary,
          ),
          onPressed: value < max ? () => onChanged(value + 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  void _showSwapExerciseDialog(int index, Exercise exercise) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final alternatives = await Exercise.getAlternativeExercises(exercise);

    Navigator.pop(context); // Close loading dialog

    if (alternatives.isEmpty) {
      MessageOverlay.showInfo(
        context,
        message: 'No alternative exercises found',
      );
      return;
    }

    // Show alternatives sheet
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
        final textSecondaryColor =
            themeProvider.isDarkMode
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary;

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Replace ${exercise.name}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimaryColor,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: textPrimaryColor),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        Text(
                          'Current targets: ${exercise.getMuscleGroupString()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: alternatives.length,
                      itemBuilder: (context, i) {
                        final alt = alternatives[i];
                        return _buildAlternativeExerciseItem(
                          alt,
                          index,
                          cardBackgroundColor: cardBackgroundColor,
                          textPrimaryColor: textPrimaryColor,
                          textSecondaryColor: textSecondaryColor,
                        );
                      },
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

  Widget _buildAlternativeExerciseItem(
    Exercise exercise,
    int indexToReplace, {
    required Color cardBackgroundColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
  }) {
    return Card(
      color: cardBackgroundColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _replaceExercise(indexToReplace, exercise);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: exercise.imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        width: 70,
                        height: 70,
                        color: AppColors.primary.withOpacity(0.1),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        width: 70,
                        height: 70,
                        color: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.fitness_center,
                          color: AppColors.primary,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.sets} sets • ${exercise.reps} reps',
                      style: TextStyle(fontSize: 14, color: textSecondaryColor),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        ...exercise.targetMuscles.map(
                          (muscle) => Chip(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            label: Text(
                              muscle,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.swap_horiz, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  void _startWorkout(BuildContext context) async {
    final sessionService = Provider.of<WorkoutSessionService>(
      context,
      listen: false,
    );

    // Check if there's an active session already
    if (sessionService.hasActiveSession) {
      final continueWorkout =
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Workout in Progress'),
                  content: const Text(
                    'You already have a workout in progress. Do you want to continue with this new workout?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('CONTINUE'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!continueWorkout) {
        return;
      }
    }

    // Navigate to the workout session screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionScreen(workout: widget.workout),
      ),
    );

    if (result == true) {
      MessageOverlay.showSuccess(
        context,
        message: 'Great job! Workout completed!',
      );
    }
  }

  // Check if admin mode is enabled
  Future<void> _checkAdminMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAdmin = prefs.getBool('admin_mode') ?? false;
    });
  }

  // Delete the workout
  Future<void> _deleteWorkout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await widget.workout.deleteWorkout();
      if (result) {
        if (mounted) {
          MessageOverlay.showSuccess(
            context,
            message: 'Workout deleted successfully',
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          MessageOverlay.showError(
            context,
            message: 'Failed to delete workout',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        MessageOverlay.showError(context, message: 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Show confirmation dialog before deleting
  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Workout'),
            content: const Text(
              'Are you sure you want to delete this workout? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      await _deleteWorkout();
    }
  }

  // Navigate to edit workout screen
  void _editWorkout(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateWorkoutScreen(workout: widget.workout),
      ),
    );

    if (result == true) {
      // Reload the workout after editing
      setState(() {
        _isLoading = true;
      });
      try {
        final updatedWorkout = await Workout.fetchWorkoutById(
          widget.workout.id,
        );
        if (updatedWorkout != null && mounted) {
          MessageOverlay.showSuccess(
            context,
            message: 'Workout updated successfully',
          );
          // Close this screen and return to previous screen
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          MessageOverlay.showError(
            context,
            message: 'Error updating workout: ${e.toString()}',
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Save changes to exercises (sets and reps)
  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new workout object with the updated exercises
      final updatedWorkout = Workout(
        id: widget.workout.id,
        name: widget.workout.name,
        description: widget.workout.description,
        type: widget.workout.type,
        imageUrl: widget.workout.imageUrl,
        duration: widget.workout.duration,
        difficulty: widget.workout.difficulty,
        caloriesBurned: widget.workout.caloriesBurned,
        exercises: _currentExercises, // Use the modified exercises
        isPublic: widget.workout.isPublic,
        createdBy: widget.workout.createdBy,
        createdAt: widget.workout.createdAt,
      );

      // Save the updated workout to the database
      final result = await updatedWorkout.updateWorkout();

      if (result != null) {
        if (mounted) {
          // Reset the change flag
          setState(() {
            _hasChanges = false;
          });

          // Show success message
          MessageOverlay.showSuccess(
            context,
            message: 'Workout exercises updated successfully',
          );
        }
      } else {
        if (mounted) {
          MessageOverlay.showError(context, message: 'Failed to save changes');
        }
      }
    } catch (e) {
      if (mounted) {
        MessageOverlay.showError(
          context,
          message: 'Error saving changes: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    final totalExerciseCount = _currentExercises.length;
    final estimatedTotalTime = _estimateTotalTime();

    // Check if current user is the owner
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = widget.workout.createdBy == currentUserId;

    // User can edit/delete if they're the owner OR if they have admin mode enabled
    final canEditDelete = isOwner || _isAdmin;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              stretch: true,
              backgroundColor: AppColors.primary,
              title: _showTitle ? Text(widget.workout.name) : null,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image
                    _buildHeaderImage(),

                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),

                    // Workout info
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.workout.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildHeaderChip(
                                Icons.timer,
                                widget.workout.duration,
                              ),
                              const SizedBox(width: 12),
                              _buildHeaderChip(
                                Icons.fitness_center,
                                widget.workout.difficulty,
                              ),
                              const SizedBox(width: 12),
                              _buildHeaderChip(
                                Icons.local_fire_department,
                                "${widget.workout.caloriesBurned} kcal",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                else ...[
                  // Save button (only shown when changes have been made)
                  if (_hasChanges)
                    IconButton(
                      icon: const Icon(Icons.save),
                      tooltip: 'Save Changes',
                      onPressed: _saveChanges,
                    ),

                  // Only show edit/delete buttons if user can edit the workout
                  if (canEditDelete) ...[
                    // Edit button
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editWorkout(context),
                    ),
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _confirmDelete,
                    ),
                  ],
                ],
              ],
            ),
          ];
        },
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Workout stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.fitness_center,
                        title: "Exercises",
                        value: "$totalExerciseCount",
                        color: AppColors.primary,
                        backgroundColor: cardBackgroundColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.timer,
                        title: "Est. Time",
                        value: estimatedTotalTime,
                        color: AppColors.primaryLight,
                        backgroundColor: cardBackgroundColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Workout type
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getWorkoutTypeIcon(widget.workout.type),
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.workout.type,
                        style: TextStyle(
                          color: textPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Description
                Text(
                  "About this workout",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.workout.description,
                  style: TextStyle(color: textSecondaryColor, height: 1.5),
                ),

                const SizedBox(height: 32),

                // Exercises heading
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Exercises",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                    Text(
                      "$totalExerciseCount exercises",
                      style: TextStyle(color: textSecondaryColor),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Exercise list
                ...List.generate(_currentExercises.length, (index) {
                  final exercise = _currentExercises[index];
                  return _buildExerciseCard(
                    exercise: exercise,
                    index: index,
                    cardBackgroundColor: cardBackgroundColor,
                    textPrimaryColor: textPrimaryColor,
                    textSecondaryColor: textSecondaryColor,
                  );
                }),

                // Bottom padding for FAB
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 54,
        margin: const EdgeInsets.only(bottom: 16),
        child: ElevatedButton(
          onPressed: () => _startWorkout(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow),
              ),
              const SizedBox(width: 12),
              const Text(
                'START WORKOUT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeaderImage() {
    try {
      return CachedNetworkImage(
        imageUrl: widget.workout.imageUrl,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              color: AppColors.primary.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        errorWidget: (context, url, error) => _buildPlaceholderBackground(),
      );
    } catch (e) {
      return _buildPlaceholderBackground();
    }
  }

  Widget _buildPlaceholderBackground() {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getWorkoutTypeIcon(widget.workout.type),
              color: Colors.white.withOpacity(0.8),
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              widget.workout.type,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontSize: 12)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard({
    required Exercise exercise,
    required int index,
    required Color cardBackgroundColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exercise number
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Exercise info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textPrimaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildNumberControl(
                            exercise.sets,
                            (newSets) =>
                                _updateExerciseSetsReps(index, sets: newSets),
                            min: 1,
                            max: 10,
                          ),
                          const SizedBox(width: 16),
                          _buildNumberControl(
                            exercise.reps,
                            (newReps) =>
                                _updateExerciseSetsReps(index, reps: newReps),
                            min: 1,
                            max: 50,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              exercise.targetMuscles.map((muscle) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    muscle,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Swap button
                GestureDetector(
                  onTap: () => _showSwapExerciseDialog(index, exercise),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Exercise image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: CachedNetworkImage(
              imageUrl: exercise.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(
                    height: 180,
                    color: AppColors.primary.withOpacity(0.1),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    height: 180,
                    color: AppColors.primary.withOpacity(0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          color: AppColors.primary,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          exercise.name,
                          style: TextStyle(color: textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
            ),
          ),

          // Exercise description (expandable)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                'Instructions',
                style: TextStyle(
                  color: textPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  exercise.description,
                  style: TextStyle(color: textSecondaryColor, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
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

  String _estimateTotalTime() {
    // Since we no longer have exercise durations, we'll just use workout duration
    return widget.workout.duration;
  }
}
