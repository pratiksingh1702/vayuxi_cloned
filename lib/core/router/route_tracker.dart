import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes.dart';

final currentRouteProvider = StateProvider<String?>((ref) => null);

class RouteTrailEntry {
  final String path;
  final String label;

  const RouteTrailEntry({required this.path, required this.label});
}

final routeTrailProvider =
    StateNotifierProvider<RouteTrailNotifier, List<RouteTrailEntry>>(
  (ref) => RouteTrailNotifier(),
);

class RouteTrailNotifier extends StateNotifier<List<RouteTrailEntry>> {
  RouteTrailNotifier() : super(const []);

  static const int _maxTrailLength = 20;

  void syncFromLocation(String location) {
    final path = normalizeRouteLocation(location);
    final label = routeBreadcrumbLabel(path);

    if (state.isNotEmpty && state.last.path == path) {
      state = [
        ...state.sublist(0, state.length - 1),
        RouteTrailEntry(path: path, label: label),
      ];
      return;
    }

    final existingIndex = state.indexWhere((entry) => entry.path == path);
    if (existingIndex >= 0) {
      state = state.sublist(0, existingIndex + 1);
      return;
    }

    final nextTrail = [
      ...state,
      RouteTrailEntry(path: path, label: label),
    ];

    state = nextTrail.length <= _maxTrailLength
        ? nextTrail
        : nextTrail.sublist(nextTrail.length - _maxTrailLength);
  }

  void clear() {
    state = const [];
  }
}

String normalizeRouteLocation(String location) {
  final uri = Uri.tryParse(location);
  if (uri == null) return location;

  final path = uri.path.isEmpty ? '/' : uri.path;
  return path == '/' && uri.queryParameters.isEmpty ? '/' : path;
}

bool isBreadcrumbVisibleLocation(String location) {
  final path = normalizeRouteLocation(location);

  const hiddenRoutes = {
    Routes.splash,
    Routes.login,
    Routes.manpowerLogin,
    Routes.register,
    Routes.trial,
    Routes.onboarding,
    Routes.planSelect,
    Routes.terms,
  };

  return !hiddenRoutes.contains(path);
}

String routeBreadcrumbLabel(String location) {
  final path = normalizeRouteLocation(location);

  switch (path) {
    case '/':
      return 'Home';
    case Routes.splash:
      return 'Splash';
    case Routes.login:
      return 'Login';
    case Routes.manpowerLogin:
      return 'Manpower Login';
    case Routes.register:
      return 'Register';
    case Routes.trial:
      return 'Trial';
    case Routes.onboarding:
      return 'Onboarding';
    case Routes.planSelect:
      return 'Plan Select';
    case Routes.workCategory:
      return 'Work Category';
    case Routes.selectModule:
      return 'Modules';
    case Routes.siteList:
      return 'Site List';
    case Routes.site:
      return 'Site';
    case Routes.analysis:
      return 'AI Analysis';
    case Routes.mocSelection:
      return 'MOC Selection';
    case Routes.manpower:
      return 'Manpower';
    case Routes.manpowerAddDetails:
      return 'Add Manpower';
    case Routes.editManpower:
      return 'Edit Manpower';
    case Routes.profile:
      return 'Profile';
    case Routes.theme:
      return 'Theme';
    case Routes.upcomingUpdate:
      return 'Upcoming Updates';
    case Routes.subscription:
      return 'Subscription';
    case Routes.language:
      return 'Language';
    case Routes.help:
      return 'Help';
    case Routes.salary:
      return 'Salary';
    case Routes.summary:
      return 'Summary';
    case Routes.dprInsuReview:
      return 'DPR Insulation Review';
    case Routes.terms:
      return 'Terms';
    case Routes.laggingMaterial:
      return 'Lagging Material';
    case Routes.cladding:
      return 'Cladding';
    case Routes.addTeam:
      return 'Add Team';
    case Routes.siteEntrySelect:
      return 'Site Entry';
    case Routes.siteImport:
      return 'Import Site';
    case Routes.dprReportDownload:
      return 'DPR Report Download';
    case Routes.inventoryReportDownload:
      return 'Inventory Report Download';
    case Routes.dprDescription:
      return 'DPR Description';
    case Routes.dprInsuDescription:
      return 'Insulation Description';
    case Routes.dprViewSelect:
      return 'DPR View';
    case Routes.addMoc:
      return 'Add MOC';
    case Routes.addFloor:
      return 'Add Floor';
    case Routes.salarySelectRange:
      return 'Salary Select Range';
    case Routes.inventoryList:
      return 'Inventory List';
    case Routes.editRate:
      return 'Edit Rate';
    case Routes.addRate:
      return 'Add Rate';
    case Routes.datePicker:
      return 'Date Range';
    case Routes.expenseForm:
      return 'Expense Form';
    case Routes.editInventory:
      return 'Edit Inventory';
    case Routes.editTeam:
      return 'Edit Team';
    case Routes.deviceOtp:
      return 'Device OTP';
  }

  if (path.startsWith('${Routes.siteList}/')) {
    return 'Site List';
  }
  if (path.startsWith('${Routes.dprWorkList}/')) {
    return 'DPR Work List';
  }
  if (path.startsWith('${Routes.moduleDetail}/')) {
    return 'Module Details';
  }
  if (path == '${Routes.salary}/individual') {
    return 'Salary Slip';
  }

  final segments = path.split('/').where((segment) => segment.isNotEmpty);
  if (segments.isEmpty) return 'Route';

  return segments
      .map(_humanizeSegment)
      .where((segment) => segment.isNotEmpty)
      .join(' / ');
}

String _humanizeSegment(String segment) {
  final replaced = segment.replaceAll(RegExp(r'[-_]+'), ' ').replaceAllMapped(
      RegExp(r'(?<=[a-z0-9])([A-Z])'), (match) => ' ${match[1]}');

  return replaced
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}
