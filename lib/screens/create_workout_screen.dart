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

  // Update exercise sets or reps
  void _updateExerciseSetsReps(int index, {int? sets, int? reps}) {
    setState(() {
      final exercise = _exercises[index];
      _exercises[index] = Exercise(
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
        themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.workout == null ? 'Create Workout' : 'Edit Workout',
          style: TextStyle(color: textPrimaryColor),
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
            TextButton(
              onPressed: _saveWorkout,
              child: const Text('SAVE'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: textPrimaryColor),
                ),
              )
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Workout image picker
                    WorkoutImagePicker(
                      imageUrl: _imageUrl,
                      isUploading: _isUploadingImage,
                      onImageSelected: _handleImageSelected,
                    ),
                    const SizedBox(height: 16),

                    // Workout name
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: textPrimaryColor),
                      decoration: InputDecoration(
                        labelText: 'Workout Name',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(color: textSecondaryColor),
                        fillColor: inputFillColor,
                        filled: themeProvider.isDarkMode,
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
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(color: textSecondaryColor),
                        fillColor: inputFillColor,
                        filled: themeProvider.isDarkMode,
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
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(color: textSecondaryColor),
                        fillColor: inputFillColor,
                        filled: themeProvider.isDarkMode,
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
                    const SizedBox(height: 16),

                    // Row for difficulty and duration
                    Row(
                      children: [
                        // Difficulty dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedDifficulty,
                            style: TextStyle(color: textPrimaryColor),
                            dropdownColor: cardBackgroundColor,
                            decoration: InputDecoration(
                              labelText: 'Difficulty',
                              border: const OutlineInputBorder(),
                              labelStyle: TextStyle(color: textSecondaryColor),
                              fillColor: inputFillColor,
                              filled: themeProvider.isDarkMode,
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
                        ),
                        const SizedBox(width: 16),

                        // Duration input
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            style: TextStyle(color: textPrimaryColor),
                            decoration: InputDecoration(
                              labelText: 'Duration',
                              border: const OutlineInputBorder(),
                              hintText: 'e.g. 30 min',
                              hintStyle: TextStyle(color: textSecondaryColor),
                              labelStyle: TextStyle(color: textSecondaryColor),
                              fillColor: inputFillColor,
                              filled: themeProvider.isDarkMode,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Calories input
                    TextFormField(
                      controller: _caloriesController,
                      style: TextStyle(color: textPrimaryColor),
                      decoration: InputDecoration(
                        labelText: 'Calories Burned',
                        border: const OutlineInputBorder(),
                        hintText: 'e.g. 300',
                        hintStyle: TextStyle(color: textSecondaryColor),
                        labelStyle: TextStyle(color: textSecondaryColor),
                        fillColor: inputFillColor,
                        filled: themeProvider.isDarkMode,
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
                    const SizedBox(height: 16),

                    // Public visibility toggle (only visible to admins)
                    if (_isAdminMode)
                      SwitchListTile(
                        title: Text(
                          'Make Public (Visible to All Users)',
                          style: TextStyle(color: textPrimaryColor),
                        ),
                        value: _isPublic,
                        activeColor: AppColors.primary,
                        onChanged: (bool value) {
                          setState(() {
                            _isPublic = value;
                          });
                        },
                        secondary: const Icon(
                          Icons.public,
                          color: AppColors.primary,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Exercise section
                    Text(
                      'Exercises',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_exercises.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No exercises added yet',
                            style: TextStyle(color: textSecondaryColor),
                          ),
                        ),
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: _reorderExercises,
                        itemCount: _exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _exercises[index];
                          return Card(
                            key: Key('exercise_${exercise.id}_$index'),
                            color: cardBackgroundColor,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Exercise icon and drag handle
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: const Icon(
                                          Icons.fitness_center,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Exercise name and muscle groups
                                      Expanded(
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
                                            Text(
                                              exercise.targetMuscles.join(', '),
                                              style: TextStyle(
                                                color: textSecondaryColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Delete button
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _removeExercise(index),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Sets and reps controls
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Sets control
                                      Row(
                                        children: [
                                          Text(
                                            'Sets: ',
                                            style: TextStyle(
                                              color: textSecondaryColor,
                                              fontSize: 14,
                                            ),
                                          ),
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
                                        ],
                                      ),

                                      // Reps control
                                      Row(
                                        children: [
                                          Text(
                                            'Reps: ',
                                            style: TextStyle(
                                              color: textSecondaryColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                          _buildNumberControl(
                                            exercise.reps,
                                            (value) {
                                              if (value >= 1 && value <= 50) {
                                                _updateExerciseSetsReps(
                                                  index,
                                                  reps: value,
                                                );
                                              }
                                            },
                                            min: 1,
                                            max: 50,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 16),

                    // Add exercise button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Exercise'),
                      onPressed: () => _showExerciseSelector(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // Show bottom sheet to select exercises
  void _showExerciseSelector() {
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
                  filteredExercises =
                      _availableExercises
                          .where(
                            (exercise) =>
                                exercise.name.toLowerCase().contains(
                                  query.toLowerCase(),
                                ) ||
                                exercise.targetMuscles.any(
                                  (muscle) => muscle.toLowerCase().contains(
                                    query.toLowerCase(),
                                  ),
                                ),
                          )
                          .toList();
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
