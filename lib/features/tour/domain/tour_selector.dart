import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/tour/domain/tour_step_model.dart';
import 'tour_controller.dart';

final currentTourStepProvider = Provider<TourStep?>((ref) {
  return ref.watch(tourControllerProvider.notifier).currentStep;
});

final currentRouteProvider = StateProvider<String>((ref) => "/");
