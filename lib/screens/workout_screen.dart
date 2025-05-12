import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../providers/theme_provider.dart';
import '../widgets/workout_card.dart';
import '../utils/app_colors.dart';
import 'workout_details_screen.dart';
import 'create_workout_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Strength',
    'Cardio',
    'Yoga',
    'HIIT',
    'Recovery',
  ];

  List<Workout> _workouts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWorkouts();
  }

  Future<void> _fetchWorkouts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final workouts = await Workout.fetchWorkouts();

      if (workouts.isEmpty) {
        await Workout.initializePublicWorkouts();
        final initializedWorkouts = await Workout.fetchWorkouts();
        setState(() {
          _workouts = initializedWorkouts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _workouts = workouts;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load workouts: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Workout> _getFilteredWorkouts(bool publicOnly) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return _workouts.where((workout) {
      final matchesPublic = publicOnly ? workout.isPublic : !workout.isPublic;
      final isOwnedByUser =
          currentUserId != null && workout.createdBy == currentUserId;
      final visibilityMatches =
          publicOnly ? matchesPublic : (matchesPublic && isOwnedByUser);
      final categoryMatches =
          _selectedCategory == 'All' || workout.type == _selectedCategory;

      return visibilityMatches && categoryMatches;
    }).toList();
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

    final publicWorkouts = _getFilteredWorkouts(true);
    final privateWorkouts = _getFilteredWorkouts(false);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchWorkouts,
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: textPrimaryColor),
                    ),
                  )
                  : CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        floating: true,
                        pinned: true,
                        backgroundColor: backgroundColor,
                        elevation: 0,
                        title: Text(
                          'Workouts',
                          style: TextStyle(
                            color: textPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        actions: [
                          IconButton(
                            icon: Icon(Icons.search, color: textPrimaryColor),
                            onPressed: () {
                              // TODO: Implement search functionality
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.filter_list,
                              color: textPrimaryColor,
                            ),
                            onPressed: () {
                              // TODO: Implement filter functionality
                            },
                          ),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: _buildCategorySelector(
                          cardBackgroundColor,
                          textPrimaryColor,
                          textSecondaryColor,
                        ),
                      ),
                      // Add extra spacing between categories and AI Workout Creator
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      // AI Workout Creator Banner
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Material(
                            borderRadius: BorderRadius.circular(16),
                            elevation: 4,
                            child: InkWell(
                              onTap: () => _openAIWorkoutCreator(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryLight,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.bolt,
                                            color: AppColors.primary,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: const [
                                              Text(
                                                "AI Workout Creator",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "Create personalized workouts using AI",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            "Get Started",
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: AppColors.primary,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Public Workouts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                          ),
                        ),
                      ),
                      publicWorkouts.isEmpty
                          ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  'No public workouts found',
                                  style: TextStyle(color: textSecondaryColor),
                                ),
                              ),
                            ),
                          )
                          : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => WorkoutCard(
                                workout: publicWorkouts[index],
                                onTap:
                                    () => _openWorkoutDetails(
                                      context,
                                      publicWorkouts[index],
                                    ),
                              ),
                              childCount: publicWorkouts.length,
                            ),
                          ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Custom Workouts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimaryColor,
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('New'),
                                onPressed: () => _createCustomWorkout(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      privateWorkouts.isEmpty
                          ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  'You haven\'t created any custom workouts yet',
                                  style: TextStyle(color: textSecondaryColor),
                                ),
                              ),
                            ),
                          )
                          : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => WorkoutCard(
                                workout: privateWorkouts[index],
                                onTap:
                                    () => _openWorkoutDetails(
                                      context,
                                      privateWorkouts[index],
                                    ),
                              ),
                              childCount: privateWorkouts.length,
                            ),
                          ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _createCustomWorkout(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategorySelector(
    Color cardBackgroundColor,
    Color textPrimaryColor,
    Color textSecondaryColor,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          final backgroundColor =
              isSelected ? AppColors.primary : cardBackgroundColor;

          final textColor = isSelected ? Colors.white : textPrimaryColor;

          final shadowColor =
              themeProvider.isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: TextStyle(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openWorkoutDetails(BuildContext context, Workout workout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutDetailsScreen(workout: workout),
      ),
    ).then((_) => _fetchWorkouts());
  }

  void _createCustomWorkout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateWorkoutScreen()),
    ).then((_) => _fetchWorkouts());
  }

  void _openAIWorkoutCreator(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/ai_workout_creator',
    ).then((_) => _fetchWorkouts());
  }
}
