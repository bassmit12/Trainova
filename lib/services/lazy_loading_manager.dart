import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage lazy loading of non-critical services after app startup
class LazyLoadingManager {
  static final LazyLoadingManager _instance = LazyLoadingManager._internal();
  factory LazyLoadingManager() => _instance;
  LazyLoadingManager._internal();

  bool _isInitialized = false;
  final Set<String> _loadedServices = {};
  final Map<String, Future<void> Function()> _serviceLoaders = {};

  /// Register a service to be loaded lazily
  void registerService(String serviceName, Future<void> Function() loader) {
    _serviceLoaders[serviceName] = loader;
  }

  /// Initialize all registered services after UI is ready
  Future<void> initializeNonCriticalServices() async {
    if (_isInitialized) return;
    
    _isInitialized = true;
    
    // Load services in parallel with error handling
    final futures = _serviceLoaders.entries.map((entry) async {
      try {
        await entry.value();
        _loadedServices.add(entry.key);
        debugPrint('Lazy loaded service: ${entry.key}');
      } catch (e) {
        debugPrint('Failed to lazy load service ${entry.key}: $e');
      }
    });

    await Future.wait(futures);
    debugPrint('Lazy loading completed. Loaded ${_loadedServices.length} services');
  }

  /// Check if a specific service has been loaded
  bool isServiceLoaded(String serviceName) => _loadedServices.contains(serviceName);

  /// Get loading progress (0.0 to 1.0)
  double get loadingProgress {
    if (_serviceLoaders.isEmpty) return 1.0;
    return _loadedServices.length / _serviceLoaders.length;
  }
}