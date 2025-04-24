import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'github_api_service.dart';
import '../widgets/message_overlay.dart';

class UpdateService {
  final GitHubApiService githubApiService;
  final Dio dio = Dio();

  // Method channel for native APK installation
  static const platform = MethodChannel('com.trainova.fitness/app_updater');

  UpdateService({required this.githubApiService});

  // Check if an update is available
  Future<bool> checkForUpdate() async {
    return await githubApiService.isUpdateAvailable();
  }

  // Download and install APK directly
  Future<void> downloadAndInstallUpdate(
    BuildContext context, {
    required Function(double) onProgress,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Get update info from GitHub
      final updateInfo = await githubApiService.getUpdateInfo();
      final String? downloadUrl = updateInfo['downloadUrl'] as String?;
      final String? apkName = updateInfo['apkAssetName'] as String?;

      if (downloadUrl == null || apkName == null) {
        onError('No APK file available for download');
        return;
      }

      // First show a dialog explaining what permissions we need
      final bool userConfirmed = await _showPermissionExplanationDialog(
        context,
      );
      if (!userConfirmed) {
        onError('Update canceled by user');
        return;
      }

      // Request necessary permissions
      final permissionsGranted = await _requestPermissions(context);
      if (!permissionsGranted) {
        onError(
          'Required permissions were denied. Please enable them in app settings.',
        );
        return;
      }

      try {
        // Get the app's cache directory
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$apkName';
        final file = File(filePath);

        // Delete existing file if it exists
        if (await file.exists()) {
          await file.delete();
        }

        print('Downloading APK to: $filePath');

        // Download the APK file with progress reporting
        await dio.download(
          downloadUrl,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = received / total;
              onProgress(progress);
              print(
                'Download progress: ${(progress * 100).toStringAsFixed(0)}%',
              );
            }
          },
        );

        print('Download completed, installing APK...');

        // Ensure the file exists before trying to install
        if (await file.exists()) {
          final fileSize = await file.length();
          print('APK downloaded successfully. File size: $fileSize bytes');

          // Keep progress at 100% during installation
          onProgress(1.0);

          // Show installation dialog
          _showInstallationStartingDialog(context);

          // Try to install the APK using various methods
          bool installed = false;

          // First try the native method channel (might fail if app wasn't fully restarted)
          try {
            installed = await _installApkNative(filePath);
            print('Native installation result: $installed');
          } catch (e) {
            print('Native installation method failed: $e');
            // MissingPluginException is expected if app wasn't fully restarted
            // Continue to fallback methods
          }

          // If native method failed, try direct installation
          if (!installed) {
            installed = await _tryAlternativeInstallMethods(
              context,
              filePath,
              updateInfo,
            );
          }

          if (installed) {
            print('Installation initiated successfully');
            onSuccess();
          } else {
            print('All installation methods failed, showing error dialog');
            await _showManualInstallationDialog(context, updateInfo);
            onSuccess(); // Mark as success since we provided alternative
          }
        } else {
          print('Downloaded file does not exist at path: $filePath');
          onError('Download failed. APK file not found.');
        }
      } catch (e) {
        print('Error during download/install: $e');
        onError('Error during update process: $e');
      }
    } catch (e) {
      print('Error preparing update: $e');
      onError('Error preparing update: $e');
    }
  }

  // Try alternative installation methods
  Future<bool> _tryAlternativeInstallMethods(
    BuildContext context,
    String filePath,
    Map<String, dynamic> updateInfo,
  ) async {
    print('Trying alternative installation methods...');
    try {
      // Show a message explaining that we're trying an alternative approach
      MessageOverlay.showWarning(
        context,
        message: 'Trying alternative installation method...',
        duration: const Duration(seconds: 2),
      );

      // Offer a dialog with direct manual installation instructions
      await _showManualInstallationDialog(context, updateInfo);
      return true; // Consider this successful as we've given user instructions
    } catch (e) {
      print('Alternative installation methods failed: $e');
      return false;
    }
  }

  // Show dialog with manual installation instructions
  Future<void> _showManualInstallationDialog(
    BuildContext context,
    Map<String, dynamic> updateInfo,
  ) async {
    final String? htmlUrl = updateInfo['htmlUrl'] as String?;
    final String version =
        updateInfo['latestVersion'] as String? ?? 'latest version';

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Downloaded'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version $version has been downloaded, but we need your help to complete the installation:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please restart the app completely and try again. If that doesn\'t work, you can download the update manually from our GitHub releases page.',
              ),
            ],
          ),
          actions: <Widget>[
            if (htmlUrl != null)
              TextButton(
                child: const Text('Open GitHub'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    final uri = Uri.parse(htmlUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  } catch (e) {
                    print('Error opening GitHub: $e');
                  }
                },
              ),
            TextButton(
              child: const Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Install APK using the native method channel
  Future<bool> _installApkNative(String filePath) async {
    try {
      // Call the native method to install the APK
      final result = await platform.invokeMethod('installApk', {
        'filePath': filePath,
      });

      return result ?? false;
    } on PlatformException catch (e) {
      print('Error calling native APK installer: ${e.message}');
      return false;
    } catch (e) {
      print('Error installing APK: $e');
      return false;
    }
  }

  // Show a dialog informing the user that installation is starting
  void _showInstallationStartingDialog(BuildContext context) {
    // Using custom message widget instead of snackbar
    MessageOverlay.showSuccess(
      context,
      message:
          'Starting installation. Please follow the system prompts to install.',
      duration: const Duration(seconds: 5),
    );
  }

  // Show a dialog explaining what permissions are needed and why
  Future<bool> _showPermissionExplanationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Permissions Required'),
              content: const Text(
                'To install updates automatically, we need permission to:\n\n'
                '• Install unknown apps\n'
                '• Access files on your device\n\n'
                'You will be prompted to grant these permissions next.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Continue'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Request all required permissions with better user guidance
  Future<bool> _requestPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      // First - request install unknown apps permission
      final installStatus = await Permission.requestInstallPackages.status;
      print('Initial install packages permission status: $installStatus');

      if (!installStatus.isGranted) {
        final installResult = await Permission.requestInstallPackages.request();
        print(
          'After request, install packages permission status: $installResult',
        );

        // If permission still not granted, send to settings
        if (!installResult.isGranted) {
          final userOpenedSettings = await _showOpenSettingsDialog(
            context,
            'Install Permission Required',
            'Please enable "Install unknown apps" permission for this app in the settings.',
          );

          if (userOpenedSettings) {
            await openAppSettings();
            // Give the user time to change the setting
            await Future.delayed(const Duration(seconds: 3));
          } else {
            return false;
          }
        }
      }

      // Now - check permissions again, as user might have granted them in settings
      final finalInstallStatus = await Permission.requestInstallPackages.status;
      print('Final install permission status: $finalInstallStatus');

      return finalInstallStatus.isGranted;
    }

    return true; // Non-Android platforms don't need these permissions
  }

  // Show a dialog explaining why settings need to be opened
  Future<bool> _showOpenSettingsDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Open Settings'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
