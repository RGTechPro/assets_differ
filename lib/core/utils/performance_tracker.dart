import 'dart:developer' as developer;

/// A utility class for tracking performance metrics throughout the app
class PerformanceTracker {
  static final Map<String, Stopwatch> _activeTrackers = {};
  static final Map<String, List<Duration>> _trackerHistory = {};
  
  /// Start tracking a named operation
  static void startTracking(String operationName) {
    final stopwatch = Stopwatch()..start();
    _activeTrackers[operationName] = stopwatch;
    developer.log('⏱️ Started tracking: $operationName', name: 'Performance');
  }
  
  /// End tracking a named operation and log the elapsed time
  /// Returns the elapsed time in milliseconds
  static int endTracking(String operationName) {
    final stopwatch = _activeTrackers.remove(operationName);
    if (stopwatch == null) {
      developer.log('⚠️ No active tracker found for: $operationName', name: 'Performance');
      return 0;
    }
    
    stopwatch.stop();
    final elapsed = stopwatch.elapsed;
    
    // Store in history for later analysis
    if (!_trackerHistory.containsKey(operationName)) {
      _trackerHistory[operationName] = [];
    }
    _trackerHistory[operationName]!.add(elapsed);
    
    final elapsedMs = elapsed.inMilliseconds;
    developer.log('⏱️ $operationName completed in ${elapsedMs}ms', name: 'Performance');
    return elapsedMs;
  }
  
  /// Track a function execution time and return its result
  static Future<T> trackAsync<T>(String operationName, Future<T> Function() function) async {
    startTracking(operationName);
    try {
      final result = await function();
      endTracking(operationName);
      return result;
    } catch (e) {
      endTracking(operationName);
      rethrow;
    }
  }
  
  /// Get the history of execution times for a specific operation
  static List<Duration> getHistory(String operationName) {
    return _trackerHistory[operationName] ?? [];
  }
  
  /// Get a summary of all tracked operations
  static Map<String, Map<String, dynamic>> getSummary() {
    final Map<String, Map<String, dynamic>> summary = {};
    
    _trackerHistory.forEach((operation, durations) {
      if (durations.isEmpty) return;
      
      // Calculate statistics
      final totalMs = durations.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
      final avgMs = totalMs / durations.length;
      final minMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
      final maxMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
      
      summary[operation] = {
        'count': durations.length,
        'average_ms': avgMs,
        'min_ms': minMs,
        'max_ms': maxMs,
        'total_ms': totalMs,
      };
    });
    
    return summary;
  }
  
  /// Log the complete performance summary
  static void logSummary() {
    final summary = getSummary();
    developer.log('📊 Performance Summary:', name: 'Performance');
    
    summary.forEach((operation, stats) {
      developer.log(
        '  $operation: ${stats['count']} calls, avg: ${stats['average_ms'].toStringAsFixed(2)}ms, '
        'min: ${stats['min_ms']}ms, max: ${stats['max_ms']}ms, '
        'total: ${stats['total_ms']}ms',
        name: 'Performance'
      );
    });
  }
}