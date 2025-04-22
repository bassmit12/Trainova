import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/update_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/update_notification_widget.dart';

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({Key? key}) : super(key: key);

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  late Future<PackageInfo> _packageInfoFuture;
  int _selectedCheckInterval = 24; // Default: 24 hours

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Updates'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<PackageInfo>(
        future: _packageInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final packageInfo = snapshot.data!;
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Version',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'App Name: ${packageInfo.appName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Package: ${packageInfo.packageName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Update Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Check for updates:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          ListTile(
                            title: const Text('Every 12 hours'),
                            leading: Radio<int>(
                              value: 12,
                              groupValue: _selectedCheckInterval,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCheckInterval = value!;
                                });
                                updateProvider.setUpdateCheckInterval(value!);
                              },
                              activeColor: AppColors.primary,
                            ),
                          ),
                          ListTile(
                            title: const Text('Every 24 hours'),
                            leading: Radio<int>(
                              value: 24,
                              groupValue: _selectedCheckInterval,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCheckInterval = value!;
                                });
                                updateProvider.setUpdateCheckInterval(value!);
                              },
                              activeColor: AppColors.primary,
                            ),
                          ),
                          ListTile(
                            title: const Text('Every 3 days'),
                            leading: Radio<int>(
                              value: 72,
                              groupValue: _selectedCheckInterval,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCheckInterval = value!;
                                });
                                updateProvider.setUpdateCheckInterval(value!);
                              },
                              activeColor: AppColors.primary,
                            ),
                          ),
                          ListTile(
                            title: const Text('Every 7 days'),
                            leading: Radio<int>(
                              value: 168,
                              groupValue: _selectedCheckInterval,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCheckInterval = value!;
                                });
                                updateProvider.setUpdateCheckInterval(value!);
                              },
                              activeColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: updateProvider.isCheckingForUpdate
                          ? null
                          : () {
                              updateProvider.checkForUpdate(force: true);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: updateProvider.isCheckingForUpdate
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text('Check for Updates'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (updateProvider.updateAvailable)
                    const UpdateNotificationWidget(
                      dismissible: false,
                    ),
                  if (updateProvider.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              updateProvider.errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Last update check time
                  if (updateProvider.lastUpdateCheckTime != null)
                    Text(
                      'Last checked: ${updateProvider.lastUpdateCheckTime}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}