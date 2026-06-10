import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/syncManager.dart';
import 'core/api/network_mode_banner.dart';
import 'core/router/app_router.dart';
import 'features/modules/all_Modules/more/theme/provider/theme_controller.dart';
import 'features/pricing/providers/razorpay_provider.dart';
import 'features/tour/domain/tour_scrope.dart';
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
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'VAYUXI',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: (context, child) {
        final appChild = child ?? const SizedBox.shrink();
        final previewed = DevicePreview.appBuilder(context, appChild);
        final toasted = BotToastInit()(context, previewed);
        return TourScope(
          child: GlobalTourOverlay(
            child: Stack(
              children: [
                toasted,
                const NetworkModeBanner(),
              ],
            ),
          ),
        );
      },
      theme: themeState.lightTheme,
      darkTheme: themeState.darkTheme,
      themeMode: themeState.themeMode,
    );
  }
}
