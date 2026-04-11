import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../noti_services/noti_service.dart';
import '../updates/domain/services/notification_ingestion_service.dart';
import 'noti-api.dart';

class FCMService {
  final NotificationService _noti;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final app = Firebase.app();

  FCMService(this._noti);

  Future<void> initialize() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("❤️❤️❤️❤️❤️❤️❤️");

    print("Project ID: ${app.options.projectId}");
    print("App ID: ${app.options.appId}");
    print("Sender ID: ${app.options.messagingSenderId}");
    print("API Key: ${app.options.apiKey}");

    final token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      await NotiApi().saveTokenIfNeeded(token);
    }

    print("🔥 FCM Token: $token");

    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onBackground);
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await NotiApi().saveTokenIfNeeded(newToken);
    });

    _fcm.getInitialMessage().then(_onTerminated);
  }

  void _onForeground(RemoteMessage m) {
    NotificationIngestionService.persistRemoteMessage(m);
    _noti.sendInstantNotification(
      title: m.notification?.title ?? "Message",
      body: m.notification?.body ?? "",
      payload: m.data.toString(),
      isFromFCM: true, // ✅ only here
    );
  }

  void _onBackground(RemoteMessage m) {
    NotificationIngestionService.persistRemoteMessage(m);
    print("🌙 Background message: ${m.messageId}");
  }

  void _onTerminated(RemoteMessage? m) {
    if (m == null) return;
    NotificationIngestionService.persistRemoteMessage(m);
    print("💀 Terminated message: ${m.messageId}");
  }
}
