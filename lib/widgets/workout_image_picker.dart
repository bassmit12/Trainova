import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';

class WorkoutImagePicker extends StatelessWidget {
  final String? imageUrl;
  final Function(XFile) onImageSelected;
  final bool isUploading;

  const WorkoutImagePicker({
    Key? key,
    this.imageUrl,
    required this.onImageSelected,
    this.isUploading = false,
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
        maxWidth: 1920, // Higher resolution for workout cover images
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
    // Determine what type of image we're dealing with
    final bool isNetworkImage = imageUrl != null &&
        (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://') || imageUrl!.startsWith('http'));
    final bool isAssetImage =
        imageUrl != null && imageUrl!.startsWith('assets/');
    final imageKey =
        imageUrl != null ? ValueKey(imageUrl) : const ValueKey('no_image');

    return GestureDetector(
      onTap: isUploading ? null : () => _pickImage(context),
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
            if (isNetworkImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: CachedNetworkImage(
                  key: ValueKey(imageUrl),
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  errorWidget: (context, url, error) {
                    debugPrint("Workout image error: $error for $url");
                    return _buildPlaceholder(isError: true);
                  },
                ),
              )
            else if (isAssetImage)
              // Display local asset image
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.asset(
                  imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint("Asset image error: $error for $imageUrl");
                    return _buildPlaceholder(isError: true);
                  },
                ),
              )
            else
              _buildPlaceholder(),

            // Loading indicator
            if (isUploading)
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
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  imageUrl != null ? Icons.edit : Icons.camera_alt,
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
          isError ? Icons.broken_image : Icons.image,
          size: 50,
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        Text(
          isError ? 'Failed to load image' : 'Add workout cover image',
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
        if (isError && imageUrl != null)
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
