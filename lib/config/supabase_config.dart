class SupabaseConfig {
  // Supabase URL from the Supabase dashboard
  static const String supabaseUrl = 'https://dqawjrxwzwjayfmpwddd.supabase.co';

  // Supabase anon key from the Supabase dashboard
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxYXdqcnh3endqYXlmbXB3ZGRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ2MjIyNDQsImV4cCI6MjA2MDE5ODI0NH0.Hz5fuJS9nekfvpNbxDrByr3ZSavmNPRppfQZDXMJaZo';

  // Google OAuth client ID for web platform
  static const String googleClientIdWeb =
      '369475473502-5838krq6lio4ko2r63fs8t0l4buuv680.apps.googleusercontent.com';

  // Google OAuth client ID for Android debug builds (emulator)
  static const String googleClientIdAndroidDebug =
      '369475473502-i7d15gm4v0crnrhr2dcq5p370ba1lrb5.apps.googleusercontent.com';

  // Google OAuth client ID for Android release builds
  static const String googleClientIdAndroidRelease =
      '369475473502-015rktae80k9k5gtgtc1a60co84itqgk.apps.googleusercontent.com';

  // The redirect URL used for OAuth callbacks
  static const String redirectUrl =
      'https://dqawjrxwzwjayfmpwddd.supabase.co/auth/v1/callback';

  // The redirect URL used for OAuth callbacks on mobile devices
  static const String mobileRedirectUrl =
      'com.trainova.fitness://login-callback';
}
