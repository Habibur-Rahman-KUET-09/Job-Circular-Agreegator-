import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  late FirebaseMessaging _firebaseMessaging;
  late FlutterLocalNotificationsPlugin _localNotifications;

  bool _isInitialized = false;
  final List<Map<String, dynamic>> _notificationHistory = [];

  List<Map<String, dynamic>> get notificationHistory => _notificationHistory;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _firebaseMessaging = FirebaseMessaging.instance;
    _localNotifications = FlutterLocalNotificationsPlugin();

    // Request notification permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carryForward: true,
      criticalSound: true,
      provisional: false,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestAlertPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    _isInitialized = true;
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');

    _addToHistory(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      timestamp: DateTime.now(),
      type: message.data['type'] ?? 'general',
    );

    _showLocalNotification(
      title: message.notification?.title ?? 'Job Circular Aggregator',
      body: message.notification?.body ?? '',
      payload: message.data,
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened from background: ${message.notification?.title}');
    // Handle navigation based on message data
    if (message.data['type'] == 'application_update') {
      // Navigate to applications screen
    } else if (message.data['type'] == 'job_deadline') {
      // Navigate to saved jobs screen
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'job_circular_channel',
      'Job Circular Notifications',
      channelDescription: 'Notifications for job circulars and applications',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload != null ? Uri(queryParameters: payload).query : null,
    );
  }

  void _addToHistory({
    required String title,
    required String body,
    required DateTime timestamp,
    required String type,
  }) {
    _notificationHistory.insert(0, {
      'title': title,
      'body': body,
      'timestamp': timestamp,
      'type': type,
      'read': false,
    });

    // Keep only last 50 notifications
    if (_notificationHistory.length > 50) {
      _notificationHistory.removeLast();
    }
  }

  // Send local deadline reminder
  Future<void> scheduleDeadlineReminder({
    required String jobId,
    required String jobTitle,
    required String company,
    required DateTime deadline,
  }) async {
    final now = DateTime.now();
    final thirtyDaysBefore = deadline.subtract(const Duration(days: 30));
    final sevenDaysBefore = deadline.subtract(const Duration(days: 7));
    final oneDayBefore = deadline.subtract(const Duration(days: 1));

    // Schedule 30-day reminder
    if (now.isBefore(thirtyDaysBefore)) {
      await _localNotifications.zonedSchedule(
        jobId.hashCode + 1,
        'Application Deadline Reminder',
        '30 days left to apply for $jobTitle at $company',
        thirtyDaysBefore,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'deadline_reminders',
            'Deadline Reminders',
            channelDescription: 'Reminders for job application deadlines',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Schedule 7-day reminder
    if (now.isBefore(sevenDaysBefore)) {
      await _localNotifications.zonedSchedule(
        jobId.hashCode + 2,
        'Application Deadline Reminder',
        '7 days left to apply for $jobTitle at $company',
        sevenDaysBefore,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'deadline_reminders',
            'Deadline Reminders',
            channelDescription: 'Reminders for job application deadlines',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // Schedule 1-day reminder
    if (now.isBefore(oneDayBefore)) {
      await _localNotifications.zonedSchedule(
        jobId.hashCode + 3,
        'Urgent: Application Deadline Tomorrow!',
        'Last chance to apply for $jobTitle at $company',
        oneDayBefore,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'deadline_reminders',
            'Deadline Reminders',
            channelDescription: 'Reminders for job application deadlines',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            enableLights: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelDeadlineReminder(String jobId) async {
    await _localNotifications.cancel(jobId.hashCode + 1);
    await _localNotifications.cancel(jobId.hashCode + 2);
    await _localNotifications.cancel(jobId.hashCode + 3);
  }

  Future<void> enableNotifications(String userId) async {
    // Subscribe to user-specific topics
    await _firebaseMessaging.subscribeToTopic('user_$userId');
    await _firebaseMessaging.subscribeToTopic('job_updates');
  }

  Future<void> disableNotifications(String userId) async {
    // Unsubscribe from user-specific topics
    await _firebaseMessaging.unsubscribeFromTopic('user_$userId');
    await _firebaseMessaging.unsubscribeFromTopic('job_updates');
  }

  void markNotificationAsRead(int index) {
    if (index < _notificationHistory.length) {
      _notificationHistory[index]['read'] = true;
    }
  }

  int getUnreadCount() {
    return _notificationHistory.where((n) => n['read'] == false).length;
  }

  void clearHistory() {
    _notificationHistory.clear();
  }
}
