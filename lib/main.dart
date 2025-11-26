import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'app.dart';
import 'core/api/dio.dart';
import 'core/api/requestQueue.dart';
import 'core/api/syncManager.dart';
import 'features/modules/all_Modules/site_Details/repository/siteHive/siteHiveService.dart';
import 'features/modules/all_Modules/site_Details/repository/siteHive/siteLocalStorage.dart';
import 'features/noti_system/noti_services/bg_handler.dart';
import 'features/noti_system/noti_services/fcm_service.dart';
import 'features/noti_system/noti_services/noti_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Hive with documents directory
  final appDocDir = await path_provider.getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  // Register Hive adapters
  Hive.registerAdapter(SiteModelHiveAdapter());
  // Register other adapters here if you have more

  // Initialize Hive boxes
  await SiteHiveStorage.init(); // Your site storage
  await RequestQueue.init();    // Your request queue

  // Initialize Dio client
  DioClient.init();

  // Initialize Notification System
  await NotificationService.initializeTimezone();
  final notifier = NotificationService();
  await notifier.initialize();

  final fcm = FCMService(notifier);
  await fcm.initialize();

  runApp(const ProviderScope(child: MyApp()));
}