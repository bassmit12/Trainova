import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart';
import '../config/supabase_config.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _client;
  UserModel? _currentUser;

  // Getter for the current user
  UserModel? get currentUser => _currentUser;

  // Getter to check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Getter to check if profile is complete
  bool get isProfileComplete => _currentUser?.isProfileComplete == true;

  AuthService(this._client) {
    _initializeUser();
  }

  // Initialize the user from the current Supabase session
  Future<void> _initializeUser() async {
    final session = _client.auth.currentSession;
    if (session != null) {
      final userData = session.user;
      // Create a basic user model first
      _currentUser = UserModel.fromJson(userData.toJson());
      notifyListeners();

      // Then fetch the complete profile data
      await getCurrentUserProfile();
    }

    // Listen for auth state changes
    _client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        // Create a basic user model first
        _currentUser = UserModel.fromJson(session.user.toJson());
        notifyListeners();

        // Then fetch the complete profile data
        await getCurrentUserProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web platform sign-in
        await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: SupabaseConfig.redirectUrl,
          queryParams: {'client_id': SupabaseConfig.googleClientIdWeb},
        );
        return _currentUser;
      } else {
        // Mobile platform sign-in using full OAuth flow
        final GoogleSignIn googleSignIn;

        if (kDebugMode) {
          // Debug build (emulator) - use the debug client ID
          googleSignIn = GoogleSignIn(
            scopes: ['email', 'profile'],
            clientId: SupabaseConfig.googleClientIdAndroidDebug,
            serverClientId: SupabaseConfig.googleClientIdWeb,
          );
          print(
            'DEBUG: Using Android debug client ID: ${SupabaseConfig.googleClientIdAndroidDebug}',
          );
          print(
            'DEBUG: Mobile redirect URL: ${SupabaseConfig.mobileRedirectUrl}',
          );
        } else {
          // Release build - use the release client ID
          // For GitHub Actions builds, consider using a different client ID if needed
          googleSignIn = GoogleSignIn(
            scopes: ['email', 'profile'],
            clientId: SupabaseConfig.googleClientIdAndroidRelease,
            serverClientId: SupabaseConfig.googleClientIdWeb,
          );
          print(
            'RELEASE: Using Android release client ID: ${SupabaseConfig.googleClientIdAndroidRelease}',
          );
          print(
            'RELEASE: Mobile redirect URL: ${SupabaseConfig.mobileRedirectUrl}',
          );
        }

        // Sign out first to make sure we get a fresh sign-in
        await googleSignIn.signOut();
        print('Google SignIn: Signed out previous session');

        // Try to sign in
        print('Google SignIn: Attempting to sign in...');
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // User canceled the sign-in flow
          print('Google SignIn: User canceled the sign-in flow');
          return null;
        }

        // Get authentication data from Google
        print('Google SignIn: User signed in: ${googleUser.email}');
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;

        print('Google SignIn: ID token: ${idToken?.substring(0, 10)}...');
        print(
          'Google SignIn: Access token: ${accessToken?.substring(0, 10)}...',
        );

        if (idToken == null) {
          print('Google SignIn: Failed to get ID token from Google');
          throw Exception('Failed to get ID token from Google');
        }

        print('Google SignIn: Successfully retrieved tokens');

        // Add debugging for the auth request
        print('Supabase: Attempting to sign in with Google tokens...');
        print('Supabase: Using project URL: ${SupabaseConfig.supabaseUrl}');

        // Sign in to Supabase with the Google token
        try {
          final response = await _client.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );

          // Update current user from the response
          if (response.user != null) {
            print('Supabase: Successfully signed in with Google token');
            _currentUser = UserModel.fromJson(response.user!.toJson());
            notifyListeners();

            // Fetch the complete profile data
            await getCurrentUserProfile();
          } else {
            print(
              'Supabase: Failed to sign in with Google token - no user returned',
            );
          }
        } catch (authError) {
          print('Supabase: Auth error details:');
          print('Error type: ${authError.runtimeType}');
          print('Error message: ${authError.toString()}');
          if (authError is AuthException) {
            print('Status code: ${authError.statusCode}');
          }

          // Check if this is a Google OAuth configuration issue
          if (authError.toString().contains('Project not specified')) {
            print('Supabase: Google OAuth configuration issue detected');
            print(
              'Supabase: This usually means Google OAuth is not properly configured in Supabase',
            );
            print(
              'Supabase: Please check Authentication > Providers > Google in your Supabase dashboard',
            );

            // For now, create a basic user without full Supabase auth
            // This is a temporary workaround until Google OAuth is properly configured
            final googleSignIn = GoogleSignIn(
              scopes: ['email', 'profile'],
              clientId:
                  kDebugMode
                      ? SupabaseConfig.googleClientIdAndroidDebug
                      : SupabaseConfig.googleClientIdAndroidRelease,
              serverClientId: SupabaseConfig.googleClientIdWeb,
            );

            final googleUser = googleSignIn.currentUser;
            if (googleUser != null) {
              _currentUser = UserModel(
                id: googleUser.id,
                email: googleUser.email,
                name: googleUser.displayName ?? 'User',
                avatarUrl: googleUser.photoUrl,
                isProfileComplete: false,
              );
              notifyListeners();
              print('Supabase: Created temporary user profile');
              return _currentUser;
            }
          }

          rethrow;
        }

        return _currentUser;
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      // Print stack trace for more detailed error information
      print(StackTrace.current);
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // Get the current user profile from Supabase
  Future<UserModel?> getCurrentUserProfile({bool forceRefresh = false}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        print('getCurrentUserProfile: No user ID found');
        return null;
      }

      print('getCurrentUserProfile: Fetching profile for user: $userId');

      // Add a small delay to ensure Supabase is fully ready
      await Future.delayed(const Duration(milliseconds: 100));

      // Try a simpler query approach first
      print('getCurrentUserProfile: Executing query...');
      List<Map<String, dynamic>> profileData;
      try {
        profileData = await _client
            .from('profiles')
            .select('*')
            .eq('id', userId)
            .limit(1);
      } catch (e) {
        print('getCurrentUserProfile: Query failed with error: $e');
        // If query fails, try to reconnect Supabase
        await _reinitializeSupabase();
        profileData = await _client
            .from('profiles')
            .select('*')
            .eq('id', userId)
            .limit(1);
      }

      print('getCurrentUserProfile: Query response: $profileData');

      // Check if profile exists
      if (profileData.isEmpty) {
        print('getCurrentUserProfile: No profile found, creating one...');
        // Create a basic profile if it doesn't exist
        await _client.from('profiles').upsert({
          'id': userId,
          'full_name': _currentUser?.name,
          'avatar_url': _currentUser?.avatarUrl,
          'is_profile_complete': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Fetch again after creating
        final newProfileData = await _client
            .from('profiles')
            .select('*')
            .eq('id', userId)
            .limit(1);

        if (newProfileData.isNotEmpty) {
          // Create a new map for merging
          Map<String, dynamic> mergedData = {};

          // Add current user data if available
          if (_currentUser != null) {
            mergedData.addAll(_currentUser!.toJson());
          }

          // Add the response data
          mergedData.addAll(newProfileData.first);

          _currentUser = UserModel.fromJson(mergedData);
          print(
            'getCurrentUserProfile: Profile created and loaded successfully',
          );
        }
      } else {
        print('getCurrentUserProfile: Profile found, merging data...');
        // Use existing profile data
        // Create a new map for merging
        Map<String, dynamic> mergedData = {};

        // Add current user data if available
        if (_currentUser != null) {
          mergedData.addAll(_currentUser!.toJson());
        }

        // Add the response data
        mergedData.addAll(profileData.first);

        _currentUser = UserModel.fromJson(mergedData);
        print('getCurrentUserProfile: Profile loaded successfully');
      }

      // Debug log current user data
      if (forceRefresh) {
        print(
          'User data refreshed from Supabase - weight: ${_currentUser?.weight}, height: ${_currentUser?.height}',
        );
      }

      notifyListeners();
      return _currentUser;
    } catch (e) {
      print('Error getting user profile: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      return _currentUser;
    }
  }

  // Helper method to reinitialize Supabase connection
  Future<void> _reinitializeSupabase() async {
    print('Reinitializing Supabase connection...');
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        debug: true,
      );
      print('Supabase reinitialized successfully');
    } catch (e) {
      print('Failed to reinitialize Supabase: $e');
    }
  }

  // Update user profile in Supabase
  Future<void> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // Add updated_at timestamp
      profileData['updated_at'] = DateTime.now().toIso8601String();

      // Update profile in Supabase
      await _client.from('profiles').upsert({'id': userId, ...profileData});

      // Refresh user data
      await getCurrentUserProfile();
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
}
