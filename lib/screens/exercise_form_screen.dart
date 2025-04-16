import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exercise.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';
import '../widgets/exercise_image_picker.dart';

class ExerciseFormScreen extends StatefulWidget {
  final Exercise? exercise; // For editing an existing exercise

  const ExerciseFormScreen({Key? key, this.exercise}) : super(key: key);

  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _durationController = TextEditingController();

  String _selectedDifficulty = 'intermediate';
  final List<String> _difficulties = ['beginner', 'intermediate', 'advanced'];

  List<String> _selectedEquipment = ['None'];
  final List<String> _equipmentOptions = [
    'None',
    'Dumbbells',
    'Barbell',
    'Kettlebell',
    'Resistance bands',
    'Yoga mat',
    'Pull-up bar',
    'Bench',
    'Exercise ball',
    'Jump rope',
    'Foam roller',
  ];

  List<String> _selectedMuscles = [];
  final List<String> _muscleGroups = [
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Abs',
    'Quads',
    'Hamstrings',
    'Glutes',
    'Calves',
    'Cardio',
    'Full body',
  ];

  // Image handling
  XFile? _selectedImage;
  String? _imageUrl;
  bool _isUploadingImage = false;
  final _storageService = StorageService();

  bool _isPublic = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
    _checkAdminMode();
  }

  void _initializeFormData() {
    final exercise = widget.exercise;

    if (exercise != null) {
      // Editing an existing exercise
      _nameController.text = exercise.name;
      _descriptionController.text = exercise.description;
      _setsController.text = exercise.sets.toString();
      _repsController.text = exercise.reps.toString();
      _durationController.text = exercise.duration;

      _selectedDifficulty = exercise.difficulty;
      _selectedEquipment = exercise.equipment.isNotEmpty
          ? List.from(exercise.equipment)
          : ['None'];
      _selectedMuscles = List.from(exercise.targetMuscles);

      _imageUrl = exercise.imageUrl.isNotEmpty ? exercise.imageUrl : null;
      _isPublic = exercise.isPublic;
    } else {
      // Creating a new exercise - set defaults
      _setsController.text = '3';
      _repsController.text = '12';
      _durationController.text = '45s';
    }
  }

  Future<void> _checkAdminMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAdmin = prefs.getBool('admin_mode') ?? false;
      if (_isAdmin && widget.exercise == null) {
        _isPublic = true;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _handleImageSelected(XFile image) async {
    setState(() {
      _selectedImage = image;
      _isUploadingImage = true;
    });

    try {
      final url = await _storageService.uploadExerciseImage(image);

      // Make sure we're still mounted before updating state
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isUploadingImage = false;
        });

        // Force rebuild of the ExerciseImagePicker widget
        if (url != null) {
          // Add a small delay to ensure the UI updates
          await Future.delayed(const Duration(milliseconds: 100));
          setState(() {
            // This second setState forces a rebuild after the image is loaded
          });
        } else {
          _showErrorMessage('Failed to upload image. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        _showErrorMessage('Error uploading image: ${e.toString()}');
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if muscle groups are selected
    if (_selectedMuscles.isEmpty) {
      _showErrorMessage('Please select at least one target muscle group');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Clean equipment list
      final equipment =
          _selectedEquipment.contains('None') && _selectedEquipment.length == 1
              ? ['None']
              : _selectedEquipment.where((e) => e != 'None').toList();

      // Create exercise object
      final exercise = Exercise(
        id: widget.exercise?.id ?? 'new',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        sets: int.parse(_setsController.text.trim()),
        reps: int.parse(_repsController.text.trim()),
        duration: _durationController.text.trim(),
        imageUrl: _imageUrl ?? '',
        equipment: equipment,
        targetMuscles: _selectedMuscles,
        difficulty: _selectedDifficulty,
        isPublic: _isPublic,
        createdBy: widget.exercise?.createdBy,
      );

      if (widget.exercise == null) {
        // Creating new exercise
        final newExercise = await Exercise.createExercise(exercise);
        if (newExercise == null) throw Exception('Failed to create exercise');
      } else {
        // Updating existing exercise
        final updatedExercise = await exercise.updateExercise();
        if (updatedExercise == null)
          throw Exception('Failed to update exercise');
      }

      // Return to previous screen with success
      Navigator.of(context).pop(true);
    } catch (e) {
      _showErrorMessage('Error saving exercise: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteExercise() async {
    if (widget.exercise == null) return;

    setState(() => _isDeleting = true);

    try {
      final result = await Exercise.deleteExercise(widget.exercise!.id);
      if (result) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exercise deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to delete exercise');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting exercise: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: const Text(
          'Are you sure you want to delete this exercise? This action cannot be undone. '
          'Note: If this exercise is used in any workouts, those references will be removed.',
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
      await _deleteExercise();
    }
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

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.exercise == null ? 'Create Exercise' : 'Edit Exercise'),
        actions: [
          if (_isSaving || _isDeleting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            if (widget.exercise != null)
              IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.red,
                onPressed: _confirmDelete,
              ),
            TextButton(
              onPressed: _saveExercise,
              child: const Text('SAVE'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Exercise Image
            const Text(
              'Exercise Image',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ExerciseImagePicker(
              currentImageUrl: _imageUrl,
              onImageSelected: _handleImageSelected,
              isLoading: _isUploadingImage,
            ),
            const SizedBox(height: 16),

            // Exercise Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Exercise Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'Describe how to perform this exercise...',
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

            // Sets, Reps and Duration Row
            Row(
              children: [
                // Sets
                Expanded(
                  child: TextFormField(
                    controller: _setsController,
                    decoration: const InputDecoration(
                      labelText: 'Sets',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Reps
                Expanded(
                  child: TextFormField(
                    controller: _repsController,
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Duration
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. 45s',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Difficulty Level
            const Text(
              'Difficulty Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _difficulties.map((difficulty) {
                return ChoiceChip(
                  label: Text(_capitalizeFirstLetter(difficulty)),
                  selected: _selectedDifficulty == difficulty,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedDifficulty = difficulty;
                      });
                    }
                  },
                  selectedColor: AppColors.primary.withOpacity(0.7),
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: _selectedDifficulty == difficulty
                        ? Colors.white
                        : Colors.black,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Equipment
            const Text(
              'Equipment Required',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _equipmentOptions.map((equipment) {
                final isSelected = _selectedEquipment.contains(equipment);
                // If "None" is selected, disable other options
                final isDisabled = equipment != 'None' &&
                    _selectedEquipment.contains('None') &&
                    _selectedEquipment.length == 1;
                // If any other option is selected, disable "None"
                final isNoneDisabled = equipment == 'None' &&
                    _selectedEquipment.any((e) => e != 'None');

                return FilterChip(
                  label: Text(equipment),
                  selected: isSelected,
                  onSelected: (isDisabled || isNoneDisabled)
                      ? null
                      : (selected) {
                          setState(() {
                            if (selected) {
                              _selectedEquipment.add(equipment);
                            } else {
                              _selectedEquipment.remove(equipment);
                              // If no equipment is selected, default back to "None"
                              if (_selectedEquipment.isEmpty) {
                                _selectedEquipment.add('None');
                              }
                            }
                          });
                        },
                  selectedColor: AppColors.primary.withOpacity(0.7),
                  backgroundColor: (isDisabled || isNoneDisabled)
                      ? Colors.grey.shade300
                      : Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Target Muscle Groups
            const Text(
              'Target Muscle Groups',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _muscleGroups.map((muscle) {
                final isSelected = _selectedMuscles.contains(muscle);
                return FilterChip(
                  label: Text(muscle),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedMuscles.add(muscle);
                      } else {
                        _selectedMuscles.remove(muscle);
                      }
                    });
                  },
                  selectedColor: AppColors.primary.withOpacity(0.7),
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Public/Private Toggle
            SwitchListTile(
              title: const Text('Make exercise public'),
              subtitle: const Text('Public exercises can be used by all users'),
              value: _isPublic,
              onChanged: (value) {
                setState(() {
                  _isPublic = value;
                });
              },
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('SAVE EXERCISE'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
