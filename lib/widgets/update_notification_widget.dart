import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/update_provider.dart';
import '../utils/app_colors.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class UpdateNotificationWidget extends StatelessWidget {
  final bool dismissible;

  const UpdateNotificationWidget({Key? key, this.dismissible = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final updateProvider = Provider.of<UpdateProvider>(context);

    if (!updateProvider.updateAvailable) {
      return const SizedBox.shrink();
    }

    final updateInfo = updateProvider.updateInfo;
    if (updateInfo == null) {
      return const SizedBox.shrink();
    }

    // Format APK size if available
    String? apkSizeFormatted;
    if (updateInfo['apkSize'] != null) {
      final int apkSizeBytes = updateInfo['apkSize'] as int;
      if (apkSizeBytes > 1024 * 1024) {
        // Show in MB
        final double sizeMB = apkSizeBytes / (1024 * 1024);
        apkSizeFormatted = '${sizeMB.toStringAsFixed(1)} MB';
      } else {
        // Show in KB
        final double sizeKB = apkSizeBytes / 1024;
        apkSizeFormatted = '${sizeKB.toStringAsFixed(0)} KB';
      }
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.system_update, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Update Available',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version ${updateInfo['latestVersion']} is now available. You have ${updateInfo['currentVersion']}.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (apkSizeFormatted != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Size: $apkSizeFormatted',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
                if (dismissible)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      updateProvider.resetUpdateState();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (updateInfo['releaseNotes'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What\'s New:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      updateInfo['releaseNotes'] ??
                          'No release notes available',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (updateProvider.isDownloading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDownloadStatusText(updateProvider.downloadProgress),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  LinearPercentIndicator(
                    lineHeight: 12.0,
                    percent: updateProvider.downloadProgress,
                    backgroundColor: Colors.grey.shade200,
                    progressColor: AppColors.primary,
                    barRadius: const Radius.circular(8),
                    padding: EdgeInsets.zero,
                    animation: false,
                    center: Text(
                      '${(updateProvider.downloadProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color:
                            updateProvider.downloadProgress > 0.5
                                ? Colors.white
                                : AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Please wait until installation starts automatically',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  if (updateProvider.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Update Error',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  updateProvider.errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          updateProvider.resetUpdateState();
                        },
                        child: const Text('Later'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          updateProvider.downloadAndInstallUpdate(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.system_update_alt, size: 18),
                            const SizedBox(width: 6),
                            const Text('Update Now'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _getDownloadStatusText(double progress) {
    if (progress < 0.01) {
      return 'Preparing download...';
    } else if (progress < 0.99) {
      return 'Downloading update...';
    } else {
      return 'Installing update...';
    }
  }
}
