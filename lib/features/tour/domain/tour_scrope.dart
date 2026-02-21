import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tour_controller.dart';

class TourScope extends ConsumerStatefulWidget {
  final Widget child;
  const TourScope({super.key, required this.child});

  @override
  ConsumerState<TourScope> createState() => _TourScopeState();
}

class _TourScopeState extends ConsumerState<TourScope> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tourControllerProvider.notifier).autoStartIfFirstTime();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
