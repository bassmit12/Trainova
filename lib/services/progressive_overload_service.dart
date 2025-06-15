import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/weight_prediction.dart';
import '../models/workout_set.dart';
import '../models/exercise.dart';
import '../config/api_config.dart';
import '../config/env_config.dart';
import '../services/workout_history_service.dart';

class ProgressiveOverloadService {
  final String baseUrl;
  final String feedbackUrl;
  final WorkoutHistoryService _historyService = WorkoutHistoryService();

  ProgressiveOverloadService({String? apiUrl, String? feedbackApiUrl})
    : baseUrl = apiUrl ?? EnvConfig.neuralNetworkApiUrl,
      feedbackUrl = feedbackApiUrl ?? EnvConfig.feedbackApiUrl;

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

      final requestBody = {
        'user_id': userId,
        'exercise': exercise,
        'previous_weights': previousWeights,
        'days_since_workouts': daysSinceWorkouts,
        'sets': sets, // Include sets in API request
      };

      // Log the prediction request
      print('=== AI PREDICTION REQUEST (Neural Network) ===');
      print('URL: $url');
      print('Request Body: ${jsonEncode(requestBody)}');
      print('Timestamp: ${DateTime.now().toIso8601String()}');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Log the response
      print('=== AI PREDICTION RESPONSE (Neural Network) ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Timestamp: ${DateTime.now().toIso8601String()}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prediction = WeightPrediction.fromJson(data);

        // Log the parsed prediction
        print('=== PARSED PREDICTION (Neural Network) ===');
        print('Predicted Weight: ${prediction.predictedWeight}');
        print('Confidence: ${prediction.confidence}');
        print('Suggested Reps: ${prediction.suggestedReps}');
        print('Suggested Sets: ${prediction.suggestedSets}');
        print('Message: ${prediction.message}');
        print('===============================================');

        return prediction;
      } else {
        final error = jsonDecode(response.body);
        print('=== AI PREDICTION ERROR (Neural Network) ===');
        print('Error: ${error['detail'] ?? 'Unknown error'}');
        print('===============================================');
        throw Exception(
          'Failed to predict weight: ${error['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('=== AI PREDICTION EXCEPTION (Neural Network) ===');
      print('Exception: $e');
      print('===============================================');
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
        // Use the feedback-based prediction system
        final prediction = await getFeedbackPrediction(
          exerciseId,
          exerciseSets,
        );
        if (prediction != null) {
          return prediction;
        }

        // Fall back to simple prediction if API fails
        return _createSimplePrediction(exerciseSets);
      } catch (e) {
        debugPrint('Error using feedback-based prediction: $e');
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
    // Use ALL workout sets for optimal prediction (no limit)
    // Get exercise information to determine number of programmed sets
    final exerciseInfo = await Exercise.fetchExercisesByIds([exerciseId]);
    final exercise = exerciseInfo[exerciseId];
    final programmedSets = exercise?.sets ?? 3; // Default to 3 if not found

    // Extract weights and calculate days between workouts from ALL sets
    final List<double> previousWeights = [];
    final List<int> daysBetween = [];

    // Sort sets by timestamp to ensure proper chronological order
    final sortedSets = List<WorkoutSet>.from(sets);
    sortedSets.sort((a, b) {
      final aTime = a.timestamp ?? DateTime.now();
      final bTime = b.timestamp ?? DateTime.now();
      return aTime.compareTo(bTime);
    });

    // Extract weights and calculate time differences from ALL available data
    for (int i = 0; i < sortedSets.length; i++) {
      previousWeights.add(sortedSets[i].weight);

      if (i > 0) {
        // Calculate days between this set and the previous one
        final currentTime = sortedSets[i].timestamp ?? DateTime.now();
        final previousTime = sortedSets[i - 1].timestamp ?? DateTime.now();
        final daysDiff = currentTime.difference(previousTime).inDays;
        daysBetween.add(daysDiff > 0 ? daysDiff : 1); // Minimum 1 day
      } else {
        // For the first set, assume 7 days from a previous workout
        daysBetween.add(7);
      }
    }

    // Ensure we have enough data points for the API (pad with reasonable defaults if needed)
    while (previousWeights.length < 5) {
      if (previousWeights.isNotEmpty) {
        // Use the last weight as a fallback
        previousWeights.add(previousWeights.last);
        daysBetween.add(7); // Assume weekly workouts
      } else {
        // Default starting values
        previousWeights.add(20.0); // 20kg default
        daysBetween.add(7);
      }
    }

    // Call the API with ALL available workout data
    try {
      final prediction = await predictNextWeight(
        userId: 1, // Default user ID
        exercise: exerciseId,
        previousWeights: previousWeights,
        daysSinceWorkouts: daysBetween,
        sets: programmedSets, // Pass the actual number of sets
      );

      return prediction;
    } catch (e) {
      debugPrint('API prediction failed: $e');
      throw Exception('API prediction failed');
    }
  }

  /// Sends feedback to the feedback-based prediction system about the accuracy of a prediction
  /// This helps the system learn and improve future predictions
  Future<Map<String, dynamic>> sendPredictionFeedback({
    required String exercise,
    required double predictedWeight,
    required double actualWeight,
    required bool success,
    int? reps,
  }) async {
    try {
      final url = '$feedbackUrl/feedback';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'exercise': exercise,
          'predicted_weight': predictedWeight,
          'actual_weight': actualWeight,
          'success': success,
          if (reps != null) 'reps': reps,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Feedback sent successfully: ${data['message']}');
        return data;
      } else {
        final error = jsonDecode(response.body);
        debugPrint(
          'Failed to send feedback: ${error['detail'] ?? 'Unknown error'}',
        );
        return {'error': error['detail'] ?? 'Unknown error'};
      }
    } catch (e) {
      debugPrint('Failed to connect to Feedback API: $e');
      return {'error': 'Failed to connect to Feedback API: $e'};
    }
  }

  /// Gets a prediction from the feedback-based system
  Future<WeightPrediction?> getFeedbackPrediction(
    String exerciseId,
    List<WorkoutSet> previousWorkouts,
  ) async {
    try {
      final url = '$feedbackUrl/predict';

      // Get the exercise name from the exercise ID
      String exerciseName = exerciseId; // fallback to ID if lookup fails
      try {
        final exerciseInfo = await Exercise.fetchExercisesByIds([exerciseId]);
        final exercise = exerciseInfo[exerciseId];
        if (exercise != null) {
          // Convert exercise name to a format the ML model expects
          // Remove spaces, convert to lowercase, replace spaces with underscores
          exerciseName = exercise.name.toLowerCase().replaceAll(' ', '_');
        }
      } catch (e) {
        debugPrint('Error fetching exercise name: $e');
        // Continue with exerciseId as fallback
      }

      // Use ALL previous workouts for optimal prediction (no limit)
      // Transform workout sets into the format required by feedback API
      final List<Map<String, dynamic>> workoutData =
          previousWorkouts
              .map(
                (set) => {
                  'exercise': exerciseName, // Use exercise name instead of ID
                  'weight': set.weight,
                  'reps': set.reps,
                  'date':
                      set.timestamp?.toIso8601String() ??
                      DateTime.now().toIso8601String(),
                  'success': true, // Assume completed sets were successful
                  'rir': set.rir, // Include RIR if available
                },
              )
              .toList();

      final requestBody = {
        'exercise': exerciseName, // Use exercise name instead of ID
        'previous_workouts': workoutData,
      };

      // Log the prediction request
      print('=== AI PREDICTION REQUEST (Feedback System) ===');
      print('URL: $url');
      print('Request Body: ${jsonEncode(requestBody)}');
      print('Exercise ID: $exerciseId');
      print('Exercise Name: $exerciseName');
      print('Total Previous Workouts Sent: ${workoutData.length}');
      print('Timestamp: ${DateTime.now().toIso8601String()}');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Log the response
      print('=== AI PREDICTION RESPONSE (Feedback System) ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Timestamp: ${DateTime.now().toIso8601String()}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Get suggested reps from the feedback system or use defaults
        List<int> suggestedReps;
        if (data.containsKey('suggested_reps') &&
            data['suggested_reps'] != null) {
          // Convert from dynamic list to int list
          suggestedReps = List<int>.from(data['suggested_reps']);
        } else {
          // Default rep scheme if not provided by the API
          suggestedReps = List<int>.filled(3, 8);
        }

        // Convert feedback API response to WeightPrediction format
        final prediction = WeightPrediction(
          predictedWeight: data['weight'].toDouble(),
          exercise: exerciseId,
          confidence: data['confidence'].toDouble(),
          suggestedReps: suggestedReps,
          suggestedSets: suggestedReps.length,
          message: data['message'] ?? 'Prediction from feedback-based system',
        );

        // Log the parsed prediction
        print('=== PARSED PREDICTION (Feedback System) ===');
        print('Predicted Weight: ${prediction.predictedWeight}');
        print('Confidence: ${prediction.confidence}');
        print('Suggested Reps: ${prediction.suggestedReps}');
        print('Suggested Sets: ${prediction.suggestedSets}');
        print('Message: ${prediction.message}');
        print('===============================================');

        return prediction;
      } else {
        final error = jsonDecode(response.body);
        print('=== AI PREDICTION ERROR (Feedback System) ===');
        print('Error: ${error['detail'] ?? 'Unknown error'}');
        print('===============================================');
        debugPrint(
          'Failed to get feedback prediction: ${error['detail'] ?? 'Unknown error'}',
        );
        return null;
      }
    } catch (e) {
      print('=== AI PREDICTION EXCEPTION (Feedback System) ===');
      print('Exception: $e');
      print('===============================================');
      debugPrint('Failed to connect to Feedback API: $e');
      return null;
    }
  }
}
