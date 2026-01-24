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
import 'features/language/model/download_language.dart';
import 'features/language/model/language_model.dart';
import 'features/modules/all_Modules/dpr/models/hive_storage_service.dart';
import 'features/modules/all_Modules/dpr/offline/data/local/isar_db.dart';
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
  IsarDB.init();
  await Hive.initFlutter(appDocDir.path);

  Hive.registerAdapter(LanguageModuleAdapter());

  await Hive.openBox('language_meta');
  await Hive.openBox<LanguageModule>('language_modules');



  Hive.registerAdapter(DownloadLanguageAdapter());

  await Hive.openBox('language_meta');
  await Hive.openBox<LanguageModule>('language_modules');
  await Hive.openBox<DownloadLanguage>('downloaded_languages');

  Hive.registerAdapter(SiteModelHiveAdapter());
  // Initialize Hive
  // await HiveStorageService.init();

  await SiteHiveStorage.init();
  await RequestQueue.init();

  DioClient.init();

  await NotificationService.initializeTimezone();
  final notifier = NotificationService();
  await notifier.initialize();

  final fcm = FCMService(notifier);
  await fcm.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
