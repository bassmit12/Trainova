import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:flutter/foundation.dart';
import 'secure_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiConfig {
  /// Base URL for the Progressive Overload API
  /// Now uses SecureConfig for better security and validation
  static String get progressiveOverloadApiUrl {
    return SecureConfig.instance.neuralNetworkApiUrl;
  }

  /// Base URL for the Feedback API
  static String get feedbackApiUrl {
    return SecureConfig.instance.feedbackApiUrl;
  }

  /// Gemini API Key (secured)
  static String? get geminiApiKey {
    return SecureConfig.instance.geminiApiKey;
  }

  /// Timeout duration for API requests in seconds
  static int get apiTimeoutSeconds => SecureConfig.apiTimeoutSeconds;

  /// Timeout for long operations
  static int get longOperationTimeoutSeconds =>
      SecureConfig.longOperationTimeoutSeconds;

  /// Number of retry attempts for failed requests
  static int get retryAttempts => SecureConfig.retryAttempts;

  /// Test API connectivity
  static Future<bool> testApiConnection(String url) async {
    return await SecureConfig.instance.testApiConnection(url);
  }

  /// Validate Gemini API key
  static Future<bool> validateGeminiApiKey(String apiKey) async {
    if (apiKey.isEmpty) return false;

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent',
      ).replace(queryParameters: {'key': apiKey});

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": "Test"},
                  ],
                },
              ],
            }),
          )
          .timeout(Duration(seconds: 10));

      // If we get a 200 response or even a 400 (bad request), the key is valid
      // 401/403 would indicate authentication issues
      return response.statusCode != 401 && response.statusCode != 403;
    } catch (e) {
      print('Gemini API key validation error: $e');
      return false;
    }
  }

  /// Get all current API configurations
  static Map<String, String> getCurrentConfig() {
    return SecureConfig.instance.getCurrentConfig();
  }
}
