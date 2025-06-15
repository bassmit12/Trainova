import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnvConfig {
  static bool _initialized = false;

  // Load environment variables
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: '.env');
      _initialized = true;
    } catch (e) {
      print('Warning: Could not load .env file: $e');
      _initialized = true; // Mark as initialized even if .env is missing
    }
  }

  // Get API keys from environment
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Neural Network API endpoint
  static Future<String> get neuralNetworkApiUrl async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('NEURAL_NETWORK_API_URL');
    final envUrl = dotenv.env['NEURAL_NETWORK_API_URL'];

    if (savedUrl != null && savedUrl.isNotEmpty) return savedUrl;
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    throw Exception(
      'NEURAL_NETWORK_API_URL not configured. Please set it in your .env file or app settings.',
    );
  }

  // Feedback-based API endpoint
  static Future<String> get feedbackApiUrl async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('FEEDBACK_API_URL');
    final envUrl = dotenv.env['FEEDBACK_API_URL'];

    if (savedUrl != null && savedUrl.isNotEmpty) return savedUrl;
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    throw Exception(
      'FEEDBACK_API_URL not configured. Please set it in your .env file or app settings.',
    );
  }

  // Secure Gemini API endpoint
  static String get geminiApiUrl {
    final url = dotenv.env['GEMINI_API_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        'GEMINI_API_URL not found in environment variables. '
        'Please add it to your .env file.',
      );
    }
    return url;
  }

  // Environment type for conditional behavior
  static String get environment {
    return dotenv.env['ENVIRONMENT'] ?? 'development';
  }

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';

  // Check if environment variables are loaded
  static bool get isInitialized => _initialized;
}
