import 'package:firebase_messaging/firebase_messaging.dart';
import '../noti_services/noti_service.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final service = NotificationService();
  await NotificationService.initializeTimezone();
  await service.initialize();

  service.sendInstantNotification(
    title: message.notification?.title ?? "New Message",
    body: message.notification?.body ?? "",
    payload: message.data.toString(),
  );
}
