import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Centralized secure configuration management
class SecureConfig {
  static SecureConfig? _instance;
  static SecureConfig get instance => _instance ??= SecureConfig._();
  SecureConfig._();

  bool _initialized = false;

  // Default fallback URLs for your actual ML servers
  static const String _defaultNeuralNetworkUrl = 'http://143.179.147.112:5010';
  static const String _defaultFeedbackUrl = 'http://143.179.147.112:5009';

  // Timeout and retry configurations
  static const int apiTimeoutSeconds = 30;
  static const int longOperationTimeoutSeconds = 60;
  static const int retryAttempts = 3;

  /// Initialize the secure configuration
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: '.env');
      _initialized = true;
      print('SecureConfig: Environment variables loaded successfully');
    } catch (e) {
      print('SecureConfig: Warning - Could not load .env file: $e');
      _initialized = true; // Mark as initialized to prevent repeated attempts
    }
  }

  /// Get Neural Network API URL with proper fallback
  String get neuralNetworkApiUrl {
    // First try environment variable
    final envUrl = dotenv.env['NEURAL_NETWORK_API_URL'];
    if (envUrl != null &&
        envUrl.isNotEmpty &&
        envUrl != 'http://localhost:5010') {
      return envUrl;
    }

    // Return the actual server URL
    return _defaultNeuralNetworkUrl;
  }

  /// Get Feedback API URL with proper fallback
  String get feedbackApiUrl {
    // First try environment variable
    final envUrl = dotenv.env['FEEDBACK_API_URL'];
    if (envUrl != null &&
        envUrl.isNotEmpty &&
        envUrl != 'http://localhost:5009') {
      return envUrl;
    }

    // Return the actual server URL
    return _defaultFeedbackUrl;
  }

  /// Get Gemini API Key
  String get geminiApiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null ||
        key.isEmpty ||
        key == 'your-actual-gemini-api-key-here') {
      print(
        'SecureConfig: WARNING - Gemini API key not configured or using placeholder',
      );
      return '';
    }
    return key;
  }

  /// Get Gemini API URL
  String get geminiApiUrl {
    final url = dotenv.env['GEMINI_API_URL'];
    if (url != null && url.isNotEmpty) {
      return url;
    }
    // Use the updated Gemini API endpoint
    return 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';
  }

  /// Update API URL at runtime
  Future<void> updateApiUrl(String key, String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, url);
      print('SecureConfig: Updated $key to $url');
    } catch (e) {
      print('SecureConfig: Failed to update $key: $e');
      throw Exception('Failed to save configuration: $e');
    }
  }

  /// Test API connection
  Future<bool> testApiConnection(String url) async {
    try {
      print('SecureConfig: Testing connection to $url');

      // For ML APIs, test the health endpoint
      final testUrl = url.endsWith('/') ? '${url}health' : '$url/health';

      final response = await http
          .get(
            Uri.parse(testUrl),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      final isConnected = response.statusCode == 200;
      print(
        'SecureConfig: Connection test result for $url: $isConnected (Status: ${response.statusCode})',
      );

      return isConnected;
    } catch (e) {
      print('SecureConfig: Connection test failed for $url: $e');
      return false;
    }
  }

  /// Get current configuration for display
  Map<String, String> getCurrentConfig() {
    return {
      'Neural Network API': neuralNetworkApiUrl,
      'Feedback API': feedbackApiUrl,
      'Gemini API': geminiApiUrl,
      'Gemini API Key':
          geminiApiKey.isNotEmpty ? 'Configured ✓' : 'Not configured ✗',
    };
  }

  /// Check if configuration is valid
  bool get isConfigurationValid {
    return neuralNetworkApiUrl.isNotEmpty &&
        feedbackApiUrl.isNotEmpty &&
        geminiApiUrl.isNotEmpty;
  }

  /// Check if Gemini API is properly configured
  bool get isGeminiConfigured {
    return geminiApiKey.isNotEmpty &&
        geminiApiKey != 'your-actual-gemini-api-key-here';
  }

  /// Validate all configurations
  Map<String, bool> validateConfigurations() {
    return {
      'neural_network':
          neuralNetworkApiUrl.isNotEmpty &&
          neuralNetworkApiUrl.startsWith('http'),
      'feedback_api':
          feedbackApiUrl.isNotEmpty && feedbackApiUrl.startsWith('http'),
      'gemini_api': geminiApiUrl.isNotEmpty && geminiApiUrl.startsWith('http'),
      'gemini_key': isGeminiConfigured,
    };
  }
}
