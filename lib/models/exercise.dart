import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Exercise {
  final String id;
  final String name;
  final String description;
  final int sets;
  final int reps;
  final String imageUrl;
  final List<String> targetMuscles;
  final String difficulty; // "beginner", "intermediate", "advanced"
  final bool isPublic;
  final String? createdBy;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.sets,
    required this.reps,
    required this.imageUrl,
    required this.targetMuscles,
    required this.difficulty,
    this.isPublic = false,
    this.createdBy,
  });

  // Method to create a copy of the exercise with modified properties
  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    int? sets,
    int? reps,
    String? imageUrl,
    List<String>? targetMuscles,
    String? difficulty,
    bool? isPublic,
    String? createdBy,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      imageUrl: imageUrl ?? this.imageUrl,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      difficulty: difficulty ?? this.difficulty,
      isPublic: isPublic ?? this.isPublic,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Factory to convert from Supabase response data
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      sets: map['sets'],
      reps: map['reps'],
      imageUrl: map['image_url'],
      targetMuscles: List<String>.from(map['target_muscles'] ?? []),
      difficulty: map['difficulty'],
      isPublic: map['is_public'] ?? false,
      createdBy: map['created_by'],
    );
  }

  // Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'sets': sets,
      'reps': reps,
      'image_url': imageUrl,
      'target_muscles': targetMuscles,
      'difficulty': difficulty,
      'is_public': isPublic,
      'created_by': createdBy,
    };
  }

  // Method to get alternative exercises based on equipment availability
  static Future<List<Exercise>> getAlternativeExercises(
      Exercise exercise) async {
    final supabase = Supabase.instance.client;

    // Find exercises targeting similar muscle groups
    final response = await supabase
        .from('exercises')
        .select()
        .neq('id', exercise.id) // Not the same exercise
        .overlaps(
            'target_muscles', exercise.targetMuscles) // Similar muscle groups
        .or('is_public.eq.true,created_by.eq.${supabase.auth.currentUser?.id}') // Public or owned by user
        .order('created_at');

    if (response.isEmpty) return [];

    final alternatives =
        response.map((data) => Exercise.fromMap(data)).toList();

    // Sort by number of matching muscle targets (most similar first)
    alternatives.sort((a, b) {
      final aMatches = a.targetMuscles
          .where((m) => exercise.targetMuscles.contains(m))
          .length;
      final bMatches = b.targetMuscles
          .where((m) => exercise.targetMuscles.contains(m))
          .length;
      return bMatches.compareTo(aMatches);
    });

    return alternatives;
  }

  // Method to get muscle groups targeted as a string
  String getMuscleGroupString() {
    return targetMuscles.join(', ');
  }

  // Fetch all exercises (public + user's own)
  static Future<List<Exercise>> fetchExercises() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      final response = await supabase
          .from('exercises')
          .select()
          .or('is_public.eq.true,created_by.eq.$userId')
          .order('created_at');

      return response.map((data) => Exercise.fromMap(data)).toList();
    } catch (e) {
      debugPrint('Error fetching exercises: $e');
      return [];
    }
  }

  // Fetch an exercise by its ID
  static Future<Exercise?> fetchExerciseById(String id) async {
    try {
      final supabase = Supabase.instance.client;

      final response =
          await supabase.from('exercises').select().eq('id', id).single();

      return Exercise.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching exercise by ID: $e');
      return null;
    }
  }

  // Fetch multiple exercises by their IDs
  static Future<Map<String, Exercise>> fetchExercisesByIds(
      List<String> ids) async {
    try {
      if (ids.isEmpty) {
        return {};
      }

      final supabase = Supabase.instance.client;

      // Using .eq with an 'or' clause for each ID as a workaround
      List<Map<String, dynamic>> response = [];

      // We need to query one by one since there's an issue with the .in_ method
      for (String id in ids) {
        final result = await supabase.from('exercises').select().eq('id', id);

        if (result.isNotEmpty) {
          response.addAll(result);
        }
      }

      // Create a map of exercise IDs to Exercise objects
      final Map<String, Exercise> exercisesMap = {};
      for (var data in response) {
        try {
          final exercise = Exercise.fromMap(data);
          exercisesMap[exercise.id] = exercise;
        } catch (e) {
          debugPrint('Error parsing exercise data: $e');
        }
      }

      return exercisesMap;
    } catch (e) {
      debugPrint('Error fetching exercises by IDs: $e');
      return {};
    }
  }

  // Create a new exercise
  static Future<Exercise?> createExercise(Exercise exercise) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Create exercise with current user as creator
      final exerciseData = exercise.toMap();
      exerciseData['created_by'] = userId;

      final response = await supabase
          .from('exercises')
          .insert(exerciseData)
          .select()
          .single();

      return Exercise.fromMap(response);
    } catch (e) {
      debugPrint('Error creating exercise: $e');
      return null;
    }
  }

  // Update an exercise
  Future<Exercise?> updateExercise() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      // Get admin mode status from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isAdmin = prefs.getBool('admin_mode') ?? false;

      // Verify ownership or admin status
      if (createdBy != userId && !isAdmin) {
        throw Exception('You do not own this exercise');
      }

      final response = await supabase
          .from('exercises')
          .update(toMap())
          .eq('id', id)
          .select()
          .single();

      return Exercise.fromMap(response);
    } catch (e) {
      debugPrint('Error updating exercise: $e');
      return null;
    }
  }

  // Delete an exercise
  static Future<bool> deleteExercise(String exerciseId) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      // Get admin mode status from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isAdmin = prefs.getBool('admin_mode') ?? false;

      // First check if the current user is the owner of this exercise
      final exercise = await supabase
          .from('exercises')
          .select('created_by')
          .eq('id', exerciseId)
          .single();

      final exerciseCreator = exercise['created_by'];

      // Verify ownership or admin status
      if (exerciseCreator != userId && !isAdmin) {
        throw Exception('You do not have permission to delete this exercise');
      }

      // Delete exercise (it will be removed from workouts via database cascade)
      await supabase.from('exercises').delete().eq('id', exerciseId);
      return true;
    } catch (e) {
      debugPrint('Error deleting exercise: $e');
      return false;
    }
  }
}
