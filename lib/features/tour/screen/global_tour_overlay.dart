import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/global_sync_banner.dart';
import '../../../core/router/app_access.dart';
import '../../../core/router/app_router.dart';
import '../../auth/provider/auth_provider.dart';
import '../../modules/all_Modules/rate/screens/global_screen_banner.dart';
import '../domain/tour_controller.dart';
import '../domain/tour_step_model.dart';
import 'buddy_overlay.dart';

class GlobalTourOverlay extends ConsumerWidget {
  final Widget child;
  const GlobalTourOverlay({super.key, required this.child});

  // The banners are always shown regardless of tour/auth state
  Widget _withBanners(Widget child) {
    return Stack(
      children: [
        child,
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GlobalUploadBanner(),
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GlobalSyncBanner(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(appAccessProvider);

    // User must be fully inside the app before we even think about tour UI
    final isInsideApp = !access.isBooting &&
        access.loggedIn &&
        (access.hasSubscription || access.trialActivated);

    if (!isInsideApp) {
      // Still booting / on auth/onboarding screens → only show banners
      return _withBanners(child);
    }

    final tourState = ref.watch(tourControllerProvider);
    final ctrl = ref.read(tourControllerProvider.notifier);
    final step = ctrl.currentStep;
    final router = ref.read(appRouterProvider);

    final showBuddy =
        tourState.status == TourStatus.running &&
            tourState.buddyVisible &&
            step != null;

    return Stack(
      children: [
        child,
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GlobalUploadBanner(),
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GlobalSyncBanner(),
        ),

        if (showBuddy)
          Positioned(
            top: 15,
            left: 0,
            right: 12,
            child: SizedBox(
              width: 200,
              child: BuddyOverlay(
                title: step!.title ?? "",
                message: step.buddyMessage,
                onSkip: () => ctrl.skip(),
                onHide: () => ctrl.hideBuddy(),
                onNext: () async {
                  await ctrl.next();
                  final nextStep = ctrl.currentStep;
                  if (nextStep != null) {
                    router.go(nextStep.route);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}