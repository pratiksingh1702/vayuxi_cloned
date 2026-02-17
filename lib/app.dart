
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/syncManager.dart';
import 'core/router/app_router.dart';
import 'custom_slider.dart';
import 'features/modules/all_Modules/rate/screens/global_screen_banner.dart';
import 'features/pricing/providers/razorpay_provider.dart';
import 'features/profile_page/provider/userProvider.dart';
import 'features/tour/domain/tour_scrope.dart';
import 'features/tour/screen/buddy_overlay.dart';
import 'features/tour/screen/global_tour_overlay.dart';
import 'package:bot_toast/bot_toast.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    ref.read(syncManagerProvider);
    ref.read(paymentNotifierProvider.notifier).initializeRazorpay();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'VAYUXI',
      routerConfig: router,
      debugShowCheckedModeBanner: false,

      useInheritedMediaQuery: true,




      builder: (context, child) {
        // ✅ 1) bot toast init
        child = BotToastInit()(context, child);



        // ✅ 3) your overlays
        return TourScope(
          child: GlobalTourOverlay(
            child: child,
          ),
        );
      },

      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFCFE8FA),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: SlidePageTransitionsBuilder(),
            TargetPlatform.iOS: SlidePageTransitionsBuilder(),
          },
        ),
      ),
    );
  }
}
