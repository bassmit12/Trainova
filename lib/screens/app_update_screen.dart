import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../providers/update_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({Key? key}) : super(key: key);

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  late Future<PackageInfo> _packageInfoFuture;
  int _selectedCheckInterval = 24; // Default: 24 hours
  bool _hasCheckedForUpdate = false;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
    _loadUpdateInterval();
  }

  Future<void> _loadUpdateInterval() async {
    final updateProvider = Provider.of<UpdateProvider>(context, listen: false);
    setState(() {
      _selectedCheckInterval = updateProvider.updateCheckInterval;
    });
  }

  @override
  Widget build(BuildContext context) {
    final updateProvider = Provider.of<UpdateProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final bool isDarkMode = themeProvider.isDarkMode;
    final backgroundColor =
        isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimaryColor =
        isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondaryColor =
        isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('App Updates'),
        centerTitle: true,
        backgroundColor: backgroundColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<PackageInfo>(
        future: _packageInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(
              context,
              snapshot.error.toString(),
              textPrimaryColor,
            );
          }

          final packageInfo = snapshot.data!;
          final isUpdateAvailable = updateProvider.updateAvailable;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Version Info
                  _buildSectionHeader('Current Version', textPrimaryColor),
                  _buildVersionInfoCard(
                    packageInfo,
                    textPrimaryColor,
                    textSecondaryColor,
                    isDarkMode,
                  ),

                  // Update Status Section
                  if (_hasCheckedForUpdate &&
                      !updateProvider.updateAvailable &&
                      !updateProvider.isCheckingForUpdate &&
                      updateProvider.errorMessage == null)
                    _buildUpToDateCard(
                      packageInfo,
                      textPrimaryColor,
                      textSecondaryColor,
                    ),

                  // Check for Updates Button
                  const SizedBox(height: 16),
                  _buildCheckUpdateButton(updateProvider, isUpdateAvailable),

                  // Update Settings Section
                  _buildSectionHeader('Update Settings', textPrimaryColor),
                  _buildUpdateSettingsCard(
                    updateProvider,
                    textPrimaryColor,
                    textSecondaryColor,
                    isDarkMode,
                  ),

                  // Update Available Section
                  if (updateProvider.updateAvailable)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          'New Update Available',
                          textPrimaryColor,
                        ),
                        _buildUpdateAvailableCard(
                          updateProvider,
                          textPrimaryColor,
                          textSecondaryColor,
                          isDarkMode,
                        ),
                      ],
                    ),

                  // Error Message
                  if (updateProvider.errorMessage != null)
                    _buildErrorMessageCard(
                      updateProvider.errorMessage!,
                      textSecondaryColor,
                    ),

                  // Last update check time
                  if (updateProvider.lastUpdateCheckTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text(
                          'Last checked: ${updateProvider.lastUpdateCheckTime}',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: textColor.withOpacity(0.1)),
        ],
      ),
    );
  }

  Widget _buildVersionInfoCard(
    PackageInfo packageInfo,
    Color textPrimaryColor,
    Color textSecondaryColor,
    bool isDarkMode,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    packageInfo.appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})',
                    style: TextStyle(
                      fontSize: 16,
                      color: textPrimaryColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Package: ${packageInfo.packageName}',
                    style: TextStyle(fontSize: 14, color: textSecondaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpToDateCard(
    PackageInfo packageInfo,
    Color textPrimaryColor,
    Color textSecondaryColor,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You\'re up to date!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your app is running the latest version available (${packageInfo.version}).',
                    style: TextStyle(
                      fontSize: 14,
                      color: textPrimaryColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckUpdateButton(
    UpdateProvider updateProvider,
    bool isUpdateAvailable,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            updateProvider.isCheckingForUpdate
                ? null
                : () {
                  updateProvider.checkForUpdate(force: true);
                  setState(() {
                    _hasCheckedForUpdate = true;
                  });
                },
        icon: const Icon(Icons.refresh, size: 20),
        label: const Text('Check for Updates', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildUpdateSettingsCard(
    UpdateProvider updateProvider,
    Color textPrimaryColor,
    Color textSecondaryColor,
    bool isDarkMode,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.update, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Check for updates:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textPrimaryColor,
                  ),
                ),
              ],
            ),
            _buildIntervalOption(
              'Every 12 hours',
              12,
              updateProvider,
              textPrimaryColor,
            ),
            _buildIntervalOption(
              'Every 24 hours',
              24,
              updateProvider,
              textPrimaryColor,
            ),
            _buildIntervalOption(
              'Every 3 days',
              72,
              updateProvider,
              textPrimaryColor,
            ),
            _buildIntervalOption(
              'Every 7 days',
              168,
              updateProvider,
              textPrimaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalOption(
    String title,
    int value,
    UpdateProvider updateProvider,
    Color textColor,
  ) {
    return ListTile(
      title: Text(title, style: TextStyle(color: textColor, fontSize: 15)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Radio<int>(
        value: value,
        groupValue: _selectedCheckInterval,
        onChanged: (newValue) {
          setState(() {
            _selectedCheckInterval = newValue!;
          });
          updateProvider.setUpdateCheckInterval(newValue!);
        },
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildUpdateAvailableCard(
    UpdateProvider updateProvider,
    Color textPrimaryColor,
    Color textSecondaryColor,
    bool isDarkMode,
  ) {
    final updateInfo = updateProvider.updateInfo;
    if (updateInfo == null) return const SizedBox.shrink();

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
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.new_releases, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Version ${updateInfo['latestVersion']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                          ),
                          if (apkSizeFormatted != null)
                            Text(
                              'Size: $apkSizeFormatted',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Release notes
                if (updateInfo['releaseNotes'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What\'s New:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? Colors.black12
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          updateInfo['releaseNotes'] ??
                              'No release notes available',
                          style: TextStyle(
                            fontSize: 14,
                            color: textPrimaryColor.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),

                // "Update Now" button - moved here from the check update button
                const SizedBox(height: 20),
                if (!updateProvider.isDownloading)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          () =>
                              updateProvider.downloadAndInstallUpdate(context),
                      icon: const Icon(Icons.system_update, size: 20),
                      label: const Text(
                        'Update Now',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Download progress if downloading
          if (updateProvider.isDownloading)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black12 : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircularPercentIndicator(
                        radius: 25.0,
                        lineWidth: 5.0,
                        percent: updateProvider.downloadProgress,
                        center: Text(
                          '${(updateProvider.downloadProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: textPrimaryColor,
                          ),
                        ),
                        progressColor: AppColors.primary,
                        backgroundColor:
                            isDarkMode
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDownloadStatusText(
                                updateProvider.downloadProgress,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Please wait until installation starts automatically',
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
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

  Widget _buildErrorMessageCard(String errorMessage, Color textSecondaryColor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Error',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later or contact support if the issue persists.',
                    style: TextStyle(color: textSecondaryColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 64),
            const SizedBox(height: 24),
            Text(
              'Could not load app information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              style: TextStyle(fontSize: 14, color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _packageInfoFuture = PackageInfo.fromPlatform();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
