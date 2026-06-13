import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import 'tour_models.dart';

class TourPackageAdapter {
  const TourPackageAdapter();

  Future<void> showStep(BuildContext showcaseContext, AppTourStep step) async {
    final showcase = ShowCaseWidget.of(showcaseContext);
    final targetKey = step.targetKey;
    if (!step.useSpotlight || targetKey == null) {
      showcase?.dismiss();
      return;
    }
    showcase?.dismiss();

    if (step.autoScrollToTarget) {
      var targetContext = targetKey.currentContext;
      if (targetContext == null) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        targetContext = targetKey.currentContext;
      }
      if (targetContext != null) {
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOutCubic,
          alignment: 0.42,
        );
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
    }
    if (!showcaseContext.mounted) return;
    ShowCaseWidget.of(showcaseContext)?.startShowCase([targetKey]);
  }

  void dismiss(BuildContext showcaseContext) {
    ShowCaseWidget.of(showcaseContext)?.dismiss();
  }
}
