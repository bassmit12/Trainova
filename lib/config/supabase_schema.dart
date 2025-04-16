import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper class to manage Supabase schema and migrations
class SupabaseSchemaManager {
  final SupabaseClient _client;

  SupabaseSchemaManager(this._client);

  /// Run all migrations that might be needed
  Future<void> runMigrations() async {
    try {
      // Check if we need to update the profiles table
      await _ensureProfileTableFields();

      print('Schema migrations completed successfully');
    } catch (e) {
      print('Error running schema migrations: $e');
      rethrow;
    }
  }

  /// Ensure the profiles table has all required fields
  Future<void> _ensureProfileTableFields() async {
    // This is a workaround way to check if columns exist
    // A better approach would be to use information_schema, but that requires additional permissions

    try {
      // Try to update a row with a minimal profile update to verify columns exist
      await _client.from('profiles').update({
        'is_profile_complete': false,
      }).eq('id', _client.auth.currentUser!.id);
    } catch (e) {
      // If we get an error about a missing column, we need to run the migration
      if (e.toString().contains('column') &&
          e.toString().contains('does not exist')) {
        print(
            'Missing columns in profiles table detected, prompting user to run migration');
        throw Exception(
            'Your database schema needs to be updated. Please run the following SQL in your Supabase dashboard SQL editor:\n\n'
            'ALTER TABLE public.profiles\n'
            'ADD COLUMN IF NOT EXISTS weight float,\n'
            'ADD COLUMN IF NOT EXISTS height float,\n'
            'ADD COLUMN IF NOT EXISTS weight_unit text DEFAULT \'kg\',\n'
            'ADD COLUMN IF NOT EXISTS height_unit text DEFAULT \'cm\',\n'
            'ADD COLUMN IF NOT EXISTS fitness_goal text,\n'
            'ADD COLUMN IF NOT EXISTS workouts_per_week integer,\n'
            'ADD COLUMN IF NOT EXISTS preferred_workout_types text[],\n'
            'ADD COLUMN IF NOT EXISTS experience_level text,\n'
            'ADD COLUMN IF NOT EXISTS is_profile_complete boolean DEFAULT false,\n'
            'ADD COLUMN IF NOT EXISTS created_at timestamp with time zone DEFAULT now();');
      } else {
        rethrow;
      }
    }
  }
}
