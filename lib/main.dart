import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:mobile_rag_engine/mobile_rag_engine.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:untitled2/features/noti_system/updates/domain/services/action_handler_registry.dart';

import 'app.dart';
import 'core/api/dio.dart';
import 'core/api/requestQueue.dart';
import 'core/local/isar_db.dart';
import 'core/upload/handlers/manpower_upload_handler.dart';
import 'core/upload/handlers/dpr_upload_handler.dart';
import 'core/upload/handlers/insulation_dpr_upload_handler.dart';
import 'core/upload/handlers/rate_upload_handler.dart';
import 'core/upload/handlers/site_upload_handler.dart';
import 'core/upload/upload_exports.dart';
import 'features/language/model/download_language.dart';
import 'features/language/model/language_model.dart';
import 'features/modules/all_Modules/site_Details/repository/siteHive/siteHiveService.dart';
import 'features/modules/all_Modules/site_Details/repository/siteHive/siteLocalStorage.dart';
import 'features/noti_system/noti_services/bg_handler.dart';
import 'features/noti_system/noti_services/fcm_service.dart';
import 'features/noti_system/noti_services/noti_service.dart';
import 'features/noti_system/updates/data/repositories/local_notification_repository.dart';

Future<void> main() async {
  debugPaintBaselinesEnabled = false;
  debugPaintSizeEnabled = false;
  debugPaintPointersEnabled = false;
  debugRepaintRainbowEnabled = false;

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    FlutterError.onError = (FlutterErrorDetails details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    final appDocDir = await path_provider.getApplicationDocumentsDirectory();

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
    await fcm.initialize();
    // await MobileRag.initialize(
    //   tokenizerAsset: 'assets/model/tokenizer.json',
    //   modelAsset: 'assets/model/model.onnx',
    //   deferIndexWarmup: true,
    // );

    final container = ProviderContainer();
    DioClient.syncRef = container;
    UploadHandlerRegistry.instance
      ..register(SiteUploadHandler())
      ..register(RateUploadHandler())
      ..register(ManpowerUploadHandler())
      ..register(DprUploadHandler())
      ..register(InsulationDprUploadHandler());

    final updatesRepository = LocalNotificationRepository();

    // In your main.dart or app_startup.dart
    ActionHandlerRegistry.instance
      ..register('snooze_update', (payload) async {
        final hours = payload['hours'] as int? ?? 24;
        // Schedule a local notification reminder
        debugPrint('Snoozed for $hours hours');
      })
      ..register('dpr_remove_notification', (payload) async {
        final id = payload['notificationId']?.toString();
        if (id == null || id.isEmpty) return;
        await updatesRepository.deleteNotification(id);
      });
    runApp(
      DevicePreview(
        enabled: false,
        builder: (_) => UncontrolledProviderScope(
          container: container,
          child: const MyApp(),
        ),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}
