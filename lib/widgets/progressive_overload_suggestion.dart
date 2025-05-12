import 'package:flutter/material.dart';
import '../models/weight_prediction.dart';
import '../services/progressive_overload_service.dart';
import '../utils/format_utils.dart';

class ProgressiveOverloadSuggestion extends StatefulWidget {
  final int userId;
  final String exercise;
  final List<double> previousWeights;
  final List<DateTime> previousWorkoutDates;

  const ProgressiveOverloadSuggestion({
    Key? key,
    required this.userId,
    required this.exercise,
    required this.previousWeights,
    required this.previousWorkoutDates,
  }) : super(key: key);

  @override
  State<ProgressiveOverloadSuggestion> createState() =>
      _ProgressiveOverloadSuggestionState();
}

class _ProgressiveOverloadSuggestionState
    extends State<ProgressiveOverloadSuggestion> {
  final ProgressiveOverloadService _service = ProgressiveOverloadService();
  bool _isLoading = false;
  WeightPrediction? _prediction;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPrediction();
  }

  Future<void> _fetchPrediction() async {
    if (widget.previousWeights.isEmpty || widget.previousWorkoutDates.isEmpty) {
      setState(() {
        _errorMessage = 'Not enough workout history for a prediction';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Calculate days between workouts
      final List<int> daysSinceWorkouts = [];
      for (int i = 0; i < widget.previousWorkoutDates.length - 1; i++) {
        final difference =
            widget.previousWorkoutDates[i + 1]
                .difference(widget.previousWorkoutDates[i])
                .inDays;
        daysSinceWorkouts.add(difference);
      }

      // Add days since last workout to today
      final daysSinceLastWorkout =
          DateTime.now().difference(widget.previousWorkoutDates.last).inDays;
      daysSinceWorkouts.add(daysSinceLastWorkout);

      final prediction = await _service.predictNextWeight(
        userId: widget.userId,
        exercise: widget.exercise,
        previousWeights: widget.previousWeights,
        daysSinceWorkouts: daysSinceWorkouts,
      );

      setState(() {
        _prediction = prediction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get prediction: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Weight Suggestion',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _fetchPrediction,
                  tooltip: 'Refresh prediction',
                ),
              ],
            ),
            const Divider(),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            else if (_prediction != null)
              _buildPredictionContent(context)
            else
              const Text('No prediction available'),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionContent(BuildContext context) {
    final prediction = _prediction!;
    final confidenceLevel = _getConfidenceLevel(prediction.confidence ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Weight:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${prediction.predictedWeight.toStringAsFixed(1)} lbs',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Confidence:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  confidenceLevel,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getConfidenceColor(prediction.confidence ?? 0),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (prediction.suggestedReps != null &&
            prediction.suggestedReps!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suggested Sets & Reps:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: List.generate(
                  prediction.suggestedReps!.length,
                  (index) => Chip(
                    label: Text(
                      'Set ${index + 1}: ${prediction.suggestedReps![index]} reps',
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Previous: ${widget.previousWeights.isNotEmpty ? widget.previousWeights.last.toStringAsFixed(1) : "N/A"} lbs',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 8),
            if (widget.previousWeights.isNotEmpty &&
                prediction.predictedWeight > widget.previousWeights.last)
              Text(
                '↑ ${(prediction.predictedWeight - widget.previousWeights.last).toStringAsFixed(1)} lbs',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _getConfidenceLevel(double confidence) {
    if (confidence >= 0.85) return 'High';
    if (confidence >= 0.7) return 'Medium';
    return 'Low';
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.85) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }
}
