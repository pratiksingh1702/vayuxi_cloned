import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/upload/ui/upload_banner.dart';
import '../../../core/router/app_access.dart';
import '../core/tour_models.dart';
import '../providers/tour_providers.dart';
import '../widgets/tour_tooltip_card.dart';

class GlobalTourOverlay extends ConsumerWidget {
  final Widget child;
  const GlobalTourOverlay({super.key, required this.child});

  Widget _withBanners(Widget child) {
    return Stack(
      children: [
        child,
        const Positioned.fill(child: GlobalUploadBanner()),
        // const Positioned(top: 0, left: 0, right: 0, child: GlobalSyncBanner()),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(appAccessProvider);
    final isInsideApp = !access.isBooting && access.loggedIn;

    if (!isInsideApp) return _withBanners(child);

    final tourState = ref.watch(appTourControllerProvider);
    final controller = ref.read(appTourControllerProvider.notifier);
    final tour = controller.activeTour;
    final step = controller.currentStep;
    final showTour = tourState.status == AppTourStatus.running &&
        tour != null &&
        step != null;

    return Stack(
      children: [
        child,
        const Positioned.fill(child: GlobalUploadBanner()),
        // const Positioned(top: 0, left: 0, right: 0, child: GlobalSyncBanner()),
        if (showTour)
          Positioned(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 14,
            child: TourTooltipCard(
              tour: tour!,
              step: step!,
              stepIndex: tourState.stepIndex,
              onBack: () {
                controller.back();
              },
              onNext: () {
                controller.next();
              },
              onSkip: () {
                controller.skip();
              },
            ),
          ),
      ],
    );
  }
}
