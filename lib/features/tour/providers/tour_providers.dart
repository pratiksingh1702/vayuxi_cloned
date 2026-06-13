import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_provider.dart';
import '../core/tour_analytics.dart';
import '../core/tour_engine.dart';
import '../core/tour_models.dart';
import '../core/tour_storage.dart';
import '../definitions/attendance_module_tours.dart';
import '../definitions/manpower_team_module_tours.dart';
import '../definitions/module_screen_tours.dart';
import '../definitions/setup_module_tours.dart';
import '../definitions/site_rate_module_tours.dart';

final appTourStorageProvider = Provider<AppTourStorage>((ref) {
  return AppTourStorage();
});

final appTourAnalyticsProvider = Provider<AppTourAnalytics>((ref) {
  return const AppTourAnalytics();
});

final appTourDefinitionsProvider = Provider<List<AppTourDefinition>>((ref) {
  return [
    ...ModuleScreenTours.all,
    ...AttendanceModuleTours.all,
    ...SiteRateModuleTours.all,
    ...ManpowerTeamModuleTours.all,
    ...SetupModuleTours.all,
  ];
});

final appTourRolePolicyProvider = Provider<Set<String>>((ref) {
  final role = ref.watch(authProvider).role;
  if (role == 'manpower') {
    return const {
      ModuleScreenTours.welcomeId,
      ModuleScreenTours.dailyId,
      AttendanceModuleTours.attendanceId,
      SiteRateModuleTours.siteDetailsId,
      SiteRateModuleTours.rateId,
      ManpowerTeamModuleTours.manpowerId,
      ManpowerTeamModuleTours.teamId,
    };
  }
  return ref.watch(appTourDefinitionsProvider).map((tour) => tour.id).toSet();
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
