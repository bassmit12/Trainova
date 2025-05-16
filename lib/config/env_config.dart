import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

class EnvConfig {
  // Load environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.dotenv.load(fileName: '.env');
      debugPrint('Environment variables loaded successfully');
    } catch (e) {
      debugPrint('Error loading environment variables: $e');
    }
  }

  // Get API keys from environment
  static String get geminiApiKey => dotenv.dotenv.env['GEMINI_API_KEY'] ?? '';

  // Neural Network API endpoint
  static String get neuralNetworkApiUrl => 
      dotenv.dotenv.env['NEURAL_NETWORK_API_URL'] ?? 'http://192.168.178.109:8000';

  // API Endpoints
  static const String geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  // Check if environment variables are loaded
  static bool get isInitialized => dotenv.dotenv.isInitialized;
}
