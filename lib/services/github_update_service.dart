import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GitHubUpdateService {
  // Configure with your GitHub repository details
  final String owner;
  final String repo;
  final Dio _dio = Dio();

  GitHubUpdateService({
    required this.owner,
    required this.repo,
  });

  /// Check if an update is available by comparing current version with latest GitHub release
  Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      // Get current app version
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);

      // Get latest release from GitHub
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final releaseData = json.decode(response.body);
        final latestVersionString =
            releaseData['tag_name'].toString().replaceAll('v', '');

        // Parse the version string (handle formats like "v1.0.1" by removing the "v")
        final latestVersion = Version.parse(latestVersionString);

        // Compare versions
        if (latestVersion > currentVersion) {
          // Update is available
          return {
            'updateAvailable': true,
            'currentVersion': currentVersion.toString(),
            'latestVersion': latestVersion.toString(),
            'releaseNotes': releaseData['body'] ?? 'No release notes available',
            'downloadUrl': _getApkDownloadUrl(releaseData),
            'releaseData': releaseData,
          };
        } else {
          // No update needed
          return {
            'updateAvailable': false,
            'currentVersion': currentVersion.toString(),
            'latestVersion': latestVersion.toString(),
          };
        }
      } else {
        debugPrint(
            'GitHub API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }

  /// Extract the APK download URL from GitHub release assets
  String _getApkDownloadUrl(Map<String, dynamic> releaseData) {
    final assets = releaseData['assets'] as List;
    for (final asset in assets) {
      if (asset['name'].toString().endsWith('.apk')) {
        return asset['browser_download_url'];
      }
    }
    // If no APK is found, return the release URL
    return releaseData['html_url'] ?? '';
  }

  /// Show update dialog to the user
  Future<void> showUpdateDialog(
      BuildContext context, Map<String, dynamic> updateInfo) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A new version (${updateInfo['latestVersion']}) is available!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Current version: ${updateInfo['currentVersion']}'),
              const SizedBox(height: 16),
              const Text('What\'s new:'),
              const SizedBox(height: 8),
              Text(
                updateInfo['releaseNotes'] ?? 'No release notes available',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadOrOpenUrl(updateInfo['downloadUrl'], context);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  /// Download or open URL based on platform
  Future<void> _downloadOrOpenUrl(
      String downloadUrl, BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        // For Android, show download progress dialog and save to downloads
        _showDownloadDialog(context, downloadUrl);
      } else {
        // For other platforms, just open the URL
        final url = Uri.parse(downloadUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $url';
        }
      }
    } catch (e) {
      debugPrint('Error handling update: $e');
      _showDownloadErrorDialog(context, e.toString());
    }
  }

  /// Show download dialog for Android
  Future<void> _showDownloadDialog(
      BuildContext context, String downloadUrl) async {
    double progress = 0;
    String progressText = "0%";
    bool isDownloading = true;

    // Show the progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Downloading Update'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 16),
                Text(progressText),
              ],
            ),
            actions: [
              if (!isDownloading)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
            ],
          );
        },
      ),
    );

    try {
      // Get the download directory
      final directory = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/app_update.apk';

      // Download the APK
      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Update the progress
            final newProgress = received / total;
            final newProgressText =
                '${(newProgress * 100).toStringAsFixed(0)}%';

            // Update the dialog
            if (context.mounted) {
              (context as Element).markNeedsBuild();
              progress = newProgress;
              progressText = newProgressText;
            }
          }
        },
      );

      // Download complete
      isDownloading = false;

      // Open the file
      final fileUri = Uri.file(filePath);
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Download Complete'),
            content: const Text(
                'The update has been downloaded. Please install it manually.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Open the file for installation
                  try {
                    await launchUrl(
                      fileUri,
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (e) {
                    debugPrint('Error opening file: $e');
                    if (context.mounted) {
                      _showDownloadErrorDialog(context,
                          'Could not open the installation file. Please install it manually from your downloads folder.');
                    }
                  }
                },
                child: const Text('Install'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      isDownloading = false;
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        _showDownloadErrorDialog(context, e.toString());
      }
    }
  }

  /// Show error dialog if download fails
  void _showDownloadErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Error'),
        content: Text('Failed to download update: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
