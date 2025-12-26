import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance optimization utilities for better app performance

/// Debounce function to limit function calls
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Throttle function to limit function calls to once per duration
class Throttler {
  final Duration delay;
  DateTime? _lastCall;

  Throttler({this.delay = const Duration(milliseconds: 300)});

  bool canCall() {
    final now = DateTime.now();
    if (_lastCall == null || now.difference(_lastCall!) >= delay) {
      _lastCall = now;
      return true;
    }
    return false;
  }
}

/// Simple in-memory cache with TTL (Time To Live)
class MemoryCache<T> {
  final Map<String, _CacheItem<T>> _cache = {};
  final Duration ttl;

  MemoryCache({this.ttl = const Duration(minutes: 5)});

  void put(String key, T value) {
    _cache[key] = _CacheItem<T>(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  T? get(String key) {
    final item = _cache[key];
    if (item == null) return null;
    
    if (DateTime.now().isAfter(item.expiresAt)) {
      _cache.remove(key);
      return null;
    }
    
    return item.value;
  }

  void clear() {
    _cache.clear();
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void cleanup() {
    final now = DateTime.now();
    _cache.removeWhere((key, item) => now.isAfter(item.expiresAt));
  }
}

class _CacheItem<T> {
  final T value;
  final DateTime expiresAt;

  _CacheItem({required this.value, required this.expiresAt});
}

/// Request deduplication to prevent duplicate API calls
class RequestDeduplicator {
  final Map<String, Completer> _pendingRequests = {};

  Future<T> deduplicate<T>(
    String key,
    Future<T> Function() request,
  ) async {
    if (_pendingRequests.containsKey(key)) {
      return _pendingRequests[key]!.future as Future<T>;
    }

    final completer = Completer<T>();
    _pendingRequests[key] = completer;

    try {
      final result = await request();
      completer.complete(result);
      _pendingRequests.remove(key);
      return result;
    } catch (e) {
      completer.completeError(e);
      _pendingRequests.remove(key);
      rethrow;
    }
  }

  void clear() {
    _pendingRequests.clear();
  }
}

/// Performance monitor for tracking operations
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};

  static void start(String operation) {
    _timers[operation] = Stopwatch()..start();
  }

  static void end(String operation) {
    final timer = _timers[operation];
    if (timer != null) {
      timer.stop();
      if (kDebugMode) {
        debugPrint('⏱️ $operation: ${timer.elapsedMilliseconds}ms');
      }
      _timers.remove(operation);
    }
  }

  static void clear() {
    _timers.clear();
  }
}

