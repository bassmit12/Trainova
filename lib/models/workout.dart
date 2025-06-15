import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'exercise.dart';
import 'workout_history.dart';
import '../services/cache_service.dart'; // Add cache service

class Workout {
  final String id;
  final String name;
  final String description;
  final String type; // e.g., "Strength", "Cardio", etc.
  final String imageUrl;
  final String duration;
  final String difficulty;
  final int caloriesBurned;
  final List<Exercise> exercises;
  final bool isPublic;
  final String? createdBy;
  final DateTime? createdAt;

  const Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.imageUrl,
    required this.duration,
    required this.difficulty,
    required this.caloriesBurned,
    required this.exercises,
    this.isPublic = false,
    this.createdBy,
    this.createdAt,
  });

  // Factory to convert from Supabase response
  factory Workout.fromMap(
    Map<String, dynamic> map,
    List<Exercise> workoutExercises,
  ) {
    return Workout(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      type: map['type'],
      imageUrl: map['image_url'],
      duration: map['duration'],
      difficulty: map['difficulty'],
      caloriesBurned: map['calories_burned'],
      exercises: workoutExercises,
      isPublic: map['is_public'] ?? false,
      createdBy: map['created_by'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  // Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'image_url': imageUrl,
      'duration': duration,
      'difficulty': difficulty,
      'calories_burned': caloriesBurned,
      'is_public': isPublic,
      'created_by': createdBy,
    };
  }

  // Fetch all workouts (public + user's own) with caching
  static Future<List<Workout>> fetchWorkouts() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      final cache = CacheService();

      // Check cache first
      final cacheKey = 'cache_workouts_$userId';
      final cachedWorkouts = cache.get<List<dynamic>>(
        cacheKey,
        maxAge: const Duration(minutes: 10), // Cache for 10 minutes
      );
      
      if (cachedWorkouts != null) {
        debugPrint('Using cached workouts data');
        return cachedWorkouts.map((data) => _workoutFromCachedData(data)).toList();
      }

      debugPrint('Fetching workouts from database');

      // Fetch workouts visible to current user
      final response = await supabase
          .from('workouts')
          .select()
          .or('is_public.eq.true,created_by.eq.$userId')
          .order('created_at');

      // Create a list to hold the results
      final List<Workout> workouts = [];
      final List<Map<String, dynamic>> workoutDataForCache = [];

      // For each workout, fetch its exercises
      for (final workoutData in response) {
        final workoutId = workoutData['id'];

        // Get exercises for this workout with custom sets and reps
        final exercisesResponse = await supabase
            .from('workout_exercises')
            .select('exercise:exercise_id(*), custom_sets, custom_reps')
            .eq('workout_id', workoutId)
            .order('order_index');

        final List<Exercise> exercises = [];
        final List<Map<String, dynamic>> exerciseDataForCache = [];
        
        for (final item in exercisesResponse) {
          final exerciseData = item['exercise'] as Map<String, dynamic>;
          final customSets = item['custom_sets'];
          final customReps = item['custom_reps'];

          // Create the exercise with base data
          Exercise exercise = Exercise.fromMap(exerciseData);

          // Override with custom sets and reps if available
          if (customSets != null) {
            exercise = exercise.copyWith(sets: customSets);
          }
          if (customReps != null) {
            exercise = exercise.copyWith(reps: customReps);
          }

          exercises.add(exercise);
          
          // Store exercise data for cache
          exerciseDataForCache.add({
            'exercise_data': exerciseData,
            'custom_sets': customSets,
            'custom_reps': customReps,
          });
        }

        final workout = Workout.fromMap(workoutData, exercises);
        workouts.add(workout);
        
        // Store workout data for cache
        workoutDataForCache.add({
          'workout_data': workoutData,
          'exercises_data': exerciseDataForCache,
        });
      }

      // Cache the results
      await cache.store(cacheKey, workoutDataForCache, duration: const Duration(minutes: 10));

      return workouts;
    } catch (e) {
      debugPrint('Error fetching workouts: $e');
      return [];
    }
  }

  // Helper method to reconstruct workout from cached data
  static Workout _workoutFromCachedData(Map<String, dynamic> cachedData) {
    final workoutData = cachedData['workout_data'] as Map<String, dynamic>;
    final exercisesData = cachedData['exercises_data'] as List<dynamic>;
    
    final List<Exercise> exercises = exercisesData.map((item) {
      final exerciseData = item['exercise_data'] as Map<String, dynamic>;
      final customSets = item['custom_sets'];
      final customReps = item['custom_reps'];
      
      Exercise exercise = Exercise.fromMap(exerciseData);
      
      if (customSets != null) {
        exercise = exercise.copyWith(sets: customSets);
      }
      if (customReps != null) {
        exercise = exercise.copyWith(reps: customReps);
      }
      
      return exercise;
    }).toList();
    
    return Workout.fromMap(workoutData, exercises);
  }

  // Fetch a single workout by ID with caching
  static Future<Workout?> fetchWorkoutById(String workoutId) async {
    try {
      final cache = CacheService();
      
      // Check cache first
      final cacheKey = 'cache_workout_$workoutId';
      final cachedWorkout = cache.get<Map<String, dynamic>>(
        cacheKey,
        maxAge: const Duration(minutes: 15), // Cache individual workouts longer
      );
      
      if (cachedWorkout != null) {
        debugPrint('Using cached workout data for ID: $workoutId');
        return _workoutFromCachedData(cachedWorkout);
      }

      debugPrint('Fetching workout from database for ID: $workoutId');
      
      final supabase = Supabase.instance.client;

      // Get workout data
      final workoutResponse =
          await supabase.from('workouts').select().eq('id', workoutId).single();

      // Get exercises for this workout
      final exercisesResponse = await supabase
          .from('workout_exercises')
          .select('exercise:exercise_id(*), custom_sets, custom_reps')
          .eq('workout_id', workoutId)
          .order('order_index');

      final List<Exercise> exercises = [];
      final List<Map<String, dynamic>> exerciseDataForCache = [];
      
      for (final item in exercisesResponse) {
        final exerciseData = item['exercise'] as Map<String, dynamic>;
        final customSets = item['custom_sets'];
        final customReps = item['custom_reps'];

        // Create the exercise with base data
        Exercise exercise = Exercise.fromMap(exerciseData);

        // Override with custom sets and reps if available
        if (customSets != null) {
          exercise = exercise.copyWith(sets: customSets);
        }
        if (customReps != null) {
          exercise = exercise.copyWith(reps: customReps);
        }

        exercises.add(exercise);
        
        // Store exercise data for cache
        exerciseDataForCache.add({
          'exercise_data': exerciseData,
          'custom_sets': customSets,
          'custom_reps': customReps,
        });
      }

      final workout = Workout.fromMap(workoutResponse, exercises);
      
      // Cache the result
      final dataForCache = {
        'workout_data': workoutResponse,
        'exercises_data': exerciseDataForCache,
      };
      await cache.store(cacheKey, dataForCache, duration: const Duration(minutes: 15));

      return workout;
    } catch (e) {
      debugPrint('Error fetching workout by ID: $e');
      return null;
    }
  }

  // Create a new workout with cache invalidation
  static Future<Workout?> createWorkout(Workout workout) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Start a Postgres transaction
      final workoutData = workout.toMap();
      workoutData['created_by'] = userId;

      // Insert the workout
      final workoutResponse =
          await supabase.from('workouts').insert(workoutData).select().single();

      final workoutId = workoutResponse['id'];

      // Add exercises to workout
      for (int i = 0; i < workout.exercises.length; i++) {
        final exercise = workout.exercises[i];

        // If exercise doesn't exist yet, create it
        String exerciseId = exercise.id;
        if (exerciseId.isEmpty || exerciseId == 'new') {
          final newExercise = await Exercise.createExercise(
            exercise.copyWith(createdBy: userId),
          );
          if (newExercise == null) throw Exception('Failed to create exercise');
          exerciseId = newExercise.id;
        }

        // Add to workout_exercises junction table with custom sets and reps
        await supabase.from('workout_exercises').insert({
          'workout_id': workoutId,
          'exercise_id': exerciseId,
          'order_index': i,
          'custom_sets': exercise.sets,
          // We don't set custom_reps as reps will be determined by AI
        });
      }

      // Invalidate workouts cache
      final cache = CacheService();
      await cache.remove('cache_workouts_$userId');

      // Return the created workout with exercises
      return fetchWorkoutById(workoutId);
    } catch (e) {
      debugPrint('Error creating workout: $e');
      return null;
    }
  }

  // Update an existing workout with cache invalidation
  Future<Workout?> updateWorkout() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      // Get admin mode status from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isAdmin = prefs.getBool('admin_mode') ?? false;

      // Verify ownership or admin status
      if (createdBy != userId && !isAdmin) {
        throw Exception('You do not have permission to edit this workout');
      }

      // Update the workout details
      await supabase.from('workouts').update(toMap()).eq('id', id);

      // Remove existing workout_exercises entries
      await supabase.from('workout_exercises').delete().eq('workout_id', id);

      // Re-add exercises with updated order
      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];

        // If exercise doesn't exist yet, create it
        String exerciseId = exercise.id;
        if (exerciseId.isEmpty || exerciseId == 'new') {
          final newExercise = await Exercise.createExercise(
            exercise.copyWith(createdBy: userId),
          );
          if (newExercise == null) throw Exception('Failed to create exercise');
          exerciseId = newExercise.id;
        }

        // Add to workout_exercises junction table with custom sets and reps
        await supabase.from('workout_exercises').insert({
          'workout_id': id,
          'exercise_id': exerciseId,
          'order_index': i,
          'custom_sets': exercise.sets,
          'custom_reps': exercise.reps,
        });
      }

      // Invalidate related caches
      final cache = CacheService();
      await cache.remove('cache_workouts_$userId');
      await cache.remove('cache_workout_$id');

      // Return the updated workout
      return fetchWorkoutById(id);
    } catch (e) {
      debugPrint('Error updating workout: $e');
      return null;
    }
  }

  // Delete a workout with cache invalidation
  Future<bool> deleteWorkout() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      // Get admin mode status from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final isAdmin = prefs.getBool('admin_mode') ?? false;

      // Verify ownership or admin status
      if (createdBy != userId && !isAdmin) {
        throw Exception('You do not have permission to delete this workout');
      }

      // Delete workout (workout_exercises entries will be deleted by CASCADE)
      await supabase.from('workouts').delete().eq('id', id);

      // Invalidate related caches
      final cache = CacheService();
      await cache.remove('cache_workouts_$userId');
      await cache.remove('cache_workout_$id');

      return true;
    } catch (e) {
      debugPrint('Error deleting workout: $e');
      return false;
    }
  }

  // Calculate workout statistics with caching
  static Future<Map<String, dynamic>> calculateWorkoutStatistics({
    int daysBack = 30,
  }) async {
    try {
      final cache = CacheService();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      // Check cache first
      final cacheKey = 'cache_workout_stats_${userId}_${daysBack}d';
      final cachedStats = cache.get<Map<String, dynamic>>(
        cacheKey,
        maxAge: const Duration(hours: 1), // Cache stats for 1 hour
      );
      
      if (cachedStats != null) {
        debugPrint('Using cached workout statistics');
        return cachedStats;
      }

      debugPrint('Calculating workout statistics from database');

      // Fetch workout history
      final List<WorkoutHistory> history =
          await WorkoutHistory.fetchUserWorkoutHistory();

      // Filter for workouts within the specified time range
      final DateTime cutoffDate = DateTime.now().subtract(
        Duration(days: daysBack),
      );
      final List<WorkoutHistory> recentWorkouts =
          history
              .where((workout) => workout.completedAt.isAfter(cutoffDate))
              .toList();

      // Calculate stats
      final int workoutCount = recentWorkouts.length;
      int totalCaloriesBurned = 0;
      int totalMinutes = 0;

      for (var workout in recentWorkouts) {
        totalCaloriesBurned += workout.caloriesBurned;
        totalMinutes += workout.durationMinutes;
      }

      // Convert minutes to hours with one decimal place
      final double hoursSpent = totalMinutes / 60;

      final stats = {
        'workoutCount': workoutCount,
        'caloriesBurned': totalCaloriesBurned,
        'hoursSpent': hoursSpent,
        'timeRange': daysBack,
      };

      // Cache the results
      await cache.store(cacheKey, stats, duration: const Duration(hours: 1));

      return stats;
    } catch (e) {
      debugPrint('Error calculating workout statistics: $e');
      return {
        'workoutCount': 0,
        'caloriesBurned': 0,
        'hoursSpent': 0.0,
        'timeRange': daysBack,
      };
    }
  }

  // Initialize public workouts for the first time
  static Future<bool> initializePublicWorkouts() async {
    try {
      final supabase = Supabase.instance.client;

      // Call the stored procedure to create default workouts
      await supabase.rpc('create_default_public_workouts');

      return true;
    } catch (e) {
      debugPrint('Error initializing public workouts: $e');
      return false;
    }
  }
}
