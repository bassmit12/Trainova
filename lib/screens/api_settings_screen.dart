import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _neuralNetworkController = TextEditingController();
  final TextEditingController _feedbackApiController = TextEditingController();
  
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _neuralNetworkController.text = prefs.getString('NEURAL_NETWORK_API_URL') ?? EnvConfig.neuralNetworkApiUrl;
      _feedbackApiController.text = prefs.getString('FEEDBACK_API_URL') ?? EnvConfig.feedbackApiUrl;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('NEURAL_NETWORK_API_URL', _neuralNetworkController.text.trim());
      await prefs.setString('FEEDBACK_API_URL', _feedbackApiController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API settings saved successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save settings: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _neuralNetworkController.dispose();
    _feedbackApiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Settings'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Configure API Server Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextFormField(
              controller: _neuralNetworkController,
              decoration: const InputDecoration(
                labelText: 'Neural Network API URL',
                hintText: 'e.g., http://192.168.1.100:8000',
                helperText: 'The URL of your neural network prediction server',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the neural network API URL';
                }
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'URL must start with http:// or https://';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _feedbackApiController,
              decoration: const InputDecoration(
                labelText: 'Feedback API URL',
                hintText: 'e.g., http://192.168.1.100:8001',
                helperText: 'The URL of your feedback-based prediction server',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the feedback API URL';
                }
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'URL must start with http:// or https://';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Settings'),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About API Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'These settings control which servers your app connects to for workout predictions.'
                      '\n\n'
                      'Neural Network API: The traditional neural network prediction model.'
                      '\n\n'
                      'Feedback API: The improved feedback-based prediction system.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}