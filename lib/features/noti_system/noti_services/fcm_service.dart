import 'package:firebase_messaging/firebase_messaging.dart';
import '../noti_services/noti_service.dart';

class FCMService {
  final NotificationService _noti;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  FCMService(this._noti);

  Future<void> initialize() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("❤️❤️❤️❤️❤️❤️❤️");

    final token = await _fcm.getToken();
    print("🔥 FCM Token: $token");

    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onBackground);

    _fcm.getInitialMessage().then(_onTerminated);
  }

  void _onForeground(RemoteMessage m) {
    print("⚡Foreground message: ${m.messageId}");
    _noti.sendInstantNotification(
      title: m.notification?.title ?? "Message",
      body: m.notification?.body ?? "",
      payload: m.data.toString(),
    );
  }

  void _onBackground(RemoteMessage m) {
    print("🌙 Background message: ${m.messageId}");
  }

  void _onTerminated(RemoteMessage? m) {
    if (m == null) return;
    print("💀 Terminated message: ${m.messageId}");
  }
}
