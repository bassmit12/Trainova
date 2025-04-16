import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'workout_set.dart';

class WorkoutHistory {
  final String id;
  final String workoutId;
  final String workoutName;
  final String userId;
  final DateTime completedAt;
  final int durationMinutes;
  final int caloriesBurned;
  final List<WorkoutSet> sets;
  final String? notes;

  WorkoutHistory({
    String? id,
    required this.workoutId,
    required this.workoutName,
    required this.userId,
    required this.completedAt,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.sets,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  // Create a new WorkoutHistory from a WorkoutSession
  factory WorkoutHistory.fromSession(
    WorkoutSession session, {
    required String workoutName,
    required int caloriesBurned,
  }) {
    // Calculate duration in minutes
    final durationMinutes = session.endTime != null && session.startTime != null
        ? session.endTime!.difference(session.startTime).inMinutes
        : 0;

    return WorkoutHistory(
      workoutId: session.workoutId,
      workoutName: workoutName,
      userId: Supabase.instance.client.auth.currentUser!.id,
      completedAt: session.endTime ?? DateTime.now(),
      durationMinutes: durationMinutes,
      caloriesBurned: caloriesBurned,
      sets: session.sets,
      notes: session.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_id': workoutId,
      'workout_name': workoutName,
      'user_id': userId,
      'completed_at': completedAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'sets': sets.map((set) => set.toMap()).toList(),
      'notes': notes,
    };
  }

  factory WorkoutHistory.fromMap(Map<String, dynamic> map) {
    List<WorkoutSet> parsedSets = [];
    if (map['sets'] != null) {
      if (map['sets'] is List<WorkoutSet>) {
        // If sets are already WorkoutSet objects
        parsedSets = map['sets'] as List<WorkoutSet>;
      } else {
        // If sets are maps that need to be converted to WorkoutSet objects
        parsedSets = (map['sets'] as List)
            .map((setData) => setData is WorkoutSet
                ? setData
                : WorkoutSet.fromMap(setData as Map<String, dynamic>))
            .toList();
      }
    }

    return WorkoutHistory(
      id: map['id'],
      workoutId: map['workout_id'],
      workoutName: map['workout_name'],
      userId: map['user_id'],
      completedAt: DateTime.parse(map['completed_at']),
      durationMinutes: map['duration_minutes'],
      caloriesBurned: map['calories_burned'],
      sets: parsedSets,
      notes: map['notes'],
    );
  }

  // Save workout history to Supabase
  static Future<void> saveWorkoutHistory(WorkoutHistory history) async {
    try {
      final supabase = Supabase.instance.client;

      // First, save the main workout history record
      await supabase.from('workout_history').insert({
        'id': history.id,
        'workout_id': history.workoutId,
        'workout_name': history.workoutName,
        'user_id': history.userId,
        'completed_at': history.completedAt.toIso8601String(),
        'duration_minutes': history.durationMinutes,
        'calories_burned': history.caloriesBurned,
        'notes': history.notes,
      });

      // Then save all sets
      for (final set in history.sets) {
        await supabase.from('workout_history_sets').insert({
          'id': set.id,
          'workout_history_id': history.id,
          'exercise_id': set.exerciseId,
          'set_number': set.setNumber,
          'weight': set.weight,
          'reps': set.reps,
          'is_completed': set.isCompleted,
        });
      }
    } catch (e) {
      debugPrint('Error saving workout history: $e');
      throw Exception('Failed to save workout history: $e');
    }
  }

  // Fetch workout history for the current user
  static Future<List<WorkoutHistory>> fetchUserWorkoutHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      debugPrint('Fetching workout history for user ID: $userId');

      if (userId == null) {
        debugPrint('No logged in user found.');
        return [];
      }

      // Fetch workout history records
      final historyResponse = await supabase
          .from('workout_history')
          .select('*')
          .eq('user_id', userId)
          .order('completed_at', ascending: false);

      debugPrint(
          'Found ${historyResponse.length} workout history records in Supabase');

      if (historyResponse.isEmpty) {
        debugPrint('No workout history records found in database');
        // Show all records regardless of user to check if data exists
        try {
          final allRecords = await supabase.from('workout_history').select('*');
          debugPrint(
              'Total workout history records in database: ${allRecords.length}');
          if (allRecords.isNotEmpty) {
            debugPrint('Sample record: ${allRecords.first}');
          }
        } catch (e) {
          debugPrint('Error checking all records: $e');
        }
      }

      List<WorkoutHistory> historyList = [];

      // For each history record, fetch its sets
      for (final historyData in historyResponse) {
        final historyId = historyData['id'];
        debugPrint('Processing history record ID: $historyId');

        // Fetch sets for this workout history
        final setsResponse = await supabase
            .from('workout_history_sets')
            .select()
            .eq('workout_history_id', historyId);

        debugPrint(
            'Found ${setsResponse.length} sets for workout history $historyId');

        // Create WorkoutSet objects - make sure we're properly converting to List<Map>
        final List<WorkoutSet> sets = [];
        for (var setData in setsResponse) {
          // Convert to WorkoutSet
          try {
            sets.add(WorkoutSet.fromMap(Map<String, dynamic>.from(setData)));
          } catch (e) {
            debugPrint('Error parsing set: $e, data: $setData');
          }
        }

        // Create the WorkoutHistory object with sets
        try {
          final completeHistoryData = Map<String, dynamic>.from(historyData);
          completeHistoryData['sets'] = sets; // Add the sets

          historyList.add(WorkoutHistory.fromMap(completeHistoryData));
          debugPrint(
              'Added workout history: ${completeHistoryData['id']} with ${sets.length} sets');
        } catch (e) {
          debugPrint('Error creating WorkoutHistory: $e');
        }
      }

      debugPrint('Fetched ${historyList.length} workout histories');
      return historyList;
    } catch (e) {
      debugPrint('Error fetching workout history: $e');
      return [];
    }
  }
}
