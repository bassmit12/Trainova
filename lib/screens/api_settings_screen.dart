import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';
import '../config/secure_config.dart';
import '../config/api_config.dart';
import '../utils/validators.dart';
import '../utils/error_handler.dart';
import '../utils/loading_state_manager.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen>
    with LoadingStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _neuralNetworkController =
      TextEditingController();
  final TextEditingController _feedbackApiController = TextEditingController();
  final TextEditingController _geminiApiKeyController = TextEditingController();

  bool _testingConnection = false;
  Map<String, bool> _connectionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await executeWithLoading(
      'load_settings',
      () async {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _neuralNetworkController.text =
              prefs.getString('NEURAL_NETWORK_API_URL') ??
              SecureConfig.instance.neuralNetworkApiUrl;
          _feedbackApiController.text =
              prefs.getString('FEEDBACK_API_URL') ??
              SecureConfig.instance.feedbackApiUrl;
          _geminiApiKeyController.text =
              prefs.getString('GEMINI_API_KEY') ??
              SecureConfig.instance.geminiApiKey;
        });
      },
      loadingMessage: 'Loading API settings...',
      onError: (error) {
        context.handleError(
          AppError.storage(
            'Failed to load API settings',
            technicalDetails: error,
            userAction: 'Default values will be used.',
          ),
        );
      },
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await executeWithLoading(
      'save_settings',
      () async {
        final prefs = await SharedPreferences.getInstance();

        // Update the secure config
        await SecureConfig.instance.updateApiUrl(
          'NEURAL_NETWORK_API_URL',
          _neuralNetworkController.text.trim(),
        );
        await SecureConfig.instance.updateApiUrl(
          'FEEDBACK_API_URL',
          _feedbackApiController.text.trim(),
        );

        // Save Gemini API key
        await prefs.setString(
          'GEMINI_API_KEY',
          _geminiApiKeyController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API settings saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      type: LoadingType.save,
      loadingMessage: 'Saving API settings...',
      onError: (error) {
        context.handleError(
          AppError.storage(
            'Failed to save API settings',
            technicalDetails: error,
            userAction: 'Please check your input and try again.',
          ),
        );
      },
    );
  }

  Future<void> _testConnection(String url, String apiName) async {
    setState(() {
      _testingConnection = true;
      _connectionStatus.remove(apiName);
    });

    try {
      final isConnected = await ApiConfig.testApiConnection(url);
      setState(() {
        _connectionStatus[apiName] = isConnected;
      });

      if (isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $apiName connection successful'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $apiName connection failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _connectionStatus[apiName] = false;
      });

      context.handleError(
        AppError.network(
          'Connection test failed for $apiName',
          technicalDetails: e.toString(),
          userAction: 'Check if the server is running and the URL is correct.',
        ),
      );
    } finally {
      setState(() {
        _testingConnection = false;
      });
    }
  }

  Widget _buildConnectionStatus(String apiName) {
    final status = _connectionStatus[apiName];
    if (status == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            status ? 'Connected' : 'Connection failed',
            style: TextStyle(
              color: status ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _neuralNetworkController.dispose();
    _feedbackApiController.dispose();
    _geminiApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoadingStateManager>(
      builder: (context, loadingManager, child) {
        return LoadingOverlay(
          loadingState: loadingManager.getLoadingState('save_settings'),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('API Settings'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showInfoDialog(),
                ),
              ],
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
                  const SizedBox(height: 8),
                  Text(
                    'Configure the URLs for your machine learning prediction servers.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Neural Network API Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.psychology, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Neural Network API',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ValidatedTextFormField(
                            controller: _neuralNetworkController,
                            labelText: 'Neural Network API URL',
                            hintText: 'http://your-server:5010',
                            validator: AppValidator.validateUrl,
                          ),
                          _buildConnectionStatus('neural_network'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _testingConnection
                                          ? null
                                          : () => _testConnection(
                                            _neuralNetworkController.text
                                                .trim(),
                                            'neural_network',
                                          ),
                                  icon:
                                      _testingConnection
                                          ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Icon(Icons.wifi_find),
                                  label: const Text('Test Connection'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Feedback API Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.feedback, color: Colors.orange),
                              const SizedBox(width: 8),
                              const Text(
                                'Feedback API',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ValidatedTextFormField(
                            controller: _feedbackApiController,
                            labelText: 'Feedback API URL',
                            hintText: 'http://your-server:5009',
                            validator: AppValidator.validateUrl,
                          ),
                          _buildConnectionStatus('feedback'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _testingConnection
                                          ? null
                                          : () => _testConnection(
                                            _feedbackApiController.text.trim(),
                                            'feedback',
                                          ),
                                  icon:
                                      _testingConnection
                                          ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Icon(Icons.wifi_find),
                                  label: const Text('Test Connection'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gemini API Key Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.key, color: Colors.purple),
                              const SizedBox(width: 8),
                              const Text(
                                'Gemini API Key',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _geminiApiKeyController,
                            decoration: InputDecoration(
                              labelText: 'Gemini API Key',
                              hintText: 'Enter your Gemini API key',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _geminiApiKeyController.clear();
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Gemini API Key is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final apiKey =
                                        _geminiApiKeyController.text.trim();
                                    if (apiKey.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter a Gemini API key',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    await executeWithLoading(
                                      'test_gemini_connection',
                                      () async {
                                        final isValid =
                                            await ApiConfig.validateGeminiApiKey(
                                              apiKey,
                                            );

                                        if (isValid) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                '✅ Gemini API key is valid',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                '❌ Invalid Gemini API key',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      loadingMessage:
                                          'Validating Gemini API key...',
                                      onError: (error) {
                                        context.handleError(
                                          AppError.network(
                                            'Failed to validate Gemini API key',
                                            technicalDetails: error,
                                            userAction:
                                                'Please try again later.',
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.check),
                                  label: const Text('Validate API Key'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  LoadingElevatedButton(
                    onPressed: _saveSettings,
                    isLoading: loadingManager.isLoading('save_settings'),
                    loadingText: 'Saving...',
                    child: const Text('Save Settings'),
                  ),
                  const SizedBox(height: 16),

                  // Current Configuration Display
                  Card(
                    color: Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Configuration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...ApiConfig.getCurrentConfig().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Text('${entry.key}: '),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('API Settings Help'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Neural Network API',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'The traditional machine learning model that predicts workout weights based on historical data.',
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Feedback API',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'An improved prediction system that learns from your actual workout performance and adjusts recommendations accordingly.',
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Gemini API Key',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Your personal API key for accessing the Gemini service. This key is used to authenticate your requests.',
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Connection Testing',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Use the "Test Connection" buttons to verify that your servers are running and accessible before saving the settings.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }
}
