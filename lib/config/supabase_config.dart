import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Secure Supabase configuration that loads from environment variables
class SupabaseConfig {
  // Supabase URL from environment variables
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        'SUPABASE_URL not found in environment variables. '
        'Please add it to your .env file.',
      );
    }
    return url;
  }

  // Supabase anon key from environment variables
  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY not found in environment variables. '
        'Please add it to your .env file.',
      );
    }
    return key;
  }

  // Google OAuth client ID for web platform
  static String get googleClientIdWeb {
    final clientId = dotenv.env['GOOGLE_CLIENT_ID_WEB'];
    if (clientId == null || clientId.isEmpty) {
      throw Exception(
        'GOOGLE_CLIENT_ID_WEB not found in environment variables. '
        'Please add it to your .env file.',
      );
    }
    return clientId;
  }

  // Google OAuth client ID for Android debug builds
  static String get googleClientIdAndroidDebug {
    final clientId = dotenv.env['GOOGLE_CLIENT_ID_ANDROID_DEBUG'];
    if (clientId == null || clientId.isEmpty) {
      throw Exception(
        'GOOGLE_CLIENT_ID_ANDROID_DEBUG not found in environment variables. '
        'Please add it to your .env file.',
      );
    }
    return clientId;
  }

  // Google OAuth client ID for Android release builds
  static String get googleClientIdAndroidRelease {
    final clientId = dotenv.env['GOOGLE_CLIENT_ID_ANDROID_RELEASE'];
    if (clientId == null || clientId.isEmpty) {
      throw Exception(
        'GOOGLE_CLIENT_ID_ANDROID_RELEASE not found in environment variables. '
        'Please add it to your .env file.',
      );
    }
    return clientId;
  }

  // The redirect URL for OAuth callbacks
  static String get redirectUrl {
    final url = dotenv.env['OAUTH_REDIRECT_URL'];
    if (url == null || url.isEmpty) {
      // Construct from Supabase URL as fallback
      return '$supabaseUrl/auth/v1/callback';
    }
    return url;
  }

  // The redirect URL for mobile OAuth callbacks
  static String get mobileRedirectUrl {
    final url = dotenv.env['MOBILE_REDIRECT_URL'];
    if (url == null || url.isEmpty) {
      return 'com.trainova.fitness://login-callback';
    }
    return url;
  }

  /// Validate all required configuration values
  static bool validateConfiguration() {
    try {
      supabaseUrl;
      supabaseAnonKey;
      googleClientIdWeb;
      googleClientIdAndroidDebug;
      googleClientIdAndroidRelease;
      return true;
    } catch (e) {
      return false;
    }
  }
}
