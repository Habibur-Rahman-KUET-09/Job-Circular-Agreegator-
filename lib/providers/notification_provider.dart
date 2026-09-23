import 'package:flutter/foundation.dart';

import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;

  NotificationProvider(this._notificationService);

  bool _notificationsEnabled = true;
  int _unreadCount = 0;
  bool _isInitialized = false;

  bool get notificationsEnabled => _notificationsEnabled;
  int get unreadCount => _unreadCount;
  List<Map<String, dynamic>> get notificationHistory =>
      _notificationService.notificationHistory;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _notificationService.initialize();
    _isInitialized = true;
    _updateUnreadCount();
    notifyListeners();
  }

  Future<String?> getFCMToken() async {
    return await _notificationService.getFCMToken();
  }

  Future<void> enableNotifications(String userId) async {
    _notificationsEnabled = true;
    await _notificationService.enableNotifications(userId);
    notifyListeners();
  }

  Future<void> disableNotifications(String userId) async {
    _notificationsEnabled = false;
    await _notificationService.disableNotifications(userId);
    notifyListeners();
  }

  Future<void> scheduleDeadlineReminder({
    required String jobId,
    required String jobTitle,
    required String company,
    required DateTime deadline,
  }) async {
    await _notificationService.scheduleDeadlineReminder(
      jobId: jobId,
      jobTitle: jobTitle,
      company: company,
      deadline: deadline,
    );
    notifyListeners();
  }

  Future<void> cancelDeadlineReminder(String jobId) async {
    await _notificationService.cancelDeadlineReminder(jobId);
    notifyListeners();
  }

  void markNotificationAsRead(int index) {
    _notificationService.markNotificationAsRead(index);
    _updateUnreadCount();
    notifyListeners();
  }

  void markAllAsRead() {
    for (int i = 0; i < notificationHistory.length; i++) {
      _notificationService.markNotificationAsRead(i);
    }
    _updateUnreadCount();
    notifyListeners();
  }

  void clearHistory() {
    _notificationService.clearHistory();
    _updateUnreadCount();
    notifyListeners();
  }

  void _updateUnreadCount() {
    _unreadCount = _notificationService.getUnreadCount();
  }
}
