import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // User profile data
  String _name = '';
  double _weight = 70;
  double _height = 170;
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

  // Helper methods for text formatting
  String _formatGoalText(String goal) {
    return goal
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatExperienceText(String experience) {
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
        isProfileComplete: true,
      );

      // Save to Supabase profiles table
      final client = Supabase.instance.client;
      await client.from('profiles').upsert({
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
        'is_profile_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Refresh user data in authService
      await authService.getCurrentUserProfile();

      // Navigate to main app screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveUserProfile();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Pre-populate with existing user data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user != null) {
        setState(() {
          _name = user.name ?? '';
          _weight = user.weight ?? 70.0;
          _height = user.height ?? 170.0;
          _weightUnit = user.weightUnit ?? 'kg';
          _heightUnit = user.heightUnit ?? 'cm';
          _fitnessGoal = user.fitnessGoal ?? 'weight_loss';
          _workoutsPerWeek = user.workoutsPerWeek ?? 3;
          _preferredWorkoutTypes = user.preferredWorkoutTypes ?? [];
          _experienceLevel = user.experienceLevel ?? 'beginner';
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildBasicInfoPage(),
                  _buildFitnessGoalsPage(),
                  _buildWorkoutPreferencesPage(),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fitness_center,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            "Welcome to AI Fitness!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            "Let's set up your profile to create a personalized fitness experience.",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildNextButton("Get Started"),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageTitle("Basic Information"),
            const SizedBox(height: 24),

            // Name field
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(
                labelText: "Display Name",
                border: OutlineInputBorder(),
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
            const SizedBox(height: 24),

            // Weight field with unit selector
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: _weight.toString(),
                    decoration: const InputDecoration(
                      labelText: "Weight",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your weight';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _weight = double.tryParse(value) ?? _weight;
                      });
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
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'lbs', child: Text('lbs')),
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
            const SizedBox(height: 24),

            // Height field with unit selector
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: _height.toString(),
                    decoration: const InputDecoration(
                      labelText: "Height",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your height';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _height = double.tryParse(value) ?? _height;
                      });
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
                      DropdownMenuItem(value: 'cm', child: Text('cm')),
                      DropdownMenuItem(value: 'ft', child: Text('ft')),
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
            const SizedBox(height: 40),

            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFitnessGoalsPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageTitle("Fitness Goals"),
            const SizedBox(height: 24),

            // Fitness goal selector
            const Text(
              "What is your primary fitness goal?",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),

            // Workouts per week
            const Text(
              "How many times a week do you want to work out?",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _workoutsPerWeek.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: _workoutsPerWeek.toString(),
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primaryLight.withOpacity(0.3),
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

            // Experience level
            const Text(
              "What's your fitness experience level?",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 40),

            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutPreferencesPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageTitle("Workout Preferences"),
            const SizedBox(height: 24),

            const Text(
              "What types of workouts do you prefer?",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Select all that apply",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Workout type checkboxes
            ...List.generate(_workoutTypes.length, (index) {
              final workout = _workoutTypes[index];
              final isSelected = _preferredWorkoutTypes.contains(workout['id']);

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

            _buildNavigationButtons(isLastPage: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPageTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index <= _currentPage
                      ? AppColors.primary
                      : AppColors.textLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons({bool isLastPage = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentPage > 0)
          TextButton(
            onPressed: _previousPage,
            child: const Text(
              "Back",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        _buildNextButton(isLastPage ? "Complete" : "Next"),
      ],
    );
  }

  Widget _buildNextButton(String label) {
    return ElevatedButton(
      onPressed: () {
        if (_currentPage == 3 && _preferredWorkoutTypes.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please select at least one workout type"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        _nextPage();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
