import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const WorkoutCard({Key? key, required this.workout, required this.onTap})
      : super(key: key);

  // Get a string of target muscles from all exercises in the workout
  String getTargetMuscles() {
    // Extract unique muscle groups from all exercises
    final Set<String> uniqueMuscles = {};
    for (final exercise in workout.exercises) {
      uniqueMuscles.addAll(exercise.targetMuscles);
    }

    // Take the first 2 muscle groups to avoid text overflow
    final List<String> displayMuscles = uniqueMuscles.take(2).toList();

    // If there are more than 2 muscle groups, add "& more"
    if (uniqueMuscles.length > 2) {
      return '${displayMuscles.join(", ")} & more';
    } else {
      return displayMuscles.join(", ");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final cardBackgroundColor = themeProvider.isDarkMode
        ? AppColors.darkCardBackground
        : AppColors.lightCardBackground;
    final textPrimaryColor = themeProvider.isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondaryColor = themeProvider.isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textLightColor = themeProvider.isDarkMode
        ? AppColors.darkTextLight
        : AppColors.lightTextLight;
    final shadowColor = themeProvider.isDarkMode
        ? Colors.black.withOpacity(0.2)
        : Colors.black.withOpacity(0.05);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: workout.imageUrl,
                height: 160,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 160,
                  color: AppColors.primary.withOpacity(0.1),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 160,
                  color: AppColors.primary.withOpacity(0.2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 50,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        workout.type,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        workout.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(workout.difficulty),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          workout.difficulty.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    workout.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: textLightColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${workout.duration} min',
                        style: TextStyle(
                          fontSize: 14,
                          color: textLightColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.fitness_center,
                        size: 16,
                        color: textLightColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        getTargetMuscles(),
                        style: TextStyle(
                          fontSize: 14,
                          color: textLightColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }
}
