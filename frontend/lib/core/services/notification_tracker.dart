/// Tracks which complaints have already triggered notifications
/// to prevent duplicate notifications after user dismissal
class NotificationTracker {
  static final NotificationTracker _instance = NotificationTracker._internal();

  factory NotificationTracker() {
    return _instance;
  }

  NotificationTracker._internal();

  /// Map of complaint_id -> timestamp when notification was shown
  final Map<String, DateTime> _notifiedComplaints = {};

  /// Duration after which a complaint can trigger notification again
  /// even if already notified (default: 1 hour)
  static const Duration _renotifyDelay = Duration(hours: 1);

  /// Mark a complaint as notified
  void markNotified(String complaintId) {
    _notifiedComplaints[complaintId] = DateTime.now();
  }

  /// Check if complaint should trigger a notification
  /// Returns true if:
  /// 1. Never notified before, OR
  /// 2. Last notification was more than _renotifyDelay ago
  bool shouldNotify(String complaintId) {
    final lastNotified = _notifiedComplaints[complaintId];
    
    if (lastNotified == null) {
      // Never notified before
      return true;
    }

    // Check if enough time has passed for re-notification
    final timeSinceNotification = DateTime.now().difference(lastNotified);
    return timeSinceNotification > _renotifyDelay;
  }

  /// Clear all notification history (e.g., on app restart)
  void clear() {
    _notifiedComplaints.clear();
  }

  /// Get debug info about tracked notifications
  Map<String, String> getDebugInfo() {
    return {
      'total_tracked': _notifiedComplaints.length.toString(),
      'tracked_ids': _notifiedComplaints.keys.join(', '),
      'last_update': _notifiedComplaints.isEmpty
          ? 'never'
          : _notifiedComplaints.values.last.toString(),
    };
  }
}
