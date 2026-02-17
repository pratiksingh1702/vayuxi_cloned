import 'package:firebase_messaging/firebase_messaging.dart';
import '../noti_services/noti_service.dart';
import 'package:firebase_core/firebase_core.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ✅ IMPORTANT: initialize firebase in background isolate
  await Firebase.initializeApp();

  final service = NotificationService();
  await NotificationService.initializeTimezone();
  await service.initialize();
  await service.vibrateNow();

  await service.sendInstantNotification(
    title: message.notification?.title ?? "New Message",
    body: message.notification?.body ?? "",
    payload: message.data.toString(),
    isFromFCM: true
  );
}
