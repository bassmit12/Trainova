import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';

class ExerciseImagePicker extends StatelessWidget {
  final String? currentImageUrl;
  final Function(XFile) onImageSelected;
  final bool isLoading;

  const ExerciseImagePicker({
    Key? key,
    this.currentImageUrl,
    required this.onImageSelected,
    this.isLoading = false,
  }) : super(key: key);

  Future<void> _pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final image = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        onImageSelected(image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a unique key based on the imageUrl so that when the URL changes, the widget rebuilds completely
    final hasImage = currentImageUrl != null && currentImageUrl!.isNotEmpty;
    final imageKey =
        hasImage ? ValueKey(currentImageUrl) : const ValueKey('no_image');

    return GestureDetector(
      onTap: isLoading ? null : () => _pickImage(context),
      child: Container(
        key: imageKey,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasImage)
              Builder(
                builder: (context) {
                  // Attempt to decode the URL to check for malformed URLs
                  Uri? parsedUrl;
                  try {
                    parsedUrl = Uri.parse(currentImageUrl!);
                    debugPrint("Loading image: $currentImageUrl");
                    debugPrint("Parsed URL path: ${parsedUrl.path}");
                  } catch (e) {
                    debugPrint("Invalid image URL format: $e");
                    return _buildPlaceholder(isError: true);
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: CachedNetworkImage(
                      key: ValueKey(currentImageUrl),
                      imageUrl: currentImageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ),
                      errorWidget: (context, url, error) {
                        debugPrint("Image error: $error for $url");
                        return _buildPlaceholder(isError: true);
                      },
                      // Use a unique cache key to prevent stale images
                      cacheKey:
                          '${currentImageUrl}_${DateTime.now().millisecondsSinceEpoch}',
                    ),
                  );
                },
              )
            else
              _buildPlaceholder(),

            // Loading indicator
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
              ),

            // Camera icon overlay
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  hasImage ? Icons.edit : Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder({bool isError = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isError ? Icons.broken_image : Icons.fitness_center,
          size: 50,
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        Text(
          isError ? 'Failed to load image' : 'Add exercise image',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (!isError)
          Text(
            'Tap to select',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        if (isError && currentImageUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'URL may be invalid',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
