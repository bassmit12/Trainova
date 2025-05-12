import 'dart:convert';

class WeightPrediction {
  final double predictedWeight;
  final String exercise;
  final double? confidence;
  final List<int>? suggestedReps;
  final int? suggestedSets;
  final String? message;

  WeightPrediction({
    required this.predictedWeight,
    required this.exercise,
    this.confidence,
    this.suggestedReps,
    this.suggestedSets,
    this.message,
  });

  factory WeightPrediction.fromJson(Map<String, dynamic> json) {
    return WeightPrediction(
      predictedWeight: json['predicted_weight'].toDouble(),
      exercise: json['exercise'],
      confidence: json['confidence']?.toDouble(),
      suggestedReps:
          json['suggested_reps'] != null
              ? List<int>.from(json['suggested_reps'])
              : null,
      suggestedSets: json['suggested_sets'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predicted_weight': predictedWeight,
      'exercise': exercise,
      'confidence': confidence,
      'suggested_reps': suggestedReps,
      'suggested_sets': suggestedSets,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'WeightPrediction{predictedWeight: $predictedWeight, exercise: $exercise, confidence: $confidence, suggestedReps: $suggestedReps, suggestedSets: $suggestedSets, message: $message}';
  }
}
