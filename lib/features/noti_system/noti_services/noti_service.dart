import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Initialize timezone data
  static Future<void> initializeTimezone() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  }

  // Initialize notification service
  Future<bool> initialize() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final bool? initialized = await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Setup Android notification channel (required for Android 8.0+)
    await _setupNotificationChannels();
    print("${DateTime.now()} - Notification service initialized");

    return initialized ?? false;
  }

  // Setup notification channels for Android
  Future<void> _setupNotificationChannels() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'scheduled_notifications',
      'Scheduled Notifications',
      description: 'Notifications for daily reminders and schedules',
      importance: Importance.high,
      playSound: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Create channel for instant notifications
    const AndroidNotificationChannel instantChannel = AndroidNotificationChannel(
      'immediate_notifications',
      'Instant Notifications',
      description: 'Instant notifications',
      importance: Importance.high,
      playSound: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(instantChannel);
  }

// Schedule a daily notification
  Future<bool> scheduleDailyNotification({
    required String title,
    required String body,
    required int hour,
    required int minute,
    int? id,
  }) async {
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;
      final scheduledTime = _nextInstanceOfTime(hour, minute);

      // Add detailed logging
      print('''
📅 SCHEDULING NOTIFICATION:
   ID: $notificationId
   Title: $title
   Body: $body
   Scheduled for: $hour:$minute
   Exact scheduled time: $scheduledTime
   Current time: ${tz.TZDateTime.now(tz.local)}
   Time until notification: ${scheduledTime.difference(tz.TZDateTime.now(tz.local))}
''');

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'scheduled_notifications',
            'Scheduled Notifications',
            channelDescription: 'Daily scheduled notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            sound: 'default',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ NOTIFICATION SCHEDULED SUCCESSFULLY');
      return true;
    } catch (error) {
      print('❌ ERROR SCHEDULING NOTIFICATION: $error');
      return false;
    }
  }

  // Calculate next occurrence of specified time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
  // Handle FCM notifications (called from FCM service)
  void handleFCMNotification(Map<String, dynamic> message) {
    final notification = message['notification'];
    final data = message['data'];

    if (notification != null) {
      sendInstantNotification(
        title: notification['title'] ?? 'New Message',
        body: notification['body'] ?? '',
        payload: data?.toString(),
      );
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap here
    // You can navigate to specific screens based on notification payload
    print('Notification tapped: ${response.payload}');
  }

  // Send instant notification
  Future<void> sendInstantNotification({
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? channelName,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId ?? 'immediate_notifications',
        channelName ?? 'Instant Notifications',
        channelDescription: 'Instant notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;

      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (error) {
      print('Error sending instant notification: $error');
    }
  }

  // Send progress notification
  Future<void> sendProgressNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'progress_notifications',
      'Progress Notifications',
      channelDescription: 'Notifications showing progress',
      importance: Importance.high,
      priority: Priority.high,
      channelAction: AndroidNotificationChannelAction.update,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
    );
  }

  // Update progress notification
  Future<void> updateProgressNotification({
    required int id,
    required int progress,
    required int maxProgress,
    String? title,
    String? body,
  }) async {
    await sendProgressNotification(
      id: id,
      title: title ?? 'Downloading...',
      body: body ?? 'Progress: $progress/$maxProgress',
      progress: progress,
      maxProgress: maxProgress,
    );
  }
}