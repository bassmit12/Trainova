import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../config/env_config.dart';

class AIWorkoutService {
  // Using the Gemini API configuration from EnvConfig
  static String get _apiUrl => EnvConfig.geminiApiUrl;
  static String get _apiKey => EnvConfig.geminiApiKey;

  // Determine if a prompt is likely requesting a workout
  static bool isWorkoutRequest(String prompt) {
    final workoutKeywords = [
      'workout',
      'exercise',
      'routine',
      'training',
      'fitness',
      'cardio',
      'strength',
      'hiit',
      'yoga',
      'plan',
      'sets',
      'reps',
      'program',
      'gym',
      'weight',
      'muscle',
      'body',
      'train',
    ];

    final lowerPrompt = prompt.toLowerCase();

    // Check if the prompt contains workout-related keywords
    for (var keyword in workoutKeywords) {
      if (lowerPrompt.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  // Generate a regular response for conversational queries
  static Future<String> generateConversation(String prompt) async {
    try {
      debugPrint('Making conversation request to Gemini API: $prompt');

      // Check if environment is properly initialized
      if (!EnvConfig.isInitialized) {
        return 'Environment configuration not initialized. Please restart the app.';
      }

      if (_apiKey.isEmpty) {
        return 'API key not found in environment configuration.';
      }

      final queryParams = {'key': _apiKey};
      final uri = Uri.parse(_apiUrl).replace(queryParameters: queryParams);

      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": """
You are a friendly fitness coach AI assistant. The user is having a conversation with you about fitness, health, and wellness.
Respond in a conversational, helpful manner. If the user seems to be asking for a workout, suggest they ask for a specific 
workout type or use phrases like "create a workout for..." to get a structured workout plan.

User: ${prompt}
""",
              },
            ],
          },
        ],
        "generationConfig": {"temperature": 0.7, "maxOutputTokens": 1024},
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Check if the response has the expected structure
        if (jsonResponse['candidates'] == null ||
            jsonResponse['candidates'].isEmpty ||
            jsonResponse['candidates'][0]['content'] == null ||
            jsonResponse['candidates'][0]['content']['parts'] == null ||
            jsonResponse['candidates'][0]['content']['parts'].isEmpty) {
          return 'Sorry, I had trouble understanding. Could you rephrase that?';
        }

        final content =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        return content;
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        return 'Sorry, I had a technical issue. Please try again in a moment.';
      }
    } catch (e) {
      debugPrint('Exception during conversation API call: $e');
      return 'Sorry, I encountered an error. Please try again.';
    }
  }

  // Generate a workout based on a natural language description
  static Future<WorkoutGenerationResponse> generateWorkout(
    String prompt,
  ) async {
    final uuid = Uuid();
    final id = uuid.v4();

    try {
      debugPrint('Making request to Gemini API for prompt: $prompt');
      debugPrint('API URL: $_apiUrl');

      // Check if environment is properly initialized
      if (!EnvConfig.isInitialized) {
        debugPrint('Environment variables not initialized');
        return WorkoutGenerationResponse(
          id: id,
          prompt: prompt,
          errorMessage:
              'Environment configuration not initialized. Please restart the app.',
        );
      }

      if (_apiKey.isEmpty) {
        debugPrint('API key is empty');
        return WorkoutGenerationResponse(
          id: id,
          prompt: prompt,
          errorMessage: 'API key not found in environment configuration.',
        );
      }

      final queryParams = {'key': _apiKey};
      final uri = Uri.parse(_apiUrl).replace(queryParameters: queryParams);

      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": """
You are a professional fitness coach AI assistant specializing in creating personalized workout plans. 
When a user describes what kind of workout they want, you'll create a structured workout plan with appropriate exercises.
Respond with a valid JSON object containing the workout details and exercises. Follow this exact structure:
{
  "name": "Workout name",
  "description": "Brief description of the workout and its benefits",
  "type": "Strength, Cardio, HIIT, etc.",
  "duration": "Format as '30 min', '45 min', etc.",
  "difficulty": "beginner, intermediate, or advanced",
  "calories_burned": estimated calories as integer,
  "exercises": [
    {
      "name": "Exercise name",
      "description": "Clear instruction on how to perform the exercise",
      "sets": number of sets (integer),
      "reps": number of reps per set (integer),
      "duration": "Format as '30s', '45s', '1m', etc.",
      "equipment": ["Equipment needed", "or empty array if bodyweight"],
      "target_muscles": ["Primary muscle", "Secondary muscle", etc.],
      "difficulty": "beginner, intermediate, or advanced"
    }
  ]
}

User request: ${prompt}
""",
              },
            ],
          },
        ],
        "generationConfig": {"temperature": 0.7, "maxOutputTokens": 2048},
      };

      debugPrint('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('Successful response from Gemini API');
        final jsonResponse = jsonDecode(response.body);

        // Check if the response has the expected structure
        if (jsonResponse['candidates'] == null ||
            jsonResponse['candidates'].isEmpty ||
            jsonResponse['candidates'][0]['content'] == null ||
            jsonResponse['candidates'][0]['content']['parts'] == null ||
            jsonResponse['candidates'][0]['content']['parts'].isEmpty) {
          debugPrint('Unexpected API response structure: ${response.body}');
          return WorkoutGenerationResponse(
            id: id,
            prompt: prompt,
            errorMessage: 'Unexpected API response structure',
          );
        }

        final content =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        debugPrint('Gemini Response content: $content');

        try {
          // Extract JSON from the response content
          // This handles both cases where the AI returns pure JSON or JSON embedded in markdown
          final jsonMatch = RegExp(r'{.*}', dotAll: true).firstMatch(content);
          if (jsonMatch == null) {
            debugPrint('Could not extract JSON from AI response');
            return WorkoutGenerationResponse(
              id: id,
              prompt: prompt,
              errorMessage:
                  'The AI response did not contain valid JSON. Please try again with a clearer workout description.',
            );
          }

          final jsonContent = jsonMatch.group(0);
          debugPrint('Extracted JSON: $jsonContent');

          final Map<String, dynamic> workoutData = jsonDecode(jsonContent!);
          debugPrint(
            'Successfully parsed workout data with ${workoutData['exercises']?.length ?? 0} exercises',
          );

          return WorkoutGenerationResponse(
            id: id,
            prompt: prompt,
            generatedWorkout: workoutData,
          );
        } catch (e) {
          debugPrint('Error parsing AI response: $e');
          return WorkoutGenerationResponse(
            id: id,
            prompt: prompt,
            errorMessage:
                'Failed to parse the AI response. Please try again with a clearer workout description.',
          );
        }
      } else {
        debugPrint('API error: ${response.statusCode} - ${response.body}');
        return WorkoutGenerationResponse(
          id: id,
          prompt: prompt,
          errorMessage:
              'API error (${response.statusCode}): ${_extractErrorMessage(response.body)}',
        );
      }
    } catch (e) {
      debugPrint('Exception during API call: $e');
      return WorkoutGenerationResponse(
        id: id,
        prompt: prompt,
        errorMessage: 'Connection error: ${e.toString()}',
      );
    }
  }

  // Helper method to extract error messages from the API response
  static String _extractErrorMessage(String responseBody) {
    try {
      final jsonResponse = jsonDecode(responseBody);
      if (jsonResponse['error'] != null) {
        return jsonResponse['error']['message'] ?? 'Unknown error';
      }
      return 'Unknown error';
    } catch (e) {
      return 'Could not parse error message';
    }
  }

  // Convert AI generated workout to a Workout object that can be saved
  static Future<Workout?> convertToWorkout(
    WorkoutGenerationResponse response,
  ) async {
    if (!response.isSuccess || response.generatedWorkout == null) {
      return null;
    }

    try {
      final workoutData = response.toWorkoutJson();
      final List<Exercise> exercises = [];

      // Convert exercise data
      final exerciseList = workoutData['exercises'] as List;
      for (final exerciseData in exerciseList) {
        // Handle potentially null integer values with defaults
        final int sets =
            exerciseData['sets'] is int
                ? exerciseData['sets']
                : 3; // Default to 3 sets if null or invalid

        final int reps =
            exerciseData['reps'] is int
                ? exerciseData['reps']
                : 10; // Default to 10 reps if null or invalid

        // Ensure target_muscles is a valid list or provide a default
        List<String> targetMuscles = [];
        if (exerciseData['target_muscles'] != null) {
          try {
            targetMuscles = List<String>.from(exerciseData['target_muscles']);
          } catch (e) {
            debugPrint('Error parsing target_muscles: $e');
            targetMuscles = ['General'];
          }
        } else {
          targetMuscles = ['General'];
        }

        exercises.add(
          Exercise(
            id: 'new', // This indicates it's a new exercise to be created
            name: exerciseData['name'] ?? 'Unnamed Exercise',
            description:
                exerciseData['description'] ?? 'No description provided',
            category:
                exerciseData['type'] ??
                'Strength', // Add required category parameter
            sets: sets,
            reps: reps,
            imageUrl: '', // No image for AI generated exercises by default
            targetMuscles: targetMuscles,
            difficulty: exerciseData['difficulty'] ?? 'intermediate',
            isPublic: false, // User's private exercise
          ),
        );
      }

      // Create the workout object
      return Workout(
        id: 'new', // This indicates it's a new workout to be created
        name: workoutData['name'] ?? 'AI Generated Workout',
        description: workoutData['description'] ?? 'Created with AI Assistant',
        type: workoutData['type'] ?? 'Mixed',
        imageUrl: '', // No image for AI generated workouts by default
        duration: workoutData['duration'] ?? '30 min',
        difficulty: workoutData['difficulty'] ?? 'intermediate',
        caloriesBurned:
            workoutData['calories_burned'] is int
                ? workoutData['calories_burned']
                : 300, // Default to 300 calories if null or invalid
        exercises: exercises,
        isPublic: false, // User's private workout
      );
    } catch (e) {
      debugPrint('Error converting AI response to workout: $e');
      return null;
    }
  }

  // Save a generated workout
  static Future<Workout?> saveGeneratedWorkout(
    WorkoutGenerationResponse response,
  ) async {
    final workout = await convertToWorkout(response);
    if (workout == null) return null;

    // Use the existing Workout model's createWorkout method
    return await Workout.createWorkout(workout);
  }
}
