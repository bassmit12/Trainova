import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'github_api_service.dart';

class UpdateService {
  final GitHubApiService githubApiService;
  
  UpdateService({
    required this.githubApiService,
  });
  
  // Check if an update is available
  Future<bool> checkForUpdate() async {
    return await githubApiService.isUpdateAvailable();
  }
  
  // Open the GitHub release page for manual download
  Future<void> downloadAndInstallUpdate(
    BuildContext context, {
    required Function(double) onProgress,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Get update info from GitHub
      final updateInfo = await githubApiService.getUpdateInfo();
      final releaseUrl = updateInfo['htmlUrl'] as String?;
      
      if (releaseUrl == null) {
        onError('No release URL available');
        return;
      }
      
      // Simulate progress for better UX
      onProgress(0.5);
      
      // Launch URL to GitHub release page
      final Uri uri = Uri.parse(releaseUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        onProgress(1.0);
        onSuccess();
      } else {
        onError('Could not launch the update URL: $releaseUrl');
      }
    } catch (e) {
      onError('Error launching update: $e');
    }
  }
}