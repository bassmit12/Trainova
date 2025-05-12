import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_history.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';

/// Service class to handle retrieving and analyzing workout history data
class WorkoutHistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch workout history for the current user
  Future<List<WorkoutHistory>> fetchWorkoutHistory() async {
    try {
      return await WorkoutHistory.fetchUserWorkoutHistory();
    } catch (e) {
      debugPrint('Error fetching workout history: $e');
      return [];
    }
  }

  /// Get all sets performed for a specific exercise
  /// Returns a list of sets sorted by date (most recent first)
  Future<List<WorkoutSet>> getExerciseHistory(String exerciseId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // First get all workout histories for the user
      final workoutHistories = await fetchWorkoutHistory();

      // Extract all sets for the specified exercise
      final List<Map<String, dynamic>> exerciseSetsWithDate = [];

      for (final history in workoutHistories) {
        final completedDate = history.completedAt;

        // Filter sets for the target exercise
        final exerciseSets =
            history.sets.where((set) => set.exerciseId == exerciseId).toList();

        // Add each set with its completion date
        for (final set in exerciseSets) {
          exerciseSetsWithDate.add({'set': set, 'date': completedDate});
        }
      }

      // Sort by date (most recent first)
      exerciseSetsWithDate.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

      // Extract just the sets
      return exerciseSetsWithDate
          .map((item) => item['set'] as WorkoutSet)
          .toList();
    } catch (e) {
      debugPrint('Error getting exercise history: $e');
      return [];
    }
  }

  /// Get the most recent workout sets for an exercise
  /// Returns the sets from the most recent workout where this exercise was performed
  Future<List<WorkoutSet>> getMostRecentExerciseSets(String exerciseId) async {
    try {
      final allSets = await getExerciseHistory(exerciseId);
      if (allSets.isEmpty) return [];

      // Get the date of the most recent workout
      final firstSet = allSets.first;

      // Find workout history containing this set
      final workoutHistories = await fetchWorkoutHistory();

      for (final history in workoutHistories) {
        // Check if this workout history contains the set
        if (history.sets.any((set) => set.exerciseId == exerciseId)) {
          // Return all sets for this exercise from the most recent workout
          return history.sets
              .where((set) => set.exerciseId == exerciseId)
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('Error getting most recent exercise sets: $e');
      return [];
    }
  }

  /// Calculate the average weight used for a specific exercise in the last N workouts
  Future<double> getAverageWeightForExercise(
    String exerciseId, {
    int lastNWorkouts = 3,
  }) async {
    try {
      final exerciseSets = await getExerciseHistory(exerciseId);
      if (exerciseSets.isEmpty) return 0;

      // Get unique workout dates by tracking unique set IDs we've already counted
      final uniqueWorkoutSets = <String>{};
      final weightsPerWorkout = <double>[];

      for (final set in exerciseSets) {
        // If we've collected enough workouts, stop
        if (weightsPerWorkout.length >= lastNWorkouts) break;

        // If we haven't seen this set before (from a different workout)
        if (!uniqueWorkoutSets.contains(set.id)) {
          // Add the set's weight to our list
          uniqueWorkoutSets.add(set.id);
          weightsPerWorkout.add(set.weight);
        }
      }

      // Calculate the average
      if (weightsPerWorkout.isEmpty) return 0;
      return weightsPerWorkout.reduce((a, b) => a + b) /
          weightsPerWorkout.length;
    } catch (e) {
      debugPrint('Error calculating average weight: $e');
      return 0;
    }
  }

  /// Get the maximum weight used for a specific exercise across all workouts
  Future<double> getMaxWeightForExercise(String exerciseId) async {
    try {
      final exerciseSets = await getExerciseHistory(exerciseId);
      if (exerciseSets.isEmpty) return 0;

      double maxWeight = 0;
      for (final set in exerciseSets) {
        if (set.weight > maxWeight) {
          maxWeight = set.weight;
        }
      }

      return maxWeight;
    } catch (e) {
      debugPrint('Error calculating max weight: $e');
      return 0;
    }
  }
}
