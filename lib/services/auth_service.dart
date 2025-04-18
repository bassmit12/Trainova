import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/services.dart';
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
          queryParams: {
            'client_id': SupabaseConfig.googleClientIdWeb,
          },
        );
        return _currentUser;
      } else {
        // Mobile platform sign-in using native Google Sign-In flow
        late final GoogleSignIn googleSignIn;

        if (Platform.isAndroid) {
          // On Android, use the client ID from strings.xml
          googleSignIn = GoogleSignIn(
            serverClientId: SupabaseConfig.googleClientIdAndroid,
            scopes: ['email', 'profile'],
          );
        } else {
          // On iOS, use the web client ID
          googleSignIn = GoogleSignIn(
            serverClientId: SupabaseConfig.googleClientIdWeb,
            scopes: ['email', 'profile'],
          );
        }

        // Clear any existing sign-in first
        try {
          await googleSignIn.signOut();
        } catch (e) {
          // Ignore errors during sign out
          print('Sign out before sign in error (safe to ignore): $e');
        }

        // Try to sign in with the native UI
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // User canceled the sign-in flow
          return null;
        }

        // Get authentication data from Google
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;

        if (idToken == null) {
          throw Exception('Failed to get ID token from Google');
        }

        // Sign in to Supabase with the Google token
        final response = await _client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        // Update current user from the response
        if (response.user != null) {
          _currentUser = UserModel.fromJson(response.user!.toJson());
          notifyListeners();

          // Fetch the complete profile data
          await getCurrentUserProfile();
        }

        return _currentUser;
      }
    } catch (e) {
      print('Error signing in with Google: $e');
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
      if (userId == null) return null;

      // Force a fresh fetch from Supabase when forceRefresh is true
      // Note: Supabase Flutter doesn't support headers in single() method, use maybeSingle() instead
      final query = _client.from('profiles').select().eq('id', userId);
      final response = await query.maybeSingle();

      // Check if profile exists
      if (response == null || response.isEmpty) {
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
        final newResponse = await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (newResponse != null) {
          // Create a new map for merging
          Map<String, dynamic> mergedData = {};

          // Add current user data if available
          if (_currentUser != null) {
            mergedData.addAll(_currentUser!.toJson());
          }

          // Add the response data
          mergedData.addAll(newResponse as Map<String, dynamic>);

          _currentUser = UserModel.fromJson(mergedData);
        }
      } else {
        // Use existing profile data
        // Create a new map for merging
        Map<String, dynamic> mergedData = {};

        // Add current user data if available
        if (_currentUser != null) {
          mergedData.addAll(_currentUser!.toJson());
        }

        // Add the response data
        mergedData.addAll(response as Map<String, dynamic>);

        _currentUser = UserModel.fromJson(mergedData);
      }

      // Debug log current user data
      if (forceRefresh) {
        print(
            'User data refreshed from Supabase - weight: ${_currentUser?.weight}, height: ${_currentUser?.height}');
      }

      notifyListeners();
      return _currentUser;
    } catch (e) {
      print('Error getting user profile: $e');
      return _currentUser;
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
      await _client.from('profiles').upsert({
        'id': userId,
        ...profileData,
      });

      // Refresh user data
      await getCurrentUserProfile();
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
}
