import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_set.dart';
import '../models/workout_history.dart';
import '../models/workout.dart';

class WorkoutSessionService extends ChangeNotifier {
  WorkoutSession? _activeSession;
  final List<WorkoutSession> _sessionHistory = [];
  bool _isLoading = false;
  String? _error;

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
      _activeSession!.addSet(set);
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
  Future<void> updateSet(String setId,
      {double? weight, int? reps, bool? isCompleted}) async {
    if (_activeSession == null) {
      throw Exception('No active workout session');
    }

    _setLoading(true);
    try {
      _activeSession!.updateSet(setId,
          weight: weight, reps: reps, isCompleted: isCompleted);
      await _saveActiveSession();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update set: $e');
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

    // In a real app, also fetch from online database (Supabase)
    // This implementation uses just local storage for simplicity
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
