import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/workout_set.dart';
import '../widgets/progressive_overload_suggestion.dart';
import '../utils/format_utils.dart';
import '../services/workout_history_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final int userId;

  const ExerciseDetailScreen({
    Key? key,
    required this.exercise,
    required this.userId,
  }) : super(key: key);

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final WorkoutHistoryService _historyService = WorkoutHistoryService();
  List<Map<String, dynamic>> _exerciseHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExerciseHistory();
  }

  Future<void> _loadExerciseHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the exercise history with just the exerciseId parameter
      final sets = await _historyService.getExerciseHistory(widget.exercise.id);

      // Transform the list of WorkoutSet objects into the expected format
      final List<Map<String, dynamic>> formattedHistory = [];

      // Group sets by date (assuming the sets are already sorted by date)
      final Map<String, List<Map<String, dynamic>>> setsByDate = {};

      for (final set in sets) {
        // Use the first part of the id as the workout identifier (this is just a temporary solution)
        final dateStr = set.id.split('-')[0]; // Using ID as a proxy for date

        if (!setsByDate.containsKey(dateStr)) {
          setsByDate[dateStr] = [];
        }

        setsByDate[dateStr]!.add({
          'set_number': set.setNumber,
          'weight': set.weight,
          'reps': set.reps,
        });
      }

      // Convert the grouped sets to the format expected by the UI
      setsByDate.forEach((dateStr, setList) {
        formattedHistory.add({'date': dateStr, 'sets': setList});
      });

      setState(() {
        _exerciseHistory = formattedHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load exercise history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExerciseHistory,
            tooltip: 'Refresh history',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressChart(),
                    _buildAiSuggestion(),
                    _buildHistoryList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildProgressChart() {
    // A placeholder for a future chart implementation
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Weight Progression Chart',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  Widget _buildAiSuggestion() {
    if (_exerciseHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Complete at least 5 workouts with this exercise to get AI weight suggestions.',
            ),
          ),
        ),
      );
    }

    // Extract previous weights and dates
    final previousWeights = <double>[];
    final previousDates = <DateTime>[];

    // Group by workout date and calculate average weight
    final Map<String, List<double>> workoutWeights = {};

    for (final workout in _exerciseHistory) {
      final date = DateTime.parse(workout['date'] as String);
      final dateStr = date.toIso8601String().split('T')[0];

      if (!workoutWeights.containsKey(dateStr)) {
        workoutWeights[dateStr] = [];
      }

      // Add all set weights to the list for this date
      if (workout['sets'] != null) {
        final sets = workout['sets'] as List<dynamic>;
        for (final set in sets) {
          final weight = set['weight'] as double;
          workoutWeights[dateStr]!.add(weight);
        }
      }
    }

    // Calculate average weight per workout date
    workoutWeights.forEach((dateStr, weights) {
      if (weights.isNotEmpty) {
        final avgWeight = weights.reduce((a, b) => a + b) / weights.length;
        previousWeights.add(avgWeight);
        previousDates.add(DateTime.parse(dateStr));
      }
    });

    // Sort by date
    final sortedIndices = List.generate(previousDates.length, (i) => i)
      ..sort((a, b) => previousDates[a].compareTo(previousDates[b]));

    previousWeights.replaceRange(
      0,
      previousWeights.length,
      sortedIndices.map((i) => previousWeights[i]).toList(),
    );
    previousDates.replaceRange(
      0,
      previousDates.length,
      sortedIndices.map((i) => previousDates[i]).toList(),
    );

    // Use only the last 10 workouts to avoid too much history
    if (previousWeights.length > 10) {
      previousWeights.removeRange(0, previousWeights.length - 10);
      previousDates.removeRange(0, previousDates.length - 10);
    }

    if (previousWeights.length >= 5) {
      return ProgressiveOverloadSuggestion(
        userId: widget.userId,
        exercise: widget.exercise.name,
        previousWeights: previousWeights,
        previousWorkoutDates: previousDates,
      );
    } else {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Complete at least 5 workouts with this exercise to get AI weight suggestions.',
            ),
          ),
        ),
      );
    }
  }

  Widget _buildHistoryList() {
    if (_exerciseHistory.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No workout history for this exercise'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Workout History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _exerciseHistory.length,
            itemBuilder: (context, index) {
              final workout = _exerciseHistory[index];
              final date = DateTime.parse(workout['date'] as String);
              final sets = workout['sets'] as List<dynamic>? ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            FormatUtils.formatDate(date),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '${sets.length} ${sets.length == 1 ? 'set' : 'sets'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const Divider(),
                      ...sets.map<Widget>((set) {
                        final setNum = (set['set_number'] as int?) ?? 0;
                        final weight =
                            (set['weight'] as num?)?.toDouble() ?? 0.0;
                        final reps = (set['reps'] as int?) ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Set $setNum:'),
                              Text(
                                '${FormatUtils.formatWeight(weight)} lbs × $reps reps',
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
