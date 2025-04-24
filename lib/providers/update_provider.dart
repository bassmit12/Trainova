import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/github_api_service.dart';
import '../services/update_service.dart';

class UpdateProvider extends ChangeNotifier {
  final GitHubApiService _githubApiService;
  final UpdateService _updateService;

  bool _isCheckingForUpdate = false;
  bool _updateAvailable = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  Map<String, dynamic>? _updateInfo;
  String? _errorMessage;

  // Last time update was checked
  DateTime? _lastUpdateCheck;

  // How often to check for updates (in hours)
  int _updateCheckInterval = 24;

  UpdateProvider({required String githubOwner, required String githubRepo})
    : _githubApiService = GitHubApiService(
        owner: githubOwner,
        repository: githubRepo,
      ),
      _updateService = UpdateService(
        githubApiService: GitHubApiService(
          owner: githubOwner,
          repository: githubRepo,
        ),
      ) {
    _loadLastCheckTime();
  }

  bool get isCheckingForUpdate => _isCheckingForUpdate;
  bool get updateAvailable => _updateAvailable;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  Map<String, dynamic>? get updateInfo => _updateInfo;
  String? get errorMessage => _errorMessage;
  int get updateCheckInterval => _updateCheckInterval;

  // Format and expose the last update check time
  String? get lastUpdateCheckTime {
    if (_lastUpdateCheck == null) return null;

    final formatter = DateFormat('MMM d, yyyy - h:mm a');
    return formatter.format(_lastUpdateCheck!);
  }

  // Load the last update check time from SharedPreferences
  Future<void> _loadLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckMillis = prefs.getInt('last_update_check');
    if (lastCheckMillis != null) {
      _lastUpdateCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMillis);
    }

    _updateCheckInterval = prefs.getInt('update_check_interval') ?? 24;
  }

  // Save the current time as the last update check time
  Future<void> _saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    _lastUpdateCheck = DateTime.now();
    await prefs.setInt(
      'last_update_check',
      _lastUpdateCheck!.millisecondsSinceEpoch,
    );
  }

  // Set update check interval (in hours)
  Future<void> setUpdateCheckInterval(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    _updateCheckInterval = hours;
    await prefs.setInt('update_check_interval', hours);
    notifyListeners();
  }

  // Check if it's time to check for updates
  bool shouldCheckForUpdate() {
    if (_lastUpdateCheck == null) return true;

    final now = DateTime.now();
    final difference = now.difference(_lastUpdateCheck!);
    return difference.inHours >= _updateCheckInterval;
  }

  // Check for updates
  Future<void> checkForUpdate({bool force = false}) async {
    // Only check if forced or if it's time to check
    if (!force && !shouldCheckForUpdate()) return;

    try {
      _isCheckingForUpdate = true;
      _errorMessage = null;
      notifyListeners();

      // Check if an update is available
      _updateAvailable = await _updateService.checkForUpdate();

      if (_updateAvailable) {
        // Get update information
        _updateInfo = await _githubApiService.getUpdateInfo();
        print(
          'Update available: ${_updateInfo?['latestVersion']} (current: ${_updateInfo?['currentVersion']})',
        );
      } else {
        print('No updates available or current version is latest');
      }

      // Save the check time regardless of result
      await _saveLastCheckTime();
    } catch (e) {
      _errorMessage =
          'Error checking for updates. Please check your internet connection and try again.';
      print('Update check error: $e');
    } finally {
      _isCheckingForUpdate = false;
      notifyListeners();
    }
  }

  // Download and install the update
  Future<void> downloadAndInstallUpdate(BuildContext context) async {
    if (!_updateAvailable || _isDownloading) return;

    _isDownloading = true;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    await _updateService.downloadAndInstallUpdate(
      context,
      onProgress: (progress) {
        _downloadProgress = progress;
        notifyListeners();
      },
      onSuccess: () {
        _isDownloading = false;
        notifyListeners();
      },
      onError: (error) {
        _isDownloading = false;
        _errorMessage = error;
        notifyListeners();
      },
    );
  }

  // Reset the update state (e.g., if the user dismisses the update notification)
  void resetUpdateState() {
    _updateAvailable = false;
    _isDownloading = false;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();
  }
}
