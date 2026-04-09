import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_access.dart';
import '../domain/tour_controller.dart';
import '../registry/site_registry.dart';

class TourScope extends ConsumerStatefulWidget {
  final Widget child;
  const TourScope({super.key, required this.child});

  @override
  ConsumerState<TourScope> createState() => _TourScopeState();
}

class _TourScopeState extends ConsumerState<TourScope> {
  bool _tourInitialized = false;

  @override
  Widget build(BuildContext context) {
    // Watch appAccessProvider so we react whenever it changes
    final access = ref.watch(appAccessProvider);

    // Only attempt to start tour when:
    // 1. App is fully booted (not booting)
    // 2. User is logged in
    // 3. User has either a subscription OR has completed trial activation
    //    (i.e. they are fully inside the app, past all gates)
    final isInsideApp = !access.isBooting && access.loggedIn;

    if (isInsideApp && !_tourInitialized) {
      _tourInitialized = true;
      debugPrint(
          '🎬 TourScope initialized - Site tour will start on /site page');
      // ✅ REMOVED auto-start logic
      // Site tour only starts when user navigates to /site page
      // This prevents premature tour start on work_cat
    }

    // If user logs out, reset so tour can re-evaluate on next login
    if (!access.loggedIn) {
      _tourInitialized = false;
    }

    return widget.child;
  }
}
