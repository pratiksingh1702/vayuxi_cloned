import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/global_sync_banner.dart';
import '../../../core/router/app_access.dart';
import '../../../core/router/app_router.dart';
import '../../../core/upload/ui/upload_banner.dart';
import '../../auth/provider/auth_provider.dart';

import '../domain/tour_controller.dart';
import '../domain/tour_step_model.dart';
import 'buddy_overlay.dart';

class GlobalTourOverlay extends ConsumerWidget {
  final Widget child;
  const GlobalTourOverlay({super.key, required this.child});

  Widget _withBanners(Widget child) {
    return Stack(
      children: [
        child,

        // ✅ CHANGE 1: Positioned.fill instead of Positioned(top:0,left:0,right:0)
        // Allows the floating ball inside GlobalUploadBanner to self-position
        // freely across the full screen. Banner mode is unaffected because
        // GlobalUploadBanner internally wraps in SafeArea + top margin.
        const Positioned.fill(
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

    print('''
    isBooting: ${access.isBooting}
    loggedIn: ${access.loggedIn}
    hasSubscription: ${access.hasSubscription}
    trialActivated: ${access.trialActivated}
    planSelected: ${access.planSelected}
  ''');

    final isInsideApp = !access.isBooting && access.loggedIn;

    if (!isInsideApp) {
      return _withBanners(child);
    }

    final tourState = ref.watch(tourControllerProvider);
    final ctrl = ref.read(tourControllerProvider.notifier);
    final step = ctrl.currentStep;
    final router = ref.read(appRouterProvider);

    final showBuddy = tourState.status == TourStatus.running &&
        tourState.buddyVisible &&
        step != null;

    print('''
  tourStatus: ${tourState.status}
  buddyVisible: ${tourState.buddyVisible}
  currentStep: ${ctrl.currentStep?.route}
''');

    return Stack(
      children: [
        child,

        // ✅ CHANGE 2: Same Positioned.fill fix in the main Stack
        // Floating ball needs full-screen coordinate space to drag freely.
        // Banner mode still renders at top — no visual difference.
        const Positioned.fill(
          child: GlobalUploadBanner(),
        ),

        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GlobalSyncBanner(),
        ),

        // ✅ NO CHANGE — buddy overlay untouched
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