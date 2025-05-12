import 'package:flutter/material.dart';
import '../services/progressive_overload_service.dart';
import '../utils/app_colors.dart';
import '../config/api_config.dart';

class NeuralNetworkDiagnosticScreen extends StatefulWidget {
  const NeuralNetworkDiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<NeuralNetworkDiagnosticScreen> createState() =>
      _NeuralNetworkDiagnosticScreenState();
}

class _NeuralNetworkDiagnosticScreenState
    extends State<NeuralNetworkDiagnosticScreen> {
  final ProgressiveOverloadService _service = ProgressiveOverloadService();
  bool _isLoading = false;
  String _apiStatus = 'Not tested';
  String _exercisesStatus = 'Not tested';
  String _predictionStatus = 'Not tested';
  String _modelInfoStatus = 'Not tested';
  Map<String, dynamic>? _modelInfo;
  List<String>? _exercises;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Neural Network Diagnostics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              title: 'API Connection',
              content: _apiStatus,
              icon: Icons.cloud,
              color: _getStatusColor(_apiStatus),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'API Endpoint Configuration',
              content:
                  'Progressive Overload API URL: ${ApiConfig.progressiveOverloadApiUrl}',
              icon: Icons.settings,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Supported Exercises',
              content: _exercisesStatus,
              icon: Icons.fitness_center,
              color: _getStatusColor(_exercisesStatus),
              details:
                  _exercises != null
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            _exercises!
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text('• $e'),
                                  ),
                                )
                                .toList(),
                      )
                      : null,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Weight Prediction Test',
              content: _predictionStatus,
              icon: Icons.analytics,
              color: _getStatusColor(_predictionStatus),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Model Information',
              content: _modelInfoStatus,
              icon: Icons.model_training,
              color: _getStatusColor(_modelInfoStatus),
              details:
                  _modelInfo != null
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            _modelInfo!.entries
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '${e.key}: ${e.value}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                )
                                .toList(),
                      )
                      : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _runAllTests,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text('RUN ALL TESTS'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    Widget? details,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(fontSize: 16, color: _getStatusColor(content)),
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              details,
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('Success') || status.contains('Connected')) {
      return Colors.green;
    } else if (status.contains('Error') || status.contains('Failed')) {
      return Colors.red;
    } else if (status.contains('Testing')) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
      _apiStatus = 'Testing connection...';
      _exercisesStatus = 'Testing...';
      _predictionStatus = 'Testing...';
      _modelInfoStatus = 'Testing...';
    });

    // Test basic API connection
    try {
      final url = Uri.parse(
        '${ApiConfig.progressiveOverloadApiUrl}/api/health',
      );
      final response = await Future.delayed(
        const Duration(milliseconds: 500),
        () => _service.testConnection(),
      );
      setState(() {
        _apiStatus = 'Connected: ${response['status']}';
      });
    } catch (e) {
      setState(() {
        _apiStatus = 'Error: $e';
      });
    }

    // Test getting supported exercises
    try {
      final exercises = await Future.delayed(
        const Duration(milliseconds: 800),
        () => _service.getSupportedExercises(),
      );
      setState(() {
        _exercisesStatus = 'Success: ${exercises.length} exercises found';
        _exercises = exercises;
      });
    } catch (e) {
      setState(() {
        _exercisesStatus = 'Error: $e';
      });
    }

    // Test prediction
    try {
      final prediction = await Future.delayed(
        const Duration(milliseconds: 1200),
        () => _service.predictNextWeight(
          userId: 1,
          exercise: 'Bench Press',
          previousWeights: [100, 105, 110, 115, 120], // Added 2 more weights
          daysSinceWorkouts: [
            7,
            7,
            7,
            7,
            7,
          ], // Added 2 more days, using 7 days between each workout
        ),
      );
      setState(() {
        _predictionStatus =
            'Success: Predicted ${prediction.predictedWeight} kg';
      });
    } catch (e) {
      setState(() {
        _predictionStatus = 'Error: $e';
      });
    }

    // Test model info
    try {
      final modelInfo = await Future.delayed(
        const Duration(milliseconds: 1500),
        () => _service.getModelInfo(),
      );
      setState(() {
        _modelInfoStatus = 'Success: Model information retrieved';
        _modelInfo = modelInfo;
      });
    } catch (e) {
      setState(() {
        _modelInfoStatus = 'Error: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }
}
