import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'app.dart';
import 'core/api/dio.dart';
import 'core/api/requestQueue.dart';
import 'features/modules/all_Modules/site_Details/repository/siteHive/siteHiveService.dart';
import 'features/modules/all_Modules/site_Details/repository/siteHive/siteLocalStorage.dart';
import 'features/noti_system/noti_services/bg_handler.dart';
import 'features/noti_system/noti_services/fcm_service.dart';
import 'features/noti_system/noti_services/noti_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final appDocDir = await path_provider.getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  Hive.registerAdapter(SiteModelHiveAdapter());

  await SiteHiveStorage.init();
  await RequestQueue.init();

  DioClient.init();

  await NotificationService.initializeTimezone();
  final notifier = NotificationService();
  await notifier.initialize();

  final fcm = FCMService(notifier);
  await fcm.initialize();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // 🔥 DEBUG ONLY
      builder: (context) => const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}
