import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/workout_image_picker.dart';
import '../widgets/message_overlay.dart';
import '../services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'exercise_form_screen.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final Workout? workout;

  const CreateWorkoutScreen({Key? key, this.workout}) : super(key: key);

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'Strength';
  String _selectedDifficulty = 'Intermediate';
  final _durationController = TextEditingController(text: '30 min');
  final _caloriesController = TextEditingController(text: '300');
  bool _isPublic = false; // Added for public visibility
  bool _isAdminMode = false; // Added to check admin mode

  // Image related properties
  String? _imageUrl;
  bool _isUploadingImage = false;
  final _storageService = StorageService();

  // Exercise list
  List<Exercise> _exercises = [];
  List<Exercise> _availableExercises = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Tabs
  int _currentTab = 0;

  // List of workout types
  final List<String> _workoutTypes = [
    'Strength',
    'Cardio',
    'Yoga',
    'HIIT',
    'Recovery',
  ];

  // List of difficulty levels
  final List<String> _difficultyLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();

    // If editing an existing workout, initialize form data
    if (widget.workout != null) {
      _nameController.text = widget.workout!.name;
      _descriptionController.text = widget.workout!.description;
      _selectedType = widget.workout!.type;
      _selectedDifficulty = widget.workout!.difficulty;
      _durationController.text = widget.workout!.duration;
      _caloriesController.text = widget.workout!.caloriesBurned.toString();
      _exercises = List.from(widget.workout!.exercises);
      _isPublic = widget.workout!.isPublic;
      _imageUrl = widget.workout!.imageUrl;
    }

    // Check for admin mode
    _checkAdminMode();

    // Fetch available exercises
    _fetchExercises();
  }

  // Check if admin mode is enabled
  Future<void> _checkAdminMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAdminMode = prefs.getBool('admin_mode') ?? false;
      // If in admin mode and creating a new workout, set public by default
      if (_isAdminMode && widget.workout == null) {
        _isPublic = true;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  // Fetch available exercises from database
  Future<void> _fetchExercises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final exercises = await Exercise.fetchExercises();
      setState(() {
        _availableExercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load exercises: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Save workout to database
  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate() || _exercises.isEmpty) {
      MessageOverlay.showWarning(
        context,
        message: 'Please complete all fields and add at least one exercise',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('You must be logged in to create a workout');
      }

      // Create workout object
      final workout = Workout(
        id: widget.workout?.id ?? 'new',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        imageUrl:
            _imageUrl ?? 'assets/images/workout1.png', // Using default image
        duration: _durationController.text.trim(),
        difficulty: _selectedDifficulty,
        caloriesBurned: int.tryParse(_caloriesController.text.trim()) ?? 300,
        exercises: _exercises,
        isPublic: _isPublic, // Use the isPublic flag
        createdBy: userId,
      );

      // Save to database
      if (widget.workout == null) {
        await Workout.createWorkout(workout);
      } else {
        await workout.updateWorkout();
      }

      // Return to previous screen on success
      if (mounted) {
        MessageOverlay.showSuccess(
          context,
          message:
              'Workout ${widget.workout == null ? 'created' : 'updated'} successfully!',
          actionLabel: 'VIEW',
          onAction: () {
            // Navigate back to the workout details or list
            Navigator.pop(context, true);
          },
        );

        // Short delay before popping to allow the user to see the message
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      MessageOverlay.showError(
        context,
        message: 'Error saving workout: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Add an exercise to the workout
  void _addExercise(Exercise exercise) {
    setState(() {
      // Add a copy to avoid modifying the original
      _exercises.add(
        Exercise(
          id: exercise.id,
          name: exercise.name,
          description: exercise.description,
          category: exercise.category,
          sets: exercise.sets,
          reps: exercise.reps,
          imageUrl: exercise.imageUrl,
          targetMuscles: exercise.targetMuscles,
          difficulty: exercise.difficulty,
          isPublic: exercise.isPublic,
          createdBy: exercise.createdBy,
        ),
      );
    });
  }

  // Update exercise sets
  void _updateExerciseSetsReps(int index, {int? sets}) {
    setState(() {
      final exercise = _exercises[index];
      _exercises[index] = Exercise(
        id: exercise.id,
        name: exercise.name,
        description: exercise.description,
        category: exercise.category,
        sets: sets ?? exercise.sets,
        reps: exercise.reps, // Keep existing reps, as they're determined by AI
        imageUrl: exercise.imageUrl,
        targetMuscles: exercise.targetMuscles,
        difficulty: exercise.difficulty,
        isPublic: exercise.isPublic,
        createdBy: exercise.createdBy,
      );
    });
  }

  // Remove an exercise from the workout
  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  // Reorder exercises in the workout
  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
  }

  // Handle image selection
  Future<void> _handleImageSelected(XFile imageFile) async {
    setState(() => _isUploadingImage = true);

    try {
      // Upload the image to storage
      final url = await _storageService.uploadWorkoutImage(imageFile);

      // Update state with the new image URL
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        MessageOverlay.showError(
          context,
          message: 'Error uploading image: ${e.toString()}',
        );
      }
    }
  }

  // Helper function to build a +/- control for numbers
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    final inputFillColor =
        themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.workout == null ? 'Create Workout' : 'Edit Workout',
          style: TextStyle(
            color: textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryColor),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveWorkout,
              icon: const Icon(Icons.save_rounded),
              label: const Text('SAVE'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(color: textSecondaryColor),
                    ),
                  ],
                ),
              )
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: textPrimaryColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _fetchExercises,
                      child: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: cardBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildTab(0, 'Details', Icons.info_outline),
                        _buildTab(1, 'Exercises', Icons.fitness_center),
                      ],
                    ),
                  ),

                  // Content based on selected tab
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child:
                          _currentTab == 0
                              ? _buildDetailsTab(
                                textPrimaryColor,
                                textSecondaryColor,
                                inputFillColor,
                                cardBackgroundColor,
                              )
                              : _buildExercisesTab(
                                textPrimaryColor,
                                textSecondaryColor,
                                cardBackgroundColor,
                              ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor =
        _currentTab == index
            ? AppColors.primary
            : themeProvider.isDarkMode
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    _currentTab == index
                        ? AppColors.primary
                        : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight:
                      _currentTab == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab(
    Color textPrimaryColor,
    Color textSecondaryColor,
    Color inputFillColor,
    Color cardBackgroundColor,
  ) {
    return ListView(
      padding: const EdgeInsets.all(0), // Removed padding from ListView
      children: [
        // Workout image picker - now with padding and rounded corners
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 1,
            shadowColor: Colors.black38,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workout Image',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  WorkoutImagePicker(
                    imageUrl: _imageUrl,
                    isUploading: _isUploadingImage,
                    onImageSelected: _handleImageSelected,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Padding container for the rest of the form
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Card
              Card(
                elevation: 1,
                shadowColor: Colors.black38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Workout name
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: textPrimaryColor),
                        decoration: InputDecoration(
                          labelText: 'Workout Name',
                          prefixIcon: const Icon(
                            Icons.title,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          labelStyle: TextStyle(color: textSecondaryColor),
                          fillColor: inputFillColor,
                          filled: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Workout description
                      TextFormField(
                        controller: _descriptionController,
                        style: TextStyle(color: textPrimaryColor),
                        decoration: InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 64),
                            child: const Icon(
                              Icons.description,
                              color: AppColors.primary,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          labelStyle: TextStyle(color: textSecondaryColor),
                          fillColor: inputFillColor,
                          filled: true,
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Workout type dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        style: TextStyle(color: textPrimaryColor),
                        dropdownColor: cardBackgroundColor,
                        decoration: InputDecoration(
                          labelText: 'Workout Type',
                          prefixIcon: const Icon(
                            Icons.fitness_center,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          labelStyle: TextStyle(color: textSecondaryColor),
                          fillColor: inputFillColor,
                          filled: true,
                        ),
                        items:
                            _workoutTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Additional Details Card
              Card(
                elevation: 1,
                shadowColor: Colors.black38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Difficulty dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedDifficulty,
                        style: TextStyle(color: textPrimaryColor),
                        dropdownColor: cardBackgroundColor,
                        decoration: InputDecoration(
                          labelText: 'Difficulty',
                          prefixIcon: const Icon(
                            Icons.trending_up,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          labelStyle: TextStyle(color: textSecondaryColor),
                          fillColor: inputFillColor,
                          filled: true,
                        ),
                        items:
                            _difficultyLevels.map((level) {
                              return DropdownMenuItem(
                                value: level,
                                child: Text(level),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDifficulty = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Duration and calories in a row
                      Row(
                        children: [
                          // Duration input
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              style: TextStyle(color: textPrimaryColor),
                              decoration: InputDecoration(
                                labelText: 'Duration',
                                prefixIcon: const Icon(
                                  Icons.timer,
                                  color: AppColors.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                hintText: 'e.g. 30 min',
                                hintStyle: TextStyle(color: textSecondaryColor),
                                labelStyle: TextStyle(
                                  color: textSecondaryColor,
                                ),
                                fillColor: inputFillColor,
                                filled: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Calories input
                          Expanded(
                            child: TextFormField(
                              controller: _caloriesController,
                              style: TextStyle(color: textPrimaryColor),
                              decoration: InputDecoration(
                                labelText: 'Calories',
                                prefixIcon: const Icon(
                                  Icons.local_fire_department,
                                  color: AppColors.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                hintText: 'e.g. 300',
                                hintStyle: TextStyle(color: textSecondaryColor),
                                labelStyle: TextStyle(
                                  color: textSecondaryColor,
                                ),
                                fillColor: inputFillColor,
                                filled: true,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      // Public visibility toggle (only visible to admins)
                      if (_isAdminMode) ...[
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: inputFillColor,
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: SwitchListTile(
                            title: Text(
                              'Make Public (Visible to All Users)',
                              style: TextStyle(color: textPrimaryColor),
                            ),
                            subtitle: Text(
                              'When enabled, all users will be able to see this workout',
                              style: TextStyle(
                                color: textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                            value: _isPublic,
                            activeColor: AppColors.primary,
                            onChanged: (bool value) {
                              setState(() {
                                _isPublic = value;
                              });
                            },
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.public,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExercisesTab(
    Color textPrimaryColor,
    Color textSecondaryColor,
    Color cardBackgroundColor,
  ) {
    return Column(
      children: [
        // Add exercise button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
            onPressed: () => _showExerciseSelector(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size.fromHeight(54),
              elevation: 1,
            ),
          ),
        ),

        // Exercise count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Exercises (${_exercises.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
              const Spacer(),
              if (_exercises.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.drag_handle,
                      size: 16,
                      color: textSecondaryColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Drag to reorder',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: textSecondaryColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Exercise list
        Expanded(
          child:
              _exercises.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: textSecondaryColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No exercises added yet',
                          style: TextStyle(
                            color: textSecondaryColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the button above to add exercises',
                          style: TextStyle(
                            color: textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () => _showExerciseSelector(),
                          icon: const Icon(Icons.add),
                          label: const Text('Browse Exercises'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    onReorder: _reorderExercises,
                    itemCount: _exercises.length,
                    buildDefaultDragHandles: false,
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (BuildContext context, Widget? child) {
                          return Material(
                            elevation: 4.0,
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: child,
                          );
                        },
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final exercise = _exercises[index];
                      return Card(
                        key: Key('exercise_${exercise.id}_$index'),
                        color: cardBackgroundColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Colors.grey.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                        elevation: 1,
                        shadowColor: Colors.black38,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Exercise icon with long-press drag handle
                                  ReorderableDragStartListener(
                                    index: index,
                                    enabled: true,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.fitness_center,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Exercise name and muscle groups - clickable to edit
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _editExercise(exercise),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exercise.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: textPrimaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (exercise.targetMuscles.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                exercise.targetMuscles.join(
                                                  ', ',
                                                ),
                                                style: TextStyle(
                                                  color: textSecondaryColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Delete button
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red.shade300,
                                    ),
                                    onPressed: () => _removeExercise(index),
                                    tooltip: 'Remove exercise',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Divider between exercise info and controls
                              Divider(
                                height: 1,
                                thickness: 0.5,
                                color: Colors.grey.withOpacity(0.2),
                              ),

                              const SizedBox(height: 12),

                              // Sets control
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.primary.withOpacity(
                                          0.3,
                                        ),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: const Text(
                                      'Sets',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildNumberControl(
                                    exercise.sets,
                                    (value) {
                                      if (value >= 1 && value <= 10) {
                                        _updateExerciseSetsReps(
                                          index,
                                          sets: value,
                                        );
                                      }
                                    },
                                    min: 1,
                                    max: 10,
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.amber.withOpacity(0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.auto_awesome,
                                          size: 12,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'AI Reps',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                            color: Colors.amber.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  // Show bottom sheet to select exercises (reusing the same implementation as before)
  void _showExerciseSelector() {
    // ... existing implementation
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
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
    final inputFillColor =
        themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50;

    // For exercise search functionality
    TextEditingController searchController = TextEditingController();
    List<Exercise> filteredExercises = List.from(_availableExercises);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Function to filter exercises based on search query
            void filterExercises(String query) {
              setState(() {
                if (query.isEmpty) {
                  filteredExercises = List.from(_availableExercises);
                } else {
                  final normalizedQuery = query.toLowerCase();
                  filteredExercises =
                      _availableExercises.where((exercise) {
                        // Check if exercise name contains query
                        final nameMatch = exercise.name.toLowerCase().contains(
                          normalizedQuery,
                        );

                        // Check if any target muscle contains query
                        final muscleMatch = exercise.targetMuscles.any(
                          (muscle) =>
                              muscle.toLowerCase().contains(normalizedQuery),
                        );

                        // Check if difficulty contains query
                        final difficultyMatch = exercise.difficulty
                            .toLowerCase()
                            .contains(normalizedQuery);

                        // Check if description contains query
                        final descriptionMatch = exercise.description
                            .toLowerCase()
                            .contains(normalizedQuery);

                        return nameMatch ||
                            muscleMatch ||
                            difficultyMatch ||
                            descriptionMatch;
                      }).toList();

                  // Sort by relevance - items with matching names first, followed by target muscles
                  filteredExercises.sort((a, b) {
                    // Name matches are highest priority
                    final aNameMatch = a.name.toLowerCase().contains(
                      normalizedQuery,
                    );
                    final bNameMatch = b.name.toLowerCase().contains(
                      normalizedQuery,
                    );

                    if (aNameMatch && !bNameMatch) return -1;
                    if (!aNameMatch && bNameMatch) return 1;

                    // Target muscle matches are second priority
                    final aTargetMatch = a.targetMuscles.any(
                      (m) => m.toLowerCase().contains(normalizedQuery),
                    );
                    final bTargetMatch = b.targetMuscles.any(
                      (m) => m.toLowerCase().contains(normalizedQuery),
                    );

                    if (aTargetMatch && !bTargetMatch) return -1;
                    if (!aTargetMatch && bTargetMatch) return 1;

                    // If both have similar relevance, sort alphabetically
                    return a.name.compareTo(b.name);
                  });
                }
              });
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: cardBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select Exercise',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimaryColor,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: textPrimaryColor),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      // Search bar for exercises
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          controller: searchController,
                          onChanged: filterExercises,
                          style: TextStyle(color: textPrimaryColor),
                          decoration: InputDecoration(
                            hintText: 'Search by name or muscle group...',
                            hintStyle: TextStyle(color: textSecondaryColor),
                            prefixIcon: Icon(
                              Icons.search,
                              color: textSecondaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: inputFillColor,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: ElevatedButton.icon(
                          onPressed: () => _createNewExercise(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Exercise'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                      const Divider(),
                      // Display filtered results count
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          '${filteredExercises.length} exercises found',
                          style: TextStyle(
                            color: textSecondaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            filteredExercises.isEmpty
                                ? Center(
                                  child: Text(
                                    'No exercises found matching your search',
                                    style: TextStyle(color: textSecondaryColor),
                                  ),
                                )
                                : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  itemCount: filteredExercises.length,
                                  itemBuilder: (context, i) {
                                    final alt = filteredExercises[i];
                                    return ListTile(
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: AppColors.primary.withOpacity(
                                            0.1,
                                          ),
                                        ),
                                        child:
                                            alt.imageUrl.isNotEmpty
                                                ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    alt.imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => const Icon(
                                                          Icons.fitness_center,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                  ),
                                                )
                                                : const Icon(
                                                  Icons.fitness_center,
                                                  color: AppColors.primary,
                                                ),
                                      ),
                                      title: Text(
                                        alt.name,
                                        style: TextStyle(
                                          color: textPrimaryColor,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${alt.sets} sets • ${alt.reps} reps\n${alt.targetMuscles.join(", ")}',
                                        style: TextStyle(
                                          color: textSecondaryColor,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: AppColors.primary,
                                            ),
                                            onPressed: () => _editExercise(alt),
                                            tooltip: 'Edit Exercise',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle,
                                              color: AppColors.primary,
                                            ),
                                            onPressed: () {
                                              _addExercise(alt);
                                              Navigator.of(context).pop();
                                            },
                                            tooltip: 'Add to Workout',
                                          ),
                                        ],
                                      ),
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
      },
    );
  }

  // Create a new exercise
  Future<void> _createNewExercise() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const ExerciseFormScreen()),
    );

    // If exercise was created successfully, refresh the list
    if (result == true) {
      await _fetchExercises();
    }
  }

  // Edit an existing exercise
  Future<void> _editExercise(Exercise exercise) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ExerciseFormScreen(exercise: exercise),
      ),
    );

    // If exercise was updated successfully, refresh the list
    if (result == true) {
      await _fetchExercises();
    }
  }
}
