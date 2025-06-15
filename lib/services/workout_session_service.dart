import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_set.dart';
import '../models/workout_history.dart';
import '../models/workout.dart';
import '../services/progressive_overload_service.dart';

class WorkoutSessionService extends ChangeNotifier {
  WorkoutSession? _activeSession;
  final List<WorkoutSession> _sessionHistory = [];
  bool _isLoading = false;
  String? _error;
  final ProgressiveOverloadService _progressiveOverloadService =
      ProgressiveOverloadService();

  // Getters
  WorkoutSession? get activeSession => _activeSession;
  List<WorkoutSession> get sessionHistory => _sessionHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSession => _activeSession != null;

  // Initialize the service
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Load active session from local storage
      await _loadActiveSession();
      // Load session history
      await _loadSessionHistory();
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Start a new workout session
  Future<WorkoutSession> startWorkout(String workoutId) async {
    if (_activeSession != null) {
      throw Exception('A workout session is already in progress');
    }

    _setLoading(true);
    try {
      final session = WorkoutSession(workoutId: workoutId);
      _activeSession = session;
      await _saveActiveSession();
      notifyListeners();
      return session;
    } catch (e) {
      _setError('Failed to start workout: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Add a set to the active session
  Future<void> addSet(WorkoutSet set) async {
    if (_activeSession == null) {
      throw Exception('No active workout session');
    }

    _setLoading(true);
    try {
      // Set timestamp to current time
      final setWithTimestamp = set.copyWith(timestamp: DateTime.now());
      _activeSession!.addSet(setWithTimestamp);
      await _saveActiveSession();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add set: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update a set in the active session
  Future<void> updateSet(
    String setId, {
    double? weight,
    int? reps,
    bool? isCompleted,
    int? rir,
  }) async {
    if (_activeSession == null) {
      throw Exception('No active workout session');
    }

    _setLoading(true);
    try {
      final index = _activeSession!.sets.indexWhere((set) => set.id == setId);
      if (index != -1) {
        _activeSession!.sets[index] = _activeSession!.sets[index].copyWith(
          weight: weight,
          reps: reps,
          isCompleted: isCompleted,
          rir: rir,
        );
        await _saveActiveSession();
        notifyListeners();
      } else {
        throw Exception('Set not found');
      }
    } catch (e) {
      _setError('Failed to update set: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Associate a predicted weight with a set
  Future<void> savePredictedWeight(String setId, double predictedWeight) async {
    if (_activeSession == null) {
      throw Exception('No active workout session');
    }

    _setLoading(true);
    try {
      final index = _activeSession!.sets.indexWhere((set) => set.id == setId);
      if (index != -1) {
        final updatedSet = _activeSession!.sets[index].copyWith(
          predictedWeight: predictedWeight,
        );
        _activeSession!.sets[index] = updatedSet;
        await _saveActiveSession();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to save predicted weight: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Complete the active workout session
  Future<void> completeWorkout() async {
    if (_activeSession == null) {
      throw Exception('No active workout session');
    }

    _setLoading(true);
    try {
      _activeSession!.complete();

      // Send feedback to the feedback-based prediction system for each completed set
      await _sendFeedbackForCompletedSets();

      await _saveWorkoutSession(_activeSession!);
      _sessionHistory.add(_activeSession!);
      _activeSession = null;
      await _saveActiveSession();
      await _saveSessionHistory();
      notifyListeners();
    } catch (e) {
      _setError('Failed to complete workout: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Send feedback for all completed sets that had predictions
  Future<void> _sendFeedbackForCompletedSets() async {
    if (_activeSession == null) return;

    // Group sets by exercise ID to send one feedback per exercise
    final exerciseSetMap = <String, List<WorkoutSet>>{};

    for (final set in _activeSession!.sets.where(
      (s) => s.isCompleted && s.predictedWeight != null,
    )) {
      if (!exerciseSetMap.containsKey(set.exerciseId)) {
        exerciseSetMap[set.exerciseId] = [];
      }
      exerciseSetMap[set.exerciseId]!.add(set);
    }

    // For each exercise, send feedback based on the average of completed sets
    for (final exerciseId in exerciseSetMap.keys) {
      final sets = exerciseSetMap[exerciseId]!;

      // Calculate average actual weight and predicted weight
      final averageActualWeight =
          sets.map((s) => s.weight).reduce((a, b) => a + b) / sets.length;

      // We know predictedWeight is not null because of the filter in the where clause above
      final averagePredictedWeight =
          sets.map((s) => s.predictedWeight!).reduce((a, b) => a + b) /
          sets.length;

      // Calculate average reps
      final averageReps =
          (sets.map((s) => s.reps).reduce((a, b) => a + b) / sets.length)
              .round();

      // Send feedback to the API
      try {
        await _progressiveOverloadService.sendPredictionFeedback(
          exercise: exerciseId,
          predictedWeight: averagePredictedWeight,
          actualWeight: averageActualWeight,
          success:
              true, // We assume the workout was successful since the sets are completed
          reps: averageReps,
        );
        debugPrint(
          'Feedback sent for exercise $exerciseId - Predicted: $averagePredictedWeight, Actual: $averageActualWeight',
        );
      } catch (e) {
        // Log but don't stop workout completion
        debugPrint('Failed to send feedback for exercise $exerciseId: $e');
      }
    }
  }

  // Cancel the active workout session
  Future<void> cancelWorkout() async {
    if (_activeSession == null) return;

    _setLoading(true);
    try {
      _activeSession = null;
      await _saveActiveSession();
      notifyListeners();
    } catch (e) {
      _setError('Failed to cancel workout: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update the notes for the active session
  Future<void> updateNotes(String notes) async {
    if (_activeSession == null) {
      throw Exception('No active workout session');
    }

    _setLoading(true);
    try {
      _activeSession!.notes = notes;
      await _saveActiveSession();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update notes: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Load the active session from storage
  Future<void> _loadActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionJson = prefs.getString('active_workout_session');
    if (sessionJson != null) {
      try {
        final Map<String, dynamic> sessionMap = jsonDecode(sessionJson);
        _activeSession = WorkoutSession.fromMap(sessionMap);
      } catch (e) {
        debugPrint('Error parsing active session: $e');
        // Clear invalid data
        await prefs.remove('active_workout_session');
      }
    }
  }

  // Save the active session to storage
  Future<void> _saveActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeSession == null) {
      await prefs.remove('active_workout_session');
    } else {
      final String sessionJson = jsonEncode(_activeSession!.toMap());
      await prefs.setString('active_workout_session', sessionJson);
    }
  }

  // Load session history from storage and Supabase
  Future<void> _loadSessionHistory() async {
    _sessionHistory.clear();

    // Load from local storage first
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('workout_session_history');
    if (historyJson != null) {
      try {
        final List<dynamic> historyList = jsonDecode(historyJson);
        for (var sessionMap in historyList) {
          _sessionHistory.add(WorkoutSession.fromMap(sessionMap));
        }
      } catch (e) {
        debugPrint('Error parsing session history: $e');
        // Clear invalid data
        await prefs.remove('workout_session_history');
      }
    }

    // Fetch from Supabase for cross-device sync
    // Currently using local storage with plans for cloud sync
  }

  // Save session history to storage
  Future<void> _saveSessionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> historyMaps =
        _sessionHistory.map((session) => session.toMap()).toList();
    await prefs.setString('workout_session_history', jsonEncode(historyMaps));
  }

  // Save a completed workout session to Supabase
  Future<void> _saveWorkoutSession(WorkoutSession session) async {
    try {
      // First get workout details to get the name
      final workout = await Workout.fetchWorkoutById(session.workoutId);
      if (workout == null) {
        throw Exception('Failed to get workout details');
      }

      // Create workout history object
      final workoutHistory = WorkoutHistory.fromSession(
        session,
        workoutName: workout.name,
        caloriesBurned: workout.caloriesBurned,
      );

      // Save to Supabase
      await WorkoutHistory.saveWorkoutHistory(workoutHistory);
    } catch (e) {
      debugPrint('Error saving session to Supabase: $e');
      _setError('Failed to save workout session: $e');
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _error = null;
    }
    notifyListeners();
  }

  // Helper method to set error
  void _setError(String error) {
    _error = error;
    debugPrint(error);
    notifyListeners();
  }
}
