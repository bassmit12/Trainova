import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../widgets/message_overlay.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _dataLoaded = false;

  // Text controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  // User profile data
  String _name = '';
  double _weight = 70.0;
  double _height = 170.0;
  String _weightUnit = 'kg';
  String _heightUnit = 'cm';
  String _fitnessGoal = 'weight_loss';
  int _workoutsPerWeek = 3;
  List<String> _preferredWorkoutTypes = [];
  String _experienceLevel = 'beginner';

  // Available options for selections
  final List<String> _fitnessGoals = [
    'weight_loss',
    'muscle_gain',
    'endurance',
    'flexibility',
    'general_fitness'
  ];

  final List<String> _experienceLevels = [
    'beginner',
    'intermediate',
    'advanced'
  ];

  final List<Map<String, String>> _workoutTypes = [
    {'id': 'cardio', 'name': 'Cardio'},
    {'id': 'strength', 'name': 'Strength Training'},
    {'id': 'hiit', 'name': 'HIIT'},
    {'id': 'yoga', 'name': 'Yoga'},
    {'id': 'pilates', 'name': 'Pilates'},
    {'id': 'calisthenics', 'name': 'Calisthenics'},
    {'id': 'functional', 'name': 'Functional Training'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Force a refresh of user data from Supabase
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.getCurrentUserProfile(forceRefresh: true);
      final user = authService.currentUser;

      if (user != null) {
        // Set values from database with fallbacks if null
        final weight = user.weight ?? 70.0;
        final height = user.height ?? 170.0;

        setState(() {
          // Set model values
          _name = user.name ?? '';
          _weight = weight;
          _height = height;
          _weightUnit = user.weightUnit ?? 'kg';
          _heightUnit = user.heightUnit ?? 'cm';
          _fitnessGoal = user.fitnessGoal ?? 'weight_loss';
          _workoutsPerWeek = user.workoutsPerWeek ?? 3;
          _preferredWorkoutTypes = user.preferredWorkoutTypes ?? [];
          _experienceLevel = user.experienceLevel ?? 'beginner';

          // Set controller values
          _nameController.text = _name;
          _weightController.text = weight.toStringAsFixed(1);
          _heightController.text = height.toStringAsFixed(1);

          _dataLoaded = true;
        });

        print('User data loaded - weight: $weight, height: $height');
      }
    } catch (e) {
      print('Error loading user data: $e');
      MessageOverlay.showError(
        context,
        message: 'Failed to load profile data: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper methods for text formatting
  String _formatGoalText(String goal) {
    return goal
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? word.substring(0, 1).toUpperCase() + word.substring(1)
            : '')
        .join(' ');
  }

  String _formatExperienceText(String experience) {
    if (experience.isEmpty) return '';
    return experience.substring(0, 1).toUpperCase() + experience.substring(1);
  }

  Future<void> _saveUserProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Debug logging
      print('Updating profile with weight: $_weight, height: $_height');

      // Create updated user with form data
      final updatedUser = currentUser.copyWith(
        name: _name.isEmpty ? currentUser.name : _name,
        weight: _weight,
        height: _height,
        weightUnit: _weightUnit,
        heightUnit: _heightUnit,
        fitnessGoal: _fitnessGoal,
        workoutsPerWeek: _workoutsPerWeek,
        preferredWorkoutTypes: _preferredWorkoutTypes,
        experienceLevel: _experienceLevel,
      );

      // Save to Supabase profiles table
      final client = Supabase.instance.client;
      final updateData = {
        'id': updatedUser.id,
        'full_name': updatedUser.name,
        'avatar_url': updatedUser.avatarUrl,
        'weight': updatedUser.weight,
        'height': updatedUser.height,
        'weight_unit': updatedUser.weightUnit,
        'height_unit': updatedUser.heightUnit,
        'fitness_goal': updatedUser.fitnessGoal,
        'workouts_per_week': updatedUser.workoutsPerWeek,
        'preferred_workout_types': updatedUser.preferredWorkoutTypes,
        'experience_level': updatedUser.experienceLevel,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Debug print the data being sent to Supabase
      print('Sending to Supabase: $updateData');

      await client.from('profiles').upsert(updateData);

      // Refresh user data in authService
      await authService.getCurrentUserProfile();

      // Show success message and go back
      if (mounted) {
        MessageOverlay.showSuccess(
          context,
          message: 'Profile updated successfully',
        );

        // Pop and trigger refresh on the ProfileScreen
        Navigator.of(context)
            .pop(true); // Pass true to indicate successful update
      }
    } catch (e) {
      if (mounted) {
        MessageOverlay.showError(
          context,
          message: 'Error updating profile: ${e.toString()}',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: (_isLoading || !_dataLoaded) ? null : _saveUserProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_dataLoaded
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load profile data'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information Section
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: "Display Name",
                            hintText: _name.isEmpty ? "Enter your name" : _name,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _name = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Weight field with unit selector
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _weightController,
                                decoration: InputDecoration(
                                  labelText: "Weight",
                                  hintText:
                                      "${_weight.toStringAsFixed(1)} $_weightUnit",
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your weight';
                                  }
                                  final weight = double.tryParse(value);
                                  if (weight == null || weight <= 0) {
                                    return 'Please enter a valid weight';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  final parsed = double.tryParse(value);
                                  if (parsed != null && parsed > 0) {
                                    setState(() {
                                      _weight = parsed;
                                      print(
                                          'Weight updated to: $_weight'); // Debug log
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                value: _weightUnit,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'kg', child: Text('kg')),
                                  DropdownMenuItem(
                                      value: 'lbs', child: Text('lbs')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _weightUnit = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Height field with unit selector
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _heightController,
                                decoration: InputDecoration(
                                  labelText: "Height",
                                  hintText:
                                      "${_height.toStringAsFixed(1)} $_heightUnit",
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your height';
                                  }
                                  final height = double.tryParse(value);
                                  if (height == null || height <= 0) {
                                    return 'Please enter a valid height';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  final parsed = double.tryParse(value);
                                  if (parsed != null && parsed > 0) {
                                    setState(() {
                                      _height = parsed;
                                      print(
                                          'Height updated to: $_height'); // Debug log
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: DropdownButtonFormField<String>(
                                value: _heightUnit,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'cm', child: Text('cm')),
                                  DropdownMenuItem(
                                      value: 'ft', child: Text('ft')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _heightUnit = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Fitness Goals Section
                        const Text(
                          'Fitness Goals',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Fitness goal selector
                        const Text(
                          "Primary fitness goal",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(_fitnessGoals.length, (index) {
                          final goal = _fitnessGoals[index];
                          return RadioListTile<String>(
                            title: Text(_formatGoalText(goal)),
                            value: goal,
                            groupValue: _fitnessGoal,
                            activeColor: AppColors.primary,
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  _fitnessGoal = value;
                                });
                              }
                            },
                          );
                        }),
                        const SizedBox(height: 16),

                        // Workouts per week
                        const Text(
                          "Weekly workout frequency",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _workoutsPerWeek.toDouble(),
                          min: 1,
                          max: 7,
                          divisions: 6,
                          label: _workoutsPerWeek.toString(),
                          activeColor: AppColors.primary,
                          inactiveColor:
                              AppColors.primaryLight.withOpacity(0.3),
                          onChanged: (value) {
                            setState(() {
                              _workoutsPerWeek = value.round();
                            });
                          },
                        ),
                        Center(
                          child: Text(
                            "$_workoutsPerWeek times per week",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Experience and Preferences Section
                        const Text(
                          'Experience & Preferences',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Experience level
                        const Text(
                          "Fitness experience level",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(_experienceLevels.length, (index) {
                          final level = _experienceLevels[index];
                          return RadioListTile<String>(
                            title: Text(_formatExperienceText(level)),
                            value: level,
                            groupValue: _experienceLevel,
                            activeColor: AppColors.primary,
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  _experienceLevel = value;
                                });
                              }
                            },
                          );
                        }),
                        const SizedBox(height: 16),

                        // Workout preferences
                        const Text(
                          "Preferred workout types",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(_workoutTypes.length, (index) {
                          final workout = _workoutTypes[index];
                          final isSelected =
                              _preferredWorkoutTypes.contains(workout['id']);

                          return CheckboxListTile(
                            title: Text(workout['name']!),
                            value: isSelected,
                            activeColor: AppColors.primary,
                            onChanged: (bool? value) {
                              if (value == true) {
                                setState(() {
                                  _preferredWorkoutTypes.add(workout['id']!);
                                });
                              } else {
                                setState(() {
                                  _preferredWorkoutTypes.remove(workout['id']!);
                                });
                              }
                            },
                          );
                        }),

                        if (_preferredWorkoutTypes.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Please select at least one workout type",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        const SizedBox(height: 40),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveUserProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }
}
