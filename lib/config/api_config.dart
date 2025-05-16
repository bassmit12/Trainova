import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Base URL for the Progressive Overload API
  /// Falls back to the default if not specified in environment
  static String get progressiveOverloadApiUrl {
    final configuredUrl = dotenv.dotenv.env['NEURAL_NETWORK_API_URL'];
    if (configuredUrl != null && configuredUrl.isNotEmpty) {
      return configuredUrl;
    }
    // Default fallback URL
    return 'http://192.168.178.109:8000';
  }

  /// Timeout duration for API requests in seconds
  static const int apiTimeoutSeconds = 10;
}
