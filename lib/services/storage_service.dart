import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // Bucket name constant - let's use a single bucket for all images
  static const String BUCKET_NAME = 'exercise-images';

  // Upload an exercise image to Supabase storage
  Future<String?> uploadExerciseImage(XFile imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Generate a unique filename
      final uuid = const Uuid().v4();
      final fileExtension = path.extension(imageFile.path);
      final fileName = 'exercise_$uuid$fileExtension';

      // Create storage path
      final storagePath = 'exercises/$userId/$fileName';

      // Read file as bytes
      final fileBytes = await imageFile.readAsBytes();

      // Debug: Print key information
      debugPrint('Uploading exercise image to bucket: $BUCKET_NAME');
      debugPrint('Storage path: $storagePath');
      debugPrint('File size: ${fileBytes.length} bytes');

      // Upload file to Supabase storage
      await _supabase.storage
          .from(BUCKET_NAME)
          .uploadBinary(storagePath, fileBytes);

      // Get public URL
      final imageUrl =
          _supabase.storage.from(BUCKET_NAME).getPublicUrl(storagePath);

      debugPrint('Image uploaded successfully. URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading exercise image: $e');
      return null;
    }
  }

  // Upload a workout image to Supabase storage using the same bucket
  Future<String?> uploadWorkoutImage(XFile imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Generate a unique filename
      final uuid = const Uuid().v4();
      final fileExtension = path.extension(imageFile.path);
      final fileName = 'workout_$uuid$fileExtension';

      // Create storage path - store in a workouts subfolder
      final storagePath = 'workouts/$userId/$fileName';

      // Read file as bytes
      final fileBytes = await imageFile.readAsBytes();

      // Debug: Print key information
      debugPrint('Uploading workout image to bucket: $BUCKET_NAME');
      debugPrint('Storage path: $storagePath');
      debugPrint('File size: ${fileBytes.length} bytes');

      // Upload file to Supabase storage using the existing bucket
      await _supabase.storage
          .from(BUCKET_NAME)
          .uploadBinary(storagePath, fileBytes);

      // Get public URL
      final imageUrl =
          _supabase.storage.from(BUCKET_NAME).getPublicUrl(storagePath);

      debugPrint('Workout image uploaded successfully. URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading workout image: $e');
      return null;
    }
  }

  // Delete an image from Supabase storage
  Future<bool> deleteExerciseImage(String imageUrl) async {
    try {
      return await _deleteImage(imageUrl);
    } catch (e) {
      debugPrint('Error deleting exercise image: $e');
      return false;
    }
  }

  // Delete a workout image from Supabase storage
  Future<bool> deleteWorkoutImage(String imageUrl) async {
    try {
      return await _deleteImage(imageUrl);
    } catch (e) {
      debugPrint('Error deleting workout image: $e');
      return false;
    }
  }

  // Generic method to delete images from storage
  Future<bool> _deleteImage(String imageUrl) async {
    try {
      // Extract the storage path from the URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // The storage path should be the segments after 'storage/v1/object/public/'
      final bucketIndex = pathSegments.indexOf('public') + 1;
      if (bucketIndex >= pathSegments.length) return false;

      final bucket = pathSegments[bucketIndex];
      final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');

      // Delete the file
      await _supabase.storage.from(bucket).remove([storagePath]);
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }
}
