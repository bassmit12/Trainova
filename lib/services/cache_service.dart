import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive caching service for app data
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  /// Default cache duration (30 minutes)
  static const Duration defaultCacheDuration = Duration(minutes: 30);

  /// Initialize the cache service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Store data in both memory and persistent cache
  Future<void> store<T>(
    String key, 
    T data, {
    Duration? duration,
    bool memoryOnly = false,
  }) async {
    // Store in memory cache
    _memoryCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();

    // Store in persistent cache unless memory-only
    if (!memoryOnly && _prefs != null) {
      try {
        final cacheData = {
          'data': data,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'duration': (duration ?? defaultCacheDuration).inMilliseconds,
        };
        await _prefs!.setString(key, jsonEncode(cacheData));
      } catch (e) {
        debugPrint('Failed to persist cache data for key $key: $e');
      }
    }
  }

  /// Retrieve data from cache
  T? get<T>(String key, {Duration? maxAge}) {
    final age = maxAge ?? defaultCacheDuration;
    
    // Check memory cache first
    if (_memoryCache.containsKey(key) && _cacheTimestamps.containsKey(key)) {
      final timestamp = _cacheTimestamps[key]!;
      if (DateTime.now().difference(timestamp) < age) {
        return _memoryCache[key] as T?;
      } else {
        // Remove expired memory cache
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }

    // Check persistent cache
    if (_prefs != null) {
      try {
        final cachedString = _prefs!.getString(key);
        if (cachedString != null) {
          final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
          final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
          final duration = Duration(milliseconds: cacheData['duration']);
          
          if (DateTime.now().difference(timestamp) < duration) {
            final data = cacheData['data'] as T;
            // Also store in memory for faster access
            _memoryCache[key] = data;
            _cacheTimestamps[key] = timestamp;
            return data;
          } else {
            // Remove expired cache
            _prefs!.remove(key);
          }
        }
      } catch (e) {
        debugPrint('Failed to retrieve cache data for key $key: $e');
        // Remove corrupted cache
        _prefs?.remove(key);
      }
    }

    return null;
  }

  /// Check if data exists in cache and is not expired
  bool has(String key, {Duration? maxAge}) {
    return get<dynamic>(key, maxAge: maxAge) != null;
  }

  /// Remove specific cache entry
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    await _prefs?.remove(key);
  }

  /// Clear all cache data
  Future<void> clearAll() async {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    
    if (_prefs != null) {
      // Get all cache keys (assume they start with 'cache_')
      final keys = _prefs!.getKeys().where((key) => key.startsWith('cache_'));
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpired() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    // Check memory cache
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > defaultCacheDuration) {
        expiredKeys.add(key);
      }
    });

    // Remove expired memory cache
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    // Check and clean persistent cache
    if (_prefs != null) {
      final keys = _prefs!.getKeys().where((key) => key.startsWith('cache_'));
      for (final key in keys) {
        try {
          final cachedString = _prefs!.getString(key);
          if (cachedString != null) {
            final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
            final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
            final duration = Duration(milliseconds: cacheData['duration']);
            
            if (now.difference(timestamp) > duration) {
              await _prefs!.remove(key);
            }
          }
        } catch (e) {
          // Remove corrupted cache
          await _prefs!.remove(key);
        }
      }
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'memoryEntries': _memoryCache.length,
      'persistentEntries': _prefs?.getKeys().where((key) => key.startsWith('cache_')).length ?? 0,
      'memorySize': _calculateMemorySize(),
    };
  }

  int _calculateMemorySize() {
    int size = 0;
    _memoryCache.forEach((key, value) {
      size += key.length * 2; // Rough estimate for string
      if (value is String) {
        size += value.length * 2;
      } else if (value is List) {
        size += value.length * 8; // Rough estimate
      } else if (value is Map) {
        size += value.length * 16; // Rough estimate
      } else {
        size += 8; // Default estimate
      }
    });
    return size;
  }
}