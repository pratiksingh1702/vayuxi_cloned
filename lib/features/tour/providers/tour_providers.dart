import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_provider.dart';
import '../core/tour_analytics.dart';
import '../core/tour_engine.dart';
import '../core/tour_models.dart';
import '../core/tour_storage.dart';
import '../definitions/module_screen_tours.dart';

final appTourStorageProvider = Provider<AppTourStorage>((ref) {
  return AppTourStorage();
});

final appTourAnalyticsProvider = Provider<AppTourAnalytics>((ref) {
  return const AppTourAnalytics();
});

final appTourDefinitionsProvider = Provider<List<AppTourDefinition>>((ref) {
  return ModuleScreenTours.all;
});

final appTourRolePolicyProvider = Provider<Set<String>>((ref) {
  final role = ref.watch(authProvider).role;
  if (role == 'manpower') {
    return const {
      ModuleScreenTours.welcomeId,
      ModuleScreenTours.dailyId,
    };
  }
  return ModuleScreenTours.all.map((tour) => tour.id).toSet();
});

final appTourControllerProvider =
    StateNotifierProvider<AppTourController, AppTourState>((ref) {
  return AppTourController(
    definitions: ref.watch(appTourDefinitionsProvider),
    allowedTourIds: ref.watch(appTourRolePolicyProvider),
    storage: ref.watch(appTourStorageProvider),
    analytics: ref.watch(appTourAnalyticsProvider),
  );
});
