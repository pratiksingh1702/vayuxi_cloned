import 'package:flutter/widgets.dart';
import 'package:showcaseview/showcaseview.dart';

import 'tour_models.dart';

class TourPackageAdapter {
  const TourPackageAdapter();

  void showStep(BuildContext showcaseContext, AppTourStep step) {
    final targetKey = step.targetKey;
    if (!step.useSpotlight || targetKey == null) {
      ShowCaseWidget.of(showcaseContext)?.dismiss();
      return;
    }
    ShowCaseWidget.of(showcaseContext)?.startShowCase([targetKey]);
  }

  void dismiss(BuildContext showcaseContext) {
    ShowCaseWidget.of(showcaseContext)?.dismiss();
  }
}
