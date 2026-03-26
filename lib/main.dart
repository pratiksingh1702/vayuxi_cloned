import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:flutter/foundation.dart';
import 'dart:io';

import 'app.dart';
import 'core/api/dio.dart';
import 'core/api/requestQueue.dart';
import 'core/local/isar_db.dart';
import 'features/language/model/download_language.dart';
import 'features/language/model/language_model.dart';
import 'features/modules/all_Modules/dpr/models/hive_storage_service.dart';
import 'features/modules/all_Modules/dpr/offline/data/local/isar_db.dart';
import 'features/modules/all_Modules/site_Details/repository/siteHive/siteHiveService.dart';
import 'features/modules/all_Modules/site_Details/repository/siteHive/siteLocalStorage.dart';
import 'features/modules/all_Modules/team/offline/state/isar_provider.dart';
import 'features/noti_system/noti_services/bg_handler.dart';
import 'features/noti_system/noti_services/fcm_service.dart';
import 'features/noti_system/noti_services/noti_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ STEP 1: Initialize Firebase BEFORE everything
  await Firebase.initializeApp();

  // Debug flags
  debugPaintBaselinesEnabled = false;
  debugPaintSizeEnabled = false;
  debugPaintPointersEnabled = false;
  debugRepaintRainbowEnabled = false;

  // ✅ STEP 2: Setup Crashlytics safely
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(true);

  FlutterError.onError = (FlutterErrorDetails details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // ✅ STEP 3: Wrap ONLY runApp part inside zone
  runZonedGuarded(() async {
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    final appDocDir =
        await path_provider.getApplicationDocumentsDirectory();

    await AppIsarDB.init();
    await Hive.initFlutter(appDocDir.path);

    Hive.registerAdapter(LanguageModuleAdapter());
    await Hive.openBox('language_meta');
    await Hive.openBox<LanguageModule>('language_modules');

    Hive.registerAdapter(DownloadLanguageAdapter());
    await Hive.openBox<DownloadLanguage>('downloaded_languages');

    Hive.registerAdapter(SiteModelHiveAdapter());

    await SiteHiveStorage.init();
    await RequestQueue.init();

    DioClient.init();

    await NotificationService.initializeTimezone();
    final notifier = NotificationService();
    await notifier.initialize();

    final fcm = FCMService(notifier);
    if (Platform.isAndroid) {
  await fcm.initialize();
}

    final container = ProviderContainer();
    DioClient.syncRef = container;

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    // ✅ Firebase is guaranteed initialized here
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
    );
  });
}