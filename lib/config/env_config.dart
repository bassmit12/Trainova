import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:shared_preferences/shared_preferences.dart';

class EnvConfig {
  // SharedPreferences instance
  static SharedPreferences? _prefs;
  
  // Load environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.dotenv.load(fileName: '.env');
      _prefs = await SharedPreferences.getInstance();
      debugPrint('Environment variables and preferences loaded successfully');
    } catch (e) {
      debugPrint('Error loading environment variables: $e');
    }
  }

  // Get API keys from environment
  static String get geminiApiKey => dotenv.dotenv.env['GEMINI_API_KEY'] ?? '';

  // Neural Network API endpoint
  static String get neuralNetworkApiUrl {
    final savedUrl = _prefs?.getString('NEURAL_NETWORK_API_URL');
    return savedUrl ?? dotenv.dotenv.env['NEURAL_NETWORK_API_URL'] ?? 'http://192.168.178.109:8000';
  }
  
  // Feedback-based API endpoint
  static String get feedbackApiUrl {
    final savedUrl = _prefs?.getString('FEEDBACK_API_URL');
    return savedUrl ?? dotenv.dotenv.env['FEEDBACK_API_URL'] ?? 'http://192.168.178.109:8001';
  }

  // API Endpoints
  static const String geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  // Check if environment variables are loaded
  static bool get isInitialized => dotenv.dotenv.isInitialized;
}
