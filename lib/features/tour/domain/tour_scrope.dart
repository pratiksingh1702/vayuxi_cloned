import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_access.dart';
import '../domain/tour_controller.dart';

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
    final isInsideApp = !access.isBooting &&
        access.loggedIn ;

    if (isInsideApp && !_tourInitialized) {
      _tourInitialized = true;
      // Use microtask to avoid calling setState/notifier during build
      Future.microtask(() {
        if (mounted) {
          ref.read(tourControllerProvider.notifier).autoStartIfFirstTime();
        }
      });
    }

    // If user logs out, reset so tour can re-evaluate on next login
    if (!access.loggedIn) {
      _tourInitialized = false;
    }

    return widget.child;
  }
}