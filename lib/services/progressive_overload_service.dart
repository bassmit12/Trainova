import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/weight_prediction.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';
import '../config/api_config.dart';
import '../services/workout_history_service.dart';

class ProgressiveOverloadService {
  final String baseUrl;
  final WorkoutHistoryService _historyService = WorkoutHistoryService();

  ProgressiveOverloadService({
    this.baseUrl = ApiConfig.progressiveOverloadApiUrl,
  });

  /// Fetches a weight prediction for the next workout
  Future<WeightPrediction> predictNextWeight({
    required int userId,
    required String exercise,
    required List<double> previousWeights,
    required List<int> daysSinceWorkouts,
    int sets = 3, // Add sets parameter with default value
  }) async {
    try {
      final url = '$baseUrl/api/predict';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'exercise': exercise,
          'previous_weights': previousWeights,
          'days_since_workouts': daysSinceWorkouts,
          'sets': sets, // Include sets in API request
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WeightPrediction.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          'Failed to predict weight: ${error['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to Progressive Overload API: $e');
    }
  }

  /// Gets a list of supported exercises from the API
  Future<List<String>> getSupportedExercises() async {
    try {
      final url = '$baseUrl/api/exercises';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e.toString()).toList();
      } else {
        throw Exception('Failed to fetch supported exercises');
      }
    } catch (e) {
      throw Exception('Failed to connect to Progressive Overload API: $e');
    }
  }

  /// Gets information about the model
  Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final url = '$baseUrl/api/model/info';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch model information');
      }
    } catch (e) {
      throw Exception('Failed to connect to Progressive Overload API: $e');
    }
  }

  /// Tests basic API connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final url = '$baseUrl/api/health';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to connect: Status code ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to Progressive Overload API: $e');
    }
  }

  /// Gets a recommended weight for a specific exercise based on workout history
  Future<WeightPrediction?> getRecommendedWeight(String exerciseId) async {
    try {
      // Get the exercise history from our service
      final exerciseSets = await _historyService.getExerciseHistory(exerciseId);

      // If we don't have any history, return null
      if (exerciseSets.isEmpty) {
        debugPrint('No workout history found for exercise $exerciseId');
        return null;
      }

      // We need at least 3 completed sets to make a good prediction
      if (exerciseSets.length < 3) {
        debugPrint(
          'Not enough workout history for exercise $exerciseId (only ${exerciseSets.length} sets)',
        );
        return _createSimplePrediction(exerciseSets);
      }

      try {
        // Try to use the neural network API first
        return await _getPredictionFromApi(exerciseId, exerciseSets);
      } catch (e) {
        debugPrint('Error using API prediction: $e');
        // Fall back to simple prediction if API fails
        return _createSimplePrediction(exerciseSets);
      }
    } catch (e) {
      debugPrint('Error getting recommended weight: $e');
      return null;
    }
  }

  /// Creates a simple prediction based on the last few workouts
  /// Used as a fallback when API is unavailable
  Future<WeightPrediction> _createSimplePrediction(
    List<WorkoutSet> sets,
  ) async {
    try {
      // Get the exercise ID from the first set
      final exerciseId = sets.isNotEmpty ? sets.first.exerciseId : '';

      // Get exercise information to determine number of programmed sets
      int programmedSets = 3;
      if (exerciseId.isNotEmpty) {
        final exerciseInfo = await Exercise.fetchExercisesByIds([exerciseId]);
        final exercise = exerciseInfo[exerciseId];
        programmedSets = exercise?.sets ?? 3;
      }

      // Get the weights from the sets
      final weights = sets.map((set) => set.weight).toList();

      // Find max weight
      final maxWeight = weights.reduce((a, b) => a > b ? a : b);

      // Simple progression: 5% increase from the max or 2.5 lbs, whichever is greater
      final baseIncrease = maxWeight * 0.05;
      final minIncrease = 2.5;
      final increase = baseIncrease > minIncrease ? baseIncrease : minIncrease;

      // Round to nearest 2.5 lbs
      final predictedWeight = ((maxWeight + increase) / 2.5).round() * 2.5;

      // Generate appropriate suggested reps based on the programmed number of sets
      List<int> suggestedReps;
      switch (programmedSets) {
        case 1:
          suggestedReps = [10];
          break;
        case 2:
          suggestedReps = [10, 8];
          break;
        case 3:
          suggestedReps = [10, 8, 6];
          break;
        case 4:
          suggestedReps = [10, 8, 6, 6];
          break;
        case 5:
          suggestedReps = [10, 9, 8, 7, 6];
          break;
        default:
          // For more than 5 sets, create a descending pattern
          suggestedReps = List.generate(programmedSets, (i) => max(10 - i, 6));
      }

      return WeightPrediction(
        predictedWeight: predictedWeight,
        exercise: 'Exercise', // This will be replaced in the UI
        confidence: 0.7, // Medium confidence with simple calculation
        suggestedReps: suggestedReps,
        suggestedSets: programmedSets,
        message: 'Recommendation based on previous workouts',
      );
    } catch (e) {
      // If there's any error in calculation, suggest a minimal increase
      final lastWeight = sets.isNotEmpty ? sets.first.weight : 5;
      final exerciseId = sets.isNotEmpty ? sets.first.exerciseId : '';

      // Get exercise information to determine number of programmed sets
      int programmedSets = 3;
      if (exerciseId.isNotEmpty) {
        try {
          final exerciseInfo = await Exercise.fetchExercisesByIds([exerciseId]);
          final exercise = exerciseInfo[exerciseId];
          programmedSets = exercise?.sets ?? 3;
        } catch (_) {
          // Use default if fetch fails
        }
      }

      // Create suggested reps based on number of sets
      final suggestedReps = List.filled(programmedSets, 8);

      return WeightPrediction(
        predictedWeight: lastWeight + 2.5,
        exercise: 'Exercise',
        confidence: 0.5,
        suggestedReps: suggestedReps,
        suggestedSets: programmedSets,
        message: 'Minimal progression from previous workout',
      );
    }
  }

  /// Attempts to get a prediction from the machine learning API
  Future<WeightPrediction> _getPredictionFromApi(
    String exerciseId,
    List<WorkoutSet> sets,
  ) async {
    // Get exercise information to determine number of programmed sets
    final exerciseInfo = await Exercise.fetchExercisesByIds([exerciseId]);
    final exercise = exerciseInfo[exerciseId];
    final programmedSets = exercise?.sets ?? 3; // Default to 3 if not found

    // Extract weights for previous workouts
    final List<double> previousWeights = [];

    // We'll assume a 7-day interval between workouts for now
    // In a more sophisticated implementation, we'd calculate actual days between workouts
    final List<int> daysBetween = [];

    // Group the sets by workout dates and add the average weight for each workout
    final Map<String, List<WorkoutSet>> setsByWorkout = {};

    for (final set in sets) {
      // Use set ID as a proxy for workout grouping
      // In a real implementation, we'd use actual workout dates
      final workoutId =
          set.id.split(
            '-',
          )[0]; // Just use first part of ID as workout identifier
      if (!setsByWorkout.containsKey(workoutId)) {
        setsByWorkout[workoutId] = [];
      }
      setsByWorkout[workoutId]!.add(set);
    }

    // Sort to get most recent workouts first
    final sortedWorkoutIds = setsByWorkout.keys.toList();

    // Take the last 5 workouts (or fewer if not available)
    for (int i = 0; i < sortedWorkoutIds.length && i < 5; i++) {
      final workoutSets = setsByWorkout[sortedWorkoutIds[i]]!;

      // Calculate average weight for this workout and add it to the list
      final avgWeight =
          workoutSets.map((s) => s.weight).reduce((a, b) => a + b) /
          workoutSets.length;
      previousWeights.add(avgWeight);

      // Assume 7 days between workouts
      daysBetween.add(7);
    }

    // Make sure lists have at least 5 elements for the API
    while (previousWeights.length < 5) {
      // Repeat first weight if not enough history
      previousWeights.add(previousWeights.isNotEmpty ? previousWeights[0] : 10);
      daysBetween.add(7);
    }

    // Call the API
    try {
      final prediction = await predictNextWeight(
        userId: 1, // Default user ID
        exercise: exerciseId,
        previousWeights:
            previousWeights.reversed.toList(), // Oldest first, as API expects
        daysSinceWorkouts: daysBetween.reversed.toList(),
        sets: programmedSets, // Pass the actual number of sets
      );

      return prediction;
    } catch (e) {
      debugPrint('API prediction failed: $e');
      throw Exception('API prediction failed');
    }
  }
}
