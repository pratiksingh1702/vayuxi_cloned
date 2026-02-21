import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import 'tour_controller.dart';

mixin TourAwareMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  void runTourForRoute(String currentRoute, BuildContext showcaseContext) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = ref.read(tourControllerProvider.notifier);

      // ✅ THIS IS THE MISSING LINK
      ctrl.syncToRoute(currentRoute);

      final step = ctrl.currentStep;
      if (step == null) return;

      // ✅ route match check
      final ok = ctrl.steps.indexWhere((s) => s.id == step.id) != -1;
      if (!step.autoShowcase) return;

      final sc = ShowCaseWidget.of(showcaseContext);
      if (sc == null) return;

      sc.startShowCase([step.showcaseKey]);
    });
  }


}
