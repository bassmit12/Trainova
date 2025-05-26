import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// Model class to represent a single set of an exercise in a workout session
class WorkoutSet {
  final String id;
  final String exerciseId;
  final int setNumber;
  double weight;
  int reps;
  bool isCompleted;
  double? predictedWeight; // Added field to track the predicted weight
  DateTime? timestamp;
  int? rir; // Reps in Reserve - how many more reps the user could have done

  WorkoutSet({
    String? id,
    required this.exerciseId,
    required this.setNumber,
    this.weight = 0.0,
    this.reps = 0,
    this.isCompleted = false,
    this.predictedWeight, // Initialize with optional predicted weight
    this.timestamp,
    this.rir, // Initialize with optional RIR value
  }) : id = id ?? const Uuid().v4();

  // Create a copy with updated properties
  WorkoutSet copyWith({
    String? id,
    String? exerciseId,
    int? setNumber,
    double? weight,
    int? reps,
    bool? isCompleted,
    double? predictedWeight,
    DateTime? timestamp,
    int? rir,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      predictedWeight: predictedWeight ?? this.predictedWeight,
      timestamp: timestamp ?? this.timestamp,
      rir: rir ?? this.rir,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'weight': weight,
      'reps': reps,
      'is_completed': isCompleted,
      'predicted_weight': predictedWeight,
      'timestamp': timestamp?.toIso8601String(),
      'rir': rir,
    };
  }

  // Create from Map for retrieval
  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: map['id'],
      exerciseId: map['exercise_id'],
      setNumber: map['set_number'],
      weight:
          (map['weight'] is int)
              ? (map['weight'] as int).toDouble()
              : map['weight'],
      reps: map['reps'],
      isCompleted: map['is_completed'],
      predictedWeight:
          map['predicted_weight'] != null
              ? (map['predicted_weight'] is int)
                  ? (map['predicted_weight'] as int).toDouble()
                  : map['predicted_weight']
              : null,
      timestamp:
          map['timestamp'] != null ? DateTime.parse(map['timestamp']) : null,
      rir: map['rir'],
    );
  }
}

// Model to represent a workout session
class WorkoutSession {
  final String id;
  final String workoutId;
  final DateTime startTime;
  DateTime? endTime;
  final List<WorkoutSet> sets;
  String notes;

  WorkoutSession({
    String? id,
    required this.workoutId,
    DateTime? startTime,
    this.endTime,
    List<WorkoutSet>? sets,
    this.notes = '',
  }) : id = id ?? const Uuid().v4(),
       startTime = startTime ?? DateTime.now(),
       sets = sets ?? [];

  // Check if the workout is completed
  bool get isCompleted => endTime != null;

  // Get duration of workout
  Duration get duration =>
      endTime != null
          ? endTime!.difference(startTime)
          : DateTime.now().difference(startTime);

  // Complete the workout
  void complete() {
    endTime = DateTime.now();
  }

  // Add a set
  void addSet(WorkoutSet set) {
    sets.add(set);
  }

  // Update a set
  void updateSet(
    String setId, {
    double? weight,
    int? reps,
    bool? isCompleted,
    int? rir,
  }) {
    final index = sets.indexWhere((set) => set.id == setId);
    if (index != -1) {
      sets[index] = sets[index].copyWith(
        weight: weight,
        reps: reps,
        isCompleted: isCompleted,
        rir: rir,
      );
    }
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workout_id': workoutId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'sets': sets.map((set) => set.toMap()).toList(),
      'notes': notes,
    };
  }

  // Create from Map for retrieval
  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      id: map['id'],
      workoutId: map['workout_id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      sets:
          (map['sets'] as List).map((set) => WorkoutSet.fromMap(set)).toList(),
      notes: map['notes'] ?? '',
    );
  }
}
