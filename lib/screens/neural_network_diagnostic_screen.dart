import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/progressive_overload_service.dart';
import '../utils/app_colors.dart';
import '../config/api_config.dart';
import '../config/env_config.dart';
import '../services/config_service.dart';
import '../models/workout_set.dart'; // Add import for WorkoutSet

class NeuralNetworkDiagnosticScreen extends StatefulWidget {
  const NeuralNetworkDiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<NeuralNetworkDiagnosticScreen> createState() =>
      _NeuralNetworkDiagnosticScreenState();
}

class _NeuralNetworkDiagnosticScreenState
    extends State<NeuralNetworkDiagnosticScreen> {
  late ProgressiveOverloadService _service;
  bool _isLoading = false;
  String _apiStatus = 'Not tested';
  String _feedbackStatus = 'Not tested';
  String _predictionStatus = 'Not tested';
  String _statsStatus = 'Not tested';
  Map<String, dynamic>? _statsInfo;

  @override
  void initState() {
    super.initState();
    _initializeService();
    // Listen for changes to the API URL
    final configService = Provider.of<ConfigService>(context, listen: false);
    configService.addListener(_onConfigChanged);
  }
  
  @override
  void dispose() {
    // Remove listener when widget is disposed
    final configService = Provider.of<ConfigService>(context, listen: false);
    configService.removeListener(_onConfigChanged);
    super.dispose();
  }
  
  void _initializeService() {
    _service = ProgressiveOverloadService();
  }
  
  void _onConfigChanged() {
    setState(() {
      // Reinitialize the service with the updated URL
      _initializeService();
      // Reset test statuses
      _apiStatus = 'Not tested';
      _feedbackStatus = 'Not tested';
      _predictionStatus = 'Not tested';
      _statsStatus = 'Not tested';
      _statsInfo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback System Diagnostics')),
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
                  'Feedback API URL: ${EnvConfig.feedbackApiUrl}',
              icon: Icons.settings,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Feedback System',
              content: _feedbackStatus,
              icon: Icons.feedback,
              color: _getStatusColor(_feedbackStatus),
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
              title: 'System Statistics',
              content: _statsStatus,
              icon: Icons.auto_graph,
              color: _getStatusColor(_statsStatus),
              details:
                  _statsInfo != null
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            _statsInfo!.entries
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
      _feedbackStatus = 'Testing...';
      _predictionStatus = 'Testing...';
      _statsStatus = 'Testing...';
    });

    // Test basic API connection
    try {
      final connected = await Future.delayed(
        const Duration(milliseconds: 500),
        () => _service.testFeedbackApiConnection(),
      );
      setState(() {
        _apiStatus = connected ? 'Connected: API is online' : 'Failed to connect to API';
      });
    } catch (e) {
      setState(() {
        _apiStatus = 'Error: $e';
      });
    }

    // Test feedback system
    try {
      final result = await Future.delayed(
        const Duration(milliseconds: 800),
        () => _service.sendPredictionFeedback(
          exercise: 'Test Exercise',
          predictedWeight: 100.0,
          actualWeight: 102.5,
          success: true,
          reps: 10,
        ),
      );
      setState(() {
        _feedbackStatus = result['error'] != null 
            ? 'Error: ${result['error']}' 
            : 'Success: ${result['message'] ?? 'Feedback recorded'}';
      });
    } catch (e) {
      setState(() {
        _feedbackStatus = 'Error: $e';
      });
    }

    // Test prediction with sample data
    try {
      // Create sample workout sets for testing
      final sampleSets = [
        WorkoutSet(
          exerciseId: 'Test Exercise',
          setNumber: 1,
          weight: 100.0,
          reps: 10,
          isCompleted: true,
          timestamp: DateTime.now().subtract(const Duration(days: 14)),
        ),
        WorkoutSet(
          exerciseId: 'Test Exercise',
          setNumber: 1,
          weight: 105.0,
          reps: 10,
          isCompleted: true,
          timestamp: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];
      
      final prediction = await Future.delayed(
        const Duration(milliseconds: 1200),
        () => _service.getFeedbackPrediction('Test Exercise', sampleSets),
      );
      setState(() {
        _predictionStatus = prediction != null
            ? 'Success: Predicted ${prediction.predictedWeight} kg with ${prediction.confidence! * 100}% confidence'
            : 'Failed to get prediction';
      });
    } catch (e) {
      setState(() {
        _predictionStatus = 'Error: $e';
      });
    }

    // Test model stats
    try {
      final stats = await Future.delayed(
        const Duration(milliseconds: 1500),
        () => _service.getFeedbackModelStats(),
      );
      setState(() {
        _statsStatus = stats['error'] != null
            ? 'Error: ${stats['error']}'
            : 'Success: System statistics retrieved';
        _statsInfo = stats;
      });
    } catch (e) {
      setState(() {
        _statsStatus = 'Error: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }
}
