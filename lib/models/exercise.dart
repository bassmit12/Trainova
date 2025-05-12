import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Exercise {
  final String id; // Changed to String to match how it's used in the codebase
  final String name;
  final String description;
  final String category;
  final String imageUrl;
  final String? muscleGroup;
  final bool isCustom;
  final int sets;
  final int reps;
  final List<String> targetMuscles;
  final String difficulty;
  final bool isPublic;
  final String? createdBy;

  Exercise({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    this.imageUrl = '',
    this.muscleGroup,
    this.isCustom = false,
    this.sets = 3,
    this.reps = 10,
    this.targetMuscles = const [],
    this.difficulty = 'Beginner',
    this.isPublic = true,
    this.createdBy,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      muscleGroup: json['muscle_group'] as String?,
      isCustom: json['is_custom'] as bool? ?? false,
      sets: json['sets'] as int? ?? 3,
      reps: json['reps'] as int? ?? 10,
      targetMuscles:
          json['target_muscles'] != null
              ? List<String>.from(json['target_muscles'])
              : [],
      difficulty: json['difficulty'] as String? ?? 'Beginner',
      isPublic: json['is_public'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
    );
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'].toString(),
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Strength',
      imageUrl: map['image_url'] as String? ?? '',
      muscleGroup: map['muscle_group'] as String?,
      isCustom: map['is_custom'] as bool? ?? false,
      sets: map['sets'] as int? ?? 3,
      reps: map['reps'] as int? ?? 10,
      targetMuscles:
          map['target_muscles'] != null
              ? List<String>.from(map['target_muscles'])
              : [],
      difficulty: map['difficulty'] as String? ?? 'Beginner',
      isPublic: map['is_public'] as bool? ?? true,
      createdBy: map['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'image_url': imageUrl,
      'muscle_group': muscleGroup,
      'is_custom': isCustom,
      'sets': sets,
      'reps': reps,
      'target_muscles': targetMuscles,
      'difficulty': difficulty,
      'is_public': isPublic,
      'created_by': createdBy,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? imageUrl,
    String? muscleGroup,
    bool? isCustom,
    int? sets,
    int? reps,
    List<String>? targetMuscles,
    String? difficulty,
    bool? isPublic,
    String? createdBy,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      isCustom: isCustom ?? this.isCustom,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      difficulty: difficulty ?? this.difficulty,
      isPublic: isPublic ?? this.isPublic,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  String getMuscleGroupString() {
    if (targetMuscles.isNotEmpty) {
      return targetMuscles.join(', ');
    }
    return muscleGroup ?? '';
  }

  static Future<List<Exercise>> fetchExercises() async {
    try {
      final client = Supabase.instance.client;
      final response = await client.from('exercises').select();

      final data = response as List<dynamic>;
      return data.map((item) => Exercise.fromMap(item)).toList();
    } catch (e) {
      print('Error fetching exercises: $e');
      return [];
    }
  }

  static Future<Map<String, Exercise>> fetchExercisesByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return {};

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('exercises')
          .select()
          .inFilter('id', ids);

      final data = response as List<dynamic>;
      final exercises = data.map((item) => Exercise.fromMap(item)).toList();

      return {for (var exercise in exercises) exercise.id: exercise};
    } catch (e) {
      print('Error fetching exercises by ids: $e');
      return {};
    }
  }

  static Future<Exercise?> createExercise(Exercise exercise) async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      final exerciseData = exercise.toMap();

      exerciseData.remove('id');

      if (userId != null) {
        exerciseData['created_by'] = userId;
      }

      final response =
          await client.from('exercises').insert(exerciseData).select();

      if (response != null && (response as List).isNotEmpty) {
        return Exercise.fromMap(response[0]);
      }

      return null;
    } catch (e) {
      print('Error creating exercise: $e');
      return null;
    }
  }

  static Future<bool> deleteExercise(String id) async {
    try {
      final client = Supabase.instance.client;
      await client.from('exercises').delete().eq('id', id);

      return true;
    } catch (e) {
      print('Error deleting exercise: $e');
      return false;
    }
  }

  static Future<List<Exercise>> getAlternativeExercises(
    Exercise exercise,
  ) async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('exercises')
          .select()
          .neq('id', exercise.id);

      final data = response as List<dynamic>;
      final allExercises = data.map((item) => Exercise.fromMap(item)).toList();

      return allExercises.where((e) {
        return e.targetMuscles.any(
          (muscle) => exercise.targetMuscles.contains(muscle),
        );
      }).toList();
    } catch (e) {
      print('Error fetching alternative exercises: $e');
      return [];
    }
  }

  Future<Exercise?> updateExercise() async {
    try {
      final client = Supabase.instance.client;

      final exerciseData = toMap();

      final response =
          await client
              .from('exercises')
              .update(exerciseData)
              .eq('id', id)
              .select();

      if (response != null && (response as List).isNotEmpty) {
        return Exercise.fromMap(response[0]);
      }

      return null;
    } catch (e) {
      print('Error updating exercise: $e');
      return null;
    }
  }

  @override
  String toString() {
    return 'Exercise{id: $id, name: $name, category: $category, sets: $sets, reps: $reps}';
  }
}
