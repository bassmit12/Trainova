import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/github_update_service.dart';

class UpdateProvider extends ChangeNotifier {
  final GitHubUpdateService _updateService;
  bool _isChecking = false;
  Map<String, dynamic>? _updateInfo;

  // How often to check for updates (in hours)
  final int _updateCheckInterval = 24;

  // Last time an update check was performed
  DateTime? _lastUpdateCheck;

  // Key for storing last update check time in SharedPreferences
  static const String _lastCheckKey = 'last_update_check';

  UpdateProvider({
    required String owner,
    required String repo,
  }) : _updateService = GitHubUpdateService(
          owner: owner,
          repo: repo,
        ) {
    // Initialize the provider
    _initialize();
  }

  bool get isChecking => _isChecking;
  Map<String, dynamic>? get updateInfo => _updateInfo;
  bool get updateAvailable =>
      _updateInfo != null && _updateInfo!['updateAvailable'] == true;

  /// Initialize the provider and load the last check time
  Future<void> _initialize() async {
    await _loadLastCheckTime();

    // Check for updates if it's been longer than the interval
    if (_shouldCheckForUpdate()) {
      checkForUpdate();
    }
  }

  /// Load the last update check time from SharedPreferences
  Future<void> _loadLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckTimestamp = prefs.getInt(_lastCheckKey);
      if (lastCheckTimestamp != null) {
        _lastUpdateCheck =
            DateTime.fromMillisecondsSinceEpoch(lastCheckTimestamp);
      }
    } catch (e) {
      debugPrint('Error loading last update check time: $e');
    }
  }

  /// Save the current time as the last update check time
  Future<void> _saveLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setInt(_lastCheckKey, now.millisecondsSinceEpoch);
      _lastUpdateCheck = now;
    } catch (e) {
      debugPrint('Error saving last update check time: $e');
    }
  }

  /// Determine if we should check for an update based on the interval
  bool _shouldCheckForUpdate() {
    if (_lastUpdateCheck == null) {
      return true; // First time, should check
    }

    final now = DateTime.now();
    final difference = now.difference(_lastUpdateCheck!);

    return difference.inHours >= _updateCheckInterval;
  }

  /// Check for updates from GitHub
  Future<void> checkForUpdate({bool force = false}) async {
    // Don't check if already checking
    if (_isChecking) return;

    // Don't check if it hasn't been long enough since the last check
    // unless force is true
    if (!force && !_shouldCheckForUpdate()) return;

    _isChecking = true;
    notifyListeners();

    try {
      _updateInfo = await _updateService.checkForUpdate();
      // Save the current time as the last check time
      await _saveLastCheckTime();
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      _updateInfo = null;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Show the update dialog if an update is available
  Future<void> showUpdateDialogIfAvailable(BuildContext context) async {
    if (updateAvailable) {
      await _updateService.showUpdateDialog(context, _updateInfo!);
    }
  }

  /// Check for updates and show dialog if available
  Future<void> checkAndShowUpdateDialog(BuildContext context) async {
    await checkForUpdate(force: true);
    await showUpdateDialogIfAvailable(context);
  }
}
