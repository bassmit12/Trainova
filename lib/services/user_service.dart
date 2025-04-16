import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Cache the admin status to avoid repeated DB queries
  bool? _isAdmin;
  DateTime? _lastAdminCheck;

  // Check if the current user is an admin
  Future<bool> isAdmin() async {
    // Return cached result if available and recent (within last 5 minutes)
    final now = DateTime.now();
    if (_isAdmin != null &&
        _lastAdminCheck != null &&
        now.difference(_lastAdminCheck!).inMinutes < 5) {
      return _isAdmin!;
    }

    try {
      // Get the current user ID
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Query the profile to check role
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      // Update cache
      _isAdmin = response['role'] == 'admin';
      _lastAdminCheck = now;

      return _isAdmin!;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  // Clear the admin status cache
  void clearCache() {
    _isAdmin = null;
    _lastAdminCheck = null;
  }
}
