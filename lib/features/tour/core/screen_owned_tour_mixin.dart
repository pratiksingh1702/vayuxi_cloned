import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tour_providers.dart';
import 'tour_package_adapter.dart';

mixin ScreenOwnedTourMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  static const TourPackageAdapter _screenOwnedTourAdapter =
      TourPackageAdapter();

  String? _screenOwnedTourId;
  BuildContext? _screenOwnedShowcaseContext;

  @protected
  void bindScreenOwnedTour({
    required String tourId,
    required BuildContext showcaseContext,
  }) {
    _screenOwnedTourId = tourId;
    _screenOwnedShowcaseContext = showcaseContext;
  }

  @protected
  void cancelScreenOwnedTour() {
    final tourId = _screenOwnedTourId;
    if (tourId == null) return;

    final controller = ref.read(appTourControllerProvider.notifier);
    final activeTour = controller.activeTour;
    if (activeTour?.id != tourId) return;

    final showcaseContext = _screenOwnedShowcaseContext;
    if (showcaseContext != null && showcaseContext.mounted) {
      _screenOwnedTourAdapter.dismiss(showcaseContext);
    }
    controller.cancelActiveTour(onlyTourId: tourId);
    _screenOwnedShowcaseContext = null;
  }

  @override
  void dispose() {
    cancelScreenOwnedTour();
    super.dispose();
  }
}
