import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/router/site_aware.dart';
import 'package:untitled2/exit_wrapper.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/screens/ManFieldMappingScreen.dart';
import 'package:untitled2/features/modules/all_Modules/ai_analyze/model/ai_analyze_model.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/screens/step_insulation_screen.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteList.dart';
import 'package:untitled2/features/modules/all_Modules/summary/screens/summaru_screen.dart';

import '../../features/modules/all_Modules/structure_work/boq/screens/boq_item_list.dart';
import '../../features/modules/all_Modules/structure_work/dpr/screens/dpr_structure_list_screen.dart';
import '../../features/modules/all_Modules/structure_work/reports/structure_sheet_download_page.dart';
import '../../features/modules/all_Modules/structure_work/dpr_setup/screens/dpr_setup_list_screen.dart';
import '../../features/modules/all_Modules/structure_work/dpr_setup/screens/create_assembly_card_screen.dart';
import '../../features/modules/all_Modules/structure_work/dpr_setup/isar/assembly_card_isar.dart';
import '../../features/modules/all_Modules/structure_work/reports/structure_dpr_report_list_screen.dart';
import '../../features/modules/all_Modules/structure_work/dpr/models/dpr_structure_model.dart';
import '../../features/modules/all_Modules/structure_work/dpr/screens/dpr_structure_create_screen.dart';
import '../../features/modules/all_Modules/structure_work/history_upload/screens/satmax_history_upload_screen.dart';
import '../../features/pm/screens/pm_screen.dart';
import '../../features/tour/providers/tour_providers.dart';

import '../../features/auth/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/onboarding/screens/pla_Select_Screen.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/auth/screens/TrialScreen.dart';
import '../../features/automated_entry/presentation/screens/automated_entry_screen.dart';
import '../../features/auth/screens/login.dart';
import '../../features/auth/screens/manpower_login_Screen.dart';
import '../../features/auth/screens/sign_up.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/toc.dart';
import '../../features/modules/all_Modules/Manpower Details/model/manpower_model.dart';
import '../../features/modules/all_Modules/Manpower Details/screens/addManpower.dart';
import '../../features/modules/all_Modules/Manpower Details/screens/editManpower.dart';
import '../../features/modules/all_Modules/Manpower Details/screens/man_import.dart';
import '../../features/modules/all_Modules/Manpower Details/screens/manpowerList.dart';
import '../../features/modules/screen/module_detail.dart';

import '../../features/modules/all_Modules/dpr/models/dprModel.dart';
import '../../features/modules/all_Modules/dpr/dpr_insu/model/dpr_model_insu.dart';
import '../../features/modules/all_Modules/Manpower Details/screens/view_add_manpower.dart';
import '../../features/modules/all_Modules/ai_analyze/screen/audio_upload.dart';
import '../../features/modules/all_Modules/ai_analyze/screen/selection_page.dart';
import '../../features/modules/all_Modules/ai_analyze/screen/tts.dart';
import '../../features/modules/all_Modules/attendance/screen/attendanceScreen.dart';
import '../../features/modules/all_Modules/attendance/screen/dailyAttendanceScreen.dart';
import '../../features/modules/all_Modules/attendance/screen/generate_att.dart';
import '../../features/modules/all_Modules/boq/screens/boq_dasboard_Screen.dart';
import '../../features/modules/all_Modules/dpr/dpr-setup/screens/add/add_floor.dart';
import '../../features/modules/all_Modules/dpr/dpr-setup/screens/add/add_moc.dart';
import '../../features/modules/all_Modules/dpr/dpr-setup/screens/add/select_page.dart';
import '../../features/modules/all_Modules/dpr/dpr-setup/screens/view_add.dart';
import '../../features/modules/all_Modules/dpr/dpr-setup/screens/view/view_select_page.dart';
import '../../features/modules/all_Modules/dpr/dpr_insu/screens/cladding_selection.dart';
import '../../features/modules/all_Modules/dpr/dpr_insu/screens/dpr_insu.dart';
import '../../features/modules/all_Modules/dpr/dpr_insu/screens/lagging_Selection.dart';
import '../../features/modules/all_Modules/dpr/dpr_insu/screens/testing.dart';
import '../../features/modules/all_Modules/dpr/dpr_report/screens/download_sheets.dart';
import '../../features/modules/all_Modules/dpr/screens/dprTeamDetails.dart';
import '../../features/modules/all_Modules/dpr/screens/dprTeamPage.dart';
import '../../features/modules/all_Modules/dpr/screens/dpr_flow_gate.dart';
import '../../features/modules/all_Modules/dpr/screens/add_description.dart';
import '../../features/modules/all_Modules/dpr/screens/widgets/mechanichal_stepper.dart';
import '../../features/modules/all_Modules/expense/screens/add-exp/add_expense.dart';
import '../../features/modules/all_Modules/expense/screens/expense_screen.dart';
import '../../features/modules/all_Modules/expense/screens/genericFormScreen.dart';
import '../../features/modules/all_Modules/expense/screens/view_sheet.dart';
import '../../features/modules/all_Modules/inventory/models/inventory_model.dart';
import '../../features/modules/all_Modules/inventory/screens/add_bulk_inven.dart';
import '../../features/modules/all_Modules/inventory/screens/add_inven.dart';
import '../../features/modules/all_Modules/inventory/screens/edit_inventory.dart';
import '../../features/modules/all_Modules/inventory/screens/inv_usage/checkout_managment_page.dart';
import '../../features/modules/all_Modules/inventory/screens/inv_usage/inv_usage.dart';
import '../../features/modules/all_Modules/inventory/screens/inv_usage/inventory_cat.dart';
import '../../features/modules/all_Modules/inventory/screens/inventory_list.dart';
import '../../features/modules/all_Modules/inventory/screens/report/daily_usage.dart';
import '../../features/modules/all_Modules/more/help.dart';
import '../../features/modules/all_Modules/more/language.dart';
import '../../features/modules/all_Modules/more/more.dart';
import '../../features/modules/all_Modules/more/rag.dart';
import '../../features/modules/all_Modules/more/subscription.dart';
import '../../features/modules/all_Modules/more/theme/screen/theme_screen.dart';
import '../../features/modules/all_Modules/more/themes.dart';
import '../../features/modules/all_Modules/more/upcoming.dart';
import '../../features/modules/all_Modules/rate/screens/rate.dart';
import '../../features/modules/all_Modules/rate/screens/addRate.dart';
import '../../features/modules/all_Modules/rate/screens/editRate.dart';
import '../../features/modules/all_Modules/rate/screens/view_add_rate.dart';
import '../../features/modules/all_Modules/salary/screens/individual.dart';
import '../../features/modules/all_Modules/salary/screens/salarycat.dart';
import '../../features/modules/all_Modules/salary/screens/download_all.dart';
import '../../features/modules/all_Modules/salary/screens/site.dart';
import '../../features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import '../../features/inventory/screens/inventory_management_screen.dart';
import '../../features/modules/all_Modules/site_Details/screens/project_list_screen.dart';
import '../../features/modules/all_Modules/site_Details/screens/siteDetailScreen.dart';
import '../../features/modules/all_Modules/site_Details/screens/view_add_site.dart';
import '../../features/modules/all_Modules/site_Details/screens/site_entry_select_page.dart';
import '../../features/modules/all_Modules/site_Details/screens/site_import.dart';
import '../../features/modules/all_Modules/team/screens/addTeam.dart';
import '../../features/modules/all_Modules/team/screens/editTeam.dart';
import '../../features/modules/all_Modules/team/screens/teamsList.dart';
import '../../features/modules/all_Modules/team/screens/view_add.dart';
import '../../features/modules/screen/device_id.dart';
import '../../features/peb_work/dpr/screens/peb_dpr_fabrication_screen.dart';
import '../../features/peb_work/dpr/screens/peb_dpr_ga_screen.dart';
import '../../features/peb_work/dpr/screens/peb_dpr_home_screen.dart';
import '../../features/peb_work/dpr/screens/peb_dpr_procurement_screen.dart';
import '../../features/pricing/Screens/subsciption_screen.dart';
import '../../features/pricing/providers/razorpay_provider.dart';
import '../../features/profile_page/screens/profilePage.dart';
import '../../features/noti_system/updates/presentation/navigation/updates_routes.dart';
import '../../features/quotation/screens/quotation_list_screen.dart';
import '../../features/quotation/screens/quotation_create_screen.dart';
import '../../features/procurement/screens/procurement_list_screen.dart';
import '../../features/peb_work/screens/peb_dpr_setup_screen.dart';
import '../../features/peb_work/screens/dpr_entry_screen.dart';
import '../../features/peb_execution/models/peb_execution_models.dart';
import '../../features/peb_execution/screens/peb_dpr_entry_screen.dart';
import '../../features/peb_execution/screens/peb_setup_screen.dart';
import '../../features/peb_execution/screens/peb_work_assignment_screen.dart';
import '../../features/fabrication/screens/fabrication_dpr_screen.dart';
import '../../features/modules/all_Modules/site_Details/screens/dispatch_handover_screens.dart';
import '../../features/modules/screen/module_screen_v2.dart';
import '../../features/crm/screens/crm_lead_list_screen.dart';
import '../../features/crm/screens/crm_lead_detail_screen.dart';
import '../../features/crm/models/crm_model.dart';
import '../../typeProvider/type_provider.dart';
import '../../work_cat.dart';
import '../../core/router/routes.dart';
import '../utlis/widgets/date_picker_Screen.dart';
import 'app_access.dart';
import 'go_router_refresh.dart';
import 'not_found_screen.dart';
import 'package:bot_toast/bot_toast.dart';
import 'placeholders.dart';
import '../screens/network_settings_screen.dart';
import '../screens/settings_screen.dart';
import 'route_tracker.dart';

import '../../features/modules/screen/workflow/screens/workflow_gate_screen.dart';
import '../../features/modules/screen/workflow/registry/workflow_registry.dart';

// ─────────────────────────────────────────────────────────────
//  Tiny helper – keeps every log consistent and easy to grep
// ─────────────────────────────────────────────────────────────
void _logRoute(String label, {String? path, Map<String, dynamic>? extra}) {
  final buf = StringBuffer();
  buf.write('🧭 [ROUTER] $label');
  if (path != null) buf.write(' | path: $path');
  if (extra != null && extra.isNotEmpty) {
    buf.write(' | extra: $extra');
  }
  debugPrint(buf.toString());
}

class _RouteObserver extends NavigatorObserver {
  final Ref ref;
  _RouteObserver(this.ref);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateRoute(newRoute);
  }

  void _updateRoute(Route<dynamic>? _) {
    // GoRouter often doesn't put the path in settings.name, so we might need a better way.
    // However, GoRouter state is usually enough.
    Future.microtask(() {
      ref.read(appTourControllerProvider.notifier).cancelActiveTour();
    });
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => const NotFoundScreen(),
    refreshListenable: ref.watch(routerRefreshProvider),
    redirect: (context, state) async {
      final access = ref.read(appAccessProvider);
      final loc = state.matchedLocation;
      final concretePath =
          state.uri.path.isEmpty ? '/' : normalizeRouteLocation(state.uri.path);

      // ✅ Update current route for job auto-navigation
      // Use microtask to avoid "Tried to modify a provider while the widget tree was building" error
      Future.microtask(() {
        ref.read(currentRouteProvider.notifier).state = concretePath;
        ref.read(routeTrailProvider.notifier).syncFromLocation(concretePath);
      });

      debugPrint(
        '🔀 [ROUTER REDIRECT] '
        'booting=${access.isBooting} '
        'loggedIn=${access.loggedIn} '
        'matchedLocation=$loc '
        'fullPath=${state.uri}',
      );

      // ── 0. Still booting ────────────────────────────────────────────────
      if (access.isBooting) {
        debugPrint(
            '🔀 [ROUTER REDIRECT] → ${Routes.splash}  (reason: booting)');
        return Routes.splash;
      }

      // ── 1. Not logged in → public routes only ───────────────────────────
      const Set<String> publicRoutes = {
        Routes.login,
        '/manpower-login',
        '/register',
        '/trial',
        '/onboarding',
        '/plan-select',
        '/terms',
      };
      final isPublic = publicRoutes.contains(loc);

      if (!access.loggedIn) {
        if (!isPublic) {
          debugPrint(
              '🔀 [ROUTER REDIRECT] → ${Routes.login}  (reason: not logged in, tried: $loc)');
          return Routes.login;
        }
        debugPrint(
            '🔀 [ROUTER REDIRECT] → null  (reason: public route, not logged in)');
        return null;
      }

      // ── 2. Logged in → redirect away from gate pages ────────────────────
      const Set<String> gatePages = {
        Routes.splash,
        Routes.login,
        '/manpower-login',
        '/plan-select',
      };

      if (gatePages.contains(loc)) {
        final savedType = await TypeNotifier.readSavedType();
        if (savedType != null) {
          await ref.read(typeProvider.notifier).setType(savedType);
          debugPrint(
              '🔀 [ROUTER REDIRECT] → ${Routes.selectModule}  (reason: restored saved work type: $savedType)');
          return Routes.selectModule;
        }
        debugPrint(
            '🔀 [ROUTER REDIRECT] → ${Routes.workCategory}  (reason: logged in, was at gate page: $loc)');
        return Routes.workCategory;
      }

      if (loc == Routes.workCategory) {
        final savedType = await TypeNotifier.readSavedType();
        if (savedType != null) {
          await ref.read(typeProvider.notifier).setType(savedType);
          debugPrint(
              '🔀 [ROUTER REDIRECT] → ${Routes.selectModule}  (reason: work type already selected: $savedType)');
          return Routes.selectModule;
        }
      }

      // ── 3. Logged in + inside app → free navigation ─────────────────────
      debugPrint(
          '🔀 [ROUTER REDIRECT] → null  (reason: logged in, free navigation to $loc)');
      return null;
    },
    observers: [
      BotToastNavigatorObserver(),
      _RouteObserver(ref),
    ],
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) {
          _logRoute('SplashScreen', path: state.uri.toString());
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: Routes.planSelect,
        builder: (context, state) {
          _logRoute('PlanSelectScreen', path: state.uri.toString());
          return const PlanSelectScreen();
        },
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) {
          _logRoute('OnboardingScreen', path: state.uri.toString());
          return const OnboardingScreen();
        },
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) {
          _logRoute('LoginScreen', path: state.uri.toString());
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: Routes.manpowerLogin,
        name: 'manpower-login',
        builder: (context, state) {
          _logRoute('ManpowerLoginScreen', path: state.uri.toString());
          return const ManpowerLoginScreen();
        },
      ),
      GoRoute(
        path: Routes.workCategory,
        builder: (context, state) {
          _logRoute('WorkCategoryScreen', path: state.uri.toString());
          return const ExitWrapper(
            // ✅ add this
            child: WorkCategoryScreen(),
          );
        },
      ),
      GoRoute(
        path: Routes.selectModule,
        builder: (context, state) {
          final indexStr = state.uri.queryParameters['index'];
          final initialIndex = int.tryParse(indexStr ?? '0') ?? 0;
          _logRoute('ModuleScreen',
              path: state.uri.toString(),
              extra: {'initialIndex': initialIndex});
          return ModuleScreenV2(initialIndex: initialIndex);
        },
      ),
      GoRoute(
        path: Routes.automatedEntry,
        builder: (context, state) {
          _logRoute('AutomatedEntryScreen', path: state.uri.toString());
          return const AutomatedEntryScreen();
        },
      ),

      // ── Site-list dynamic route ──────────────────────────────────────────
      GoRoute(
        path: '${Routes.siteList}/:module',
        builder: (context, state) {
          final module = state.pathParameters['module'] ?? 'site';
          final bool show = module == 'site';
          _logRoute('SiteListScreen → module=$module',
              path: state.uri.toString());
          final container = ProviderScope.containerOf(context, listen: false);

          // ── Build the pageBuilder switch once ──────────────────────────────
          Widget buildDestination(SiteModel site) {
            debugPrint(
                '📍 [ROUTER] pageBuilder called | module=$module | siteId=${site.id}');
            final type = container.read(typeProvider);

            Widget screen;
            switch (module) {
              case 'rate':
                screen = RateScreen();
                break;
              case 'team':
                screen = TeamListPage();
                break;
              case 'dpr':
                if (type == 'structure_work') {
                  screen = DprFlowGate(site: site);
                } else if (type == 'peb_work') {
                  screen = const PebDprHomeScreen();
                } else if (site.counts.teams == 0) {
                  screen = type == 'mechanical_work'
                      ? MechanichalStepperScreen(
                          siteId: site.id,
                          teamId: '',
                          teamName: null,
                        )
                      : type == 'insulation_work'
                          ? StepInsulationScreen(
                              siteId: site.id,
                              teamId: '',
                              name: site.siteName,
                              teamName: null,
                            )
                          : DprFlowGate(site: site);
                } else {
                  screen = DprFlowGate(site: site);
                }
                break;
              case 'boq':
                screen = BoqDashboardScreen(
                    siteId: site.id, siteName: site.siteName);
                break;
              case 'structure-boq':
                screen = BoqItemListScreen(
                  siteId: site.id,
                  siteName: site.siteName,
                );
                break;
              case 'structure-dpr-setup':
                screen = DPRSetupListScreen(site: site);
                break;
              case 'structure-history-upload':
                screen = SatmaxHistoryUploadScreen(
                  siteId: site.id,
                  siteName: site.siteName,
                  mode: SatmaxHistoryScreenMode.view,
                );
                break;
              case 'structure-pm-entry':
                screen = PmScreen(
                  siteId: site.id,
                  siteName: site.siteName,
                  workType: type ?? '',
                  section: PmSection.entry,
                );
                break;
              case 'structure-pm-setup':
                screen = PmScreen(
                  siteId: site.id,
                  siteName: site.siteName,
                  workType: type ?? '',
                  section: PmSection.setup,
                );
                break;
              case 'structure-pm-report':
                screen = PmScreen(
                  siteId: site.id,
                  siteName: site.siteName,
                  workType: type ?? '',
                  section: PmSection.reports,
                );
                break;
              case 'attendance':
                screen = AttendanceScreen();
                break;
              case 'siteSalary':
                screen = SiteSalaryScreen(siteModel: site);
                break;
              case 'expense':
                screen = ExpenseEntrySelectCardGrid();
                break;
              case 'addMoc':
                screen = DprSelectCardGrid();
                break;
              case 'add-exp':
                screen = AddExpenseScreen();
                break;
              case 'inv-entry':
                screen = InventoryCategorySelectionScreen();
                break;
              case 'inv-setup':
                screen = const InventoryListScreen();
                break;
              case 'att-sheet':
                screen = GenerateAttendanceSheetScreen();
                break;
              case 'manpower':
                screen = ManpowerListScreen();
                break;

              case 'man-import':
                screen = ManFieldMappingScreen();
                break;
              case 'dprReport':
                screen = DateRangeSelectionScreen(
                  onDatesSelected: (start, end) => context.push(
                    Routes.dprReportDownload,
                    extra: {'startDate': start, 'endDate': end},
                  ),
                );
                break;
              case 'inv-Report':
                screen = DateRangeSelectionScreen(
                  onDatesSelected: (start, end) => context.push(
                    Routes.inventoryReportDownload,
                    extra: {'startDate': start, 'endDate': end},
                  ),
                );
                break;

              // NEW PEB CRM & ADVANCED MODULES
              case 'dispatch':
                screen = const DispatchListScreen();
                break;
              case 'handover':
                screen = const HandoverChecklistScreen();
                break;
              case 'procurement':
                screen = ProcurementListScreen(siteId: site.id);
                break;
              case 'crm-setup':
                screen = const CrmLeadListScreen();
                break;
              case 'civil-dpr':
                screen = DprEntryScreen(siteId: site.id, title: 'Civil DPR');
                break;
              case 'erection-dpr':
                screen = PebDprEntryScreen(
                  siteId: site.id,
                  siteName: site.siteName,
                  executionType: PebExecutionType.erection,
                );
                break;
              case 'roofing-dpr':
                screen = DprEntryScreen(siteId: site.id, title: 'Roofing DPR');
                break;
              case 'fabrication-dpr':
                screen = PebDprEntryScreen(
                  siteId: site.id,
                  siteName: site.siteName,
                  executionType: PebExecutionType.fabrication,
                );
                break;
              case 'fabrication-setup':
                screen = PebSetupScreen(
                  siteId: site.id,
                  siteName: site.siteName,
                  executionType: PebExecutionType.fabrication,
                );
                break;
              case 'civil-setup':
                screen = PebDprSetupScreen(siteId: site.id, workType: 'civil');
                break;
              case 'erection-setup':
                screen = PebSetupScreen(
                  siteId: site.id,
                  siteName: site.siteName,
                  executionType: PebExecutionType.erection,
                );
                break;
              case 'roofing-setup':
                screen =
                    PebDprSetupScreen(siteId: site.id, workType: 'roofing');
                break;
              case 'mechanical-setup':
                screen =
                    PebDprSetupScreen(siteId: site.id, workType: 'mechanical');
                break;
              case 'insulation-setup':
                screen =
                    PebDprSetupScreen(siteId: site.id, workType: 'insulation');
                break;
              case 'structure-setup':
                screen =
                    PebDprSetupScreen(siteId: site.id, workType: 'structure');
                break;
              case 'peb-setup':
                screen = PebDprSetupScreen(siteId: site.id, workType: 'peb');
                break;
              case 'boq-upload':
                if (type == 'mechanical_work') {
                  screen = BoqDashboardScreen(
                    siteId: site.id,
                    siteName: site.siteName,
                    directViewMode: true,
                  );
                } else if (type == 'insulation_work') {
                  screen = BoqDashboardScreen(
                    siteId: site.id,
                    siteName: site.siteName,
                  );
                } else {
                  screen = BoqItemListScreen(
                    siteId: site.id,
                    siteName: site.siteName,
                  );
                }
                break;
              case 'work-assignment':
                screen = PebWorkAssignmentScreen(
                  siteId: site.id,
                  siteName: site.siteName,
                  executionType: type == 'fabrication_work'
                      ? PebExecutionType.fabrication
                      : PebExecutionType.erection,
                  openListDirectly: true,
                );
                break;
              case 'cold-call':
                screen = const PlaceholderScreen(title: 'Cold Call');
                break;
              case 'follow-up':
                screen = const PlaceholderScreen(title: 'Follow Up');
                break;
              case 'inventory-list':
                screen = InventoryManagementScreen(siteId: site.id);
                break;
              case 'edit-inventory':
                screen = InventoryManagementScreen(siteId: site.id);
                break;
              case 'dispatch-tracking':
                screen = const PlaceholderScreen(title: 'Dispatch Tracking');
                break;
              case 'fab-report':
                screen = const ReportPlaceholder(reportName: 'Fabrication');
                break;
              case 'dispatch-report':
                screen = const ReportPlaceholder(reportName: 'Dispatch');
                break;
              case 'handover-report':
                screen = const ReportPlaceholder(reportName: 'Handover');
                break;
              case 'crm-report':
                screen = const ReportPlaceholder(reportName: 'CRM');
                break;

              default:
                screen = SiteDetailScreen(site: site);
            }

            // ✅ Wrap so selectedSiteIdProvider syncs safely after build
            return SiteAwareWrapper(site: site, child: screen);
          }

          // ── Read the container to check if a site is already selected ──────
          final preSelectedSite = container.read(siteDropdownValueProvider);
          const modulesRequiringFreshSitePick = {'manpower'};

          // ── If site already chosen AND this is not the site-management screen,
          //    skip SiteListScreen entirely and go straight to destination ──────
          if (preSelectedSite != null &&
              !show &&
              !modulesRequiringFreshSitePick.contains(module)) {
            debugPrint(
                '⚡ [ROUTER] Skipping SiteListScreen — using pre-selected site: ${preSelectedSite.siteName}');
            // ✅ No provider writes here — SiteAwareWrapper handles it after build
            return buildDestination(preSelectedSite);
          }

          // ── No pre-selection → show the site grid as normal ─────────────────
          return SiteListScreen(
            show: show,
            module: module,
            pageBuilder: buildDestination,
          );
        },
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        builder: (context, state) {
          _logRoute('RegisterScreen', path: state.uri.toString());
          return const RegisterScreen();
        },
      ),
      GoRoute(
        path: Routes.trial,
        builder: (context, state) {
          _logRoute('TrialScreen', path: state.uri.toString());
          return const TrialScreen();
        },
      ),
      GoRoute(
        path: Routes.site,
        name: 'site',
        builder: (context, state) {
          _logRoute('SiteListScreen → module=site', path: state.uri.toString());
          return SiteListScreen(
            show: true,
            module: 'site',
            pageBuilder: (site) => SiteDetailScreen(site: site),
          );
        },
      ),
      GoRoute(
        path: Routes.analysis,
        name: 'analysis',
        builder: (context, state) {
          _logRoute('AudioUploadAnalysisScreen', path: state.uri.toString());
          return const AudioUploadAnalysisScreen();
        },
      ),
      GoRoute(
        path: Routes.mocSelection,
        name: 'mocSelection',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          _logRoute('MechanichalStepperScreen',
              path: state.uri.toString(),
              extra: {
                'siteId': data['siteId'],
                'teamId': data['teamId'],
                'teamName': data['teamName'],
              });
          return MechanichalStepperScreen(
            siteId: data['siteId'],
            teamId: data['teamId'],
            teamName: data['teamName'],
          );
        },
      ),
      GoRoute(
        path: '/mechanichal-stepper',
        name: 'mechanichalStepper',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          _logRoute('MechanichalStepperScreen',
              path: state.uri.toString(),
              extra: {
                'siteId': data['siteId'],
                'teamId': data['teamId'],
                'teamName': data['teamName'],
              });
          return MechanichalStepperScreen(
            siteId: data['siteId'],
            teamId: data['teamId'],
            teamName: data['teamName'],
          );
        },
      ),
      GoRoute(
        path: Routes.manpower,
        builder: (context, state) {
          _logRoute('SiteListScreen → module=manpower',
              path: state.uri.toString());

          Widget buildDestination(SiteModel site) {
            _logRoute('ManpowerListScreen',
                path: state.uri.toString(), extra: {'siteId': site.id});
            return SiteAwareWrapper(
              site: site,
              child: const ManpowerListScreen(),
            );
          }

          return SiteListScreen(
            module: 'manpower',
            pageBuilder: buildDestination,
          );
        },
      ),
      GoRoute(
        path: Routes.manpowerList,
        builder: (context, state) {
          _logRoute('ManpowerListScreen', path: state.uri.toString());
          return const ManpowerListScreen();
        },
      ),
      GoRoute(
        path: Routes.manpowerAddDetails,
        builder: (context, state) {
          _logRoute('NewManpowerScreen', path: state.uri.toString());
          return const NewManpowerScreen();
        },
      ),
      GoRoute(
        path: Routes.editManpower,
        builder: (context, state) {
          final manpower = state.extra as ManpowerModel;
          _logRoute('EditManpowerScreen',
              path: state.uri.toString(), extra: {'manpowerId': manpower.id});
          return EditManpowerScreen(manpower: manpower);
        },
      ),
      GoRoute(
        path: '${Routes.dprWorkList}/:siteId/:name',
        builder: (context, state) {
          final siteId = state.pathParameters['siteId']!;
          final name = state.pathParameters['name']!;
          final extra = state.extra as Map<String, dynamic>?;
          _logRoute('DprWorkScreen', path: state.uri.toString(), extra: {
            'siteId': siteId,
            'name': name,
            'startDate': extra?['startDate'],
            'endDate': extra?['endDate'],
          });
          return DprWorkScreen(
            siteId: siteId,
            name: name,
            selectedStartDate: extra?['startDate'],
            selectedEndDate: extra?['endDate'],
          );
        },
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) {
          _logRoute('ProfileScreen', path: state.uri.toString());
          return ProfileScreen();
        },
      ),
      GoRoute(
        path: Routes.theme,
        builder: (context, state) {
          _logRoute('ThemeScreen', path: state.uri.toString());
          return ThemeScreen();
        },
      ),
      GoRoute(
        path: Routes.upcomingUpdate,
        builder: (context, state) {
          _logRoute('Updates (upcomingUpdate)', path: state.uri.toString());
          return Updates();
        },
      ),
      GoRoute(
        path: Routes.subscription,
        builder: (context, state) {
          _logRoute('SubscriptionScreen', path: state.uri.toString());
          return SubscriptionScreen();
        },
      ),
      GoRoute(
        path: Routes.language,
        builder: (context, state) {
          _logRoute('LanguageSelectionScreen', path: state.uri.toString());
          return LanguageSelectionScreen();
        },
      ),
      GoRoute(
        path: Routes.help,
        builder: (context, state) {
          _logRoute('HelpCenterScreen', path: state.uri.toString());
          return HelpCenterScreen();
        },
      ),
      GoRoute(
        path: Routes.networkSettings,
        builder: (context, state) {
          _logRoute('NetworkSettingsScreen', path: state.uri.toString());
          return const NetworkSettingsScreen();
        },
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) {
          _logRoute('SettingsScreen', path: state.uri.toString());
          return const SettingsScreen();
        },
      ),
      GoRoute(
        path: Routes.workflowGate,
        name: 'workflow-gate',
        builder: (context, state) {
          final workflowId = (state.extra
                  as Map<String, dynamic>?)?['workflowId'] as String? ??
              WorkflowRegistry.dailyEntryId;
          _logRoute('WorkflowGateScreen',
              path: state.uri.toString(), extra: {'workflowId': workflowId});
          return WorkflowGateScreen(workflowId: workflowId);
        },
      ),
      GoRoute(
        path: Routes.salary,
        builder: (context, state) {
          _logRoute('CategoryScreen (salary)', path: state.uri.toString());
          return const CategoryScreen();
        },
        routes: [
          GoRoute(
            path: 'individual',
            builder: (context, state) {
              _logRoute('SalarySlipScreen (salary/individual)',
                  path: state.uri.toString());
              return const SalarySlipScreen();
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.summary,
        builder: (context, state) {
          _logRoute('SummaryScreen', path: state.uri.toString());
          return SummaryScreen();
        },
      ),
      GoRoute(
        path: '${Routes.moduleDetail}/:name',
        builder: (context, state) {
          final moduleName = state.pathParameters['name']!;
          _logRoute('ModuleDetailScreen',
              path: state.uri.toString(), extra: {'moduleName': moduleName});
          return ModuleDetailScreen(moduleName: moduleName);
        },
      ),
      GoRoute(
        path: Routes.dprInsuReview,
        name: 'dpr-screen-insu',
        builder: (context, state) {
          _logRoute('AddInsulationDescriptionScreen (dprInsuReview)',
              path: state.uri.toString());
          return AddInsulationDescriptionScreen();
        },
      ),
      GoRoute(
        path: Routes.terms,
        name: 'terms',
        builder: (context, state) {
          _logRoute('TermsAndConditionsScreen', path: state.uri.toString());
          return const TermsAndConditionsScreen();
        },
      ),
      GoRoute(
        path: Routes.laggingMaterial,
        name: 'lagging-material',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          _logRoute('LaggingMaterialScreen',
              path: state.uri.toString(),
              extra: {
                'siteId': data['siteId'],
                'teamId': data['teamId'],
                'siteName': data['siteName'],
                'teamName': data['teamName'],
                'layerIndex': data['layerIndex'],
              });
          return LaggingMaterialScreen(
            siteId: data['siteId'],
            teamId: data['teamId'],
            siteName: data['siteName'],
            teamName: data['teamName'],
            layerIndex: data['layerIndex'],
          );
        },
      ),
      GoRoute(
        path: Routes.cladding,
        name: 'cladding',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          _logRoute('CladdingScreen', path: state.uri.toString(), extra: {
            'siteId': data['siteId'],
            'teamId': data['teamId'],
            'siteName': data['siteName'],
            'teamName': data['teamName'],
          });
          return CladdingScreen(
            siteId: data['siteId'],
            teamId: data['teamId'],
            siteName: data['siteName'],
            teamName: data['teamName'],
          );
        },
      ),
      GoRoute(
        path: Routes.addTeam,
        builder: (context, state) {
          _logRoute('AddTeamScreen', path: state.uri.toString());
          return const AddTeamScreen();
        },
      ),
      GoRoute(
        path: Routes.siteEntrySelect,
        builder: (context, state) {
          _logRoute('SiteEntrySelectCardGrid', path: state.uri.toString());
          return const SiteEntrySelectCardGrid();
        },
      ),
      GoRoute(
        path: Routes.siteImport,
        builder: (context, state) {
          _logRoute('SiteImportCsvScreen', path: state.uri.toString());
          return const SiteImportCsvScreen();
        },
      ),
      GoRoute(
        path: Routes.dprReportDownload,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          _logRoute('SheetDownloadPage (dprReportDownload)',
              path: state.uri.toString(),
              extra: {
                'startDate': extra['startDate'],
                'endDate': extra['endDate'],
              });
          return SheetDownloadPage(
            selectedStartDate: extra['startDate'],
            selectedEndDate: extra['endDate'],
          );
        },
      ),
      GoRoute(
        path: '/structure-dpr/:siteId',
        builder: (context, state) {
          final siteId = state.pathParameters['siteId']!;
          final siteName =
              (state.extra as Map<String, dynamic>?)?['siteName'] ?? '';
          _logRoute('DprStructureListScreen',
              path: state.uri.toString(), extra: {'siteId': siteId});
          return DprStructureListScreen(siteId: siteId, siteName: siteName);
        },
      ),
      GoRoute(
        path: '${Routes.structureDprReportList}/:siteId',
        builder: (context, state) {
          final siteId = state.pathParameters['siteId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return StructureDprReportListScreen(
            siteId: siteId,
            startDate: extra?['startDate'] as DateTime?,
            endDate: extra?['endDate'] as DateTime?,
            type: extra?['type'] as String?,
          );
        },
      ),
      GoRoute(
        path: '${Routes.structureDprCreate}/:siteId',
        builder: (context, state) {
          final siteId = state.pathParameters['siteId']!;
          final data = state.extra as Map<String, dynamic>?;
          final siteName = data?['siteName'] ?? '';
          final initialDpr = data?['initialDpr'] as DPRStructure?;
          return DprStructureCreateScreen(
            siteId: siteId,
            siteName: siteName,
            initialDpr: initialDpr,
          );
        },
      ),
      GoRoute(
        path: Routes.createAssemblyCard,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          final site = data['site'] as SiteModel;
          final card = data['card'] as AssemblyCardIsar?;
          return CreateAssemblyCardScreen(site: site, card: card);
        },
      ),

      GoRoute(
        path: Routes.inventoryReportDownload,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          _logRoute('DailyUsagePage (inventoryReportDownload)',
              path: state.uri.toString(),
              extra: {
                'startDate': extra['startDate'],
                'endDate': extra['endDate'],
              });
          return DailyUsagePage(
            selectedStartDate: extra['startDate'],
            selectedEndDate: extra['endDate'],
          );
        },
      ),
      GoRoute(
        path: Routes.dprDescription,
        builder: (context, state) {
          final extra = state.extra;
          DprModel? work;
          var isDraftWork = false;

          if (extra is DprModel) {
            work = extra;
          } else if (extra is Map<String, dynamic>) {
            isDraftWork = extra.containsKey('draftWork');
            final rawWork = extra['draftWork'] ?? extra['work'];
            if (rawWork is DprModel) {
              work = rawWork;
            } else if (rawWork is Map<String, dynamic>) {
              work = DprModel.fromJson(rawWork);
            }
          }

          _logRoute('AddDescriptionScreen (dprDescription)',
              path: state.uri.toString(), extra: {'workId': work?.id});
          return AddDescriptionScreen(work: work, fromDraft: isDraftWork);
        },
      ),
      GoRoute(
        path: Routes.dprInsuDescription,
        builder: (context, state) {
          InsulationDprModel? work;
          final extra = state.extra;
          var isDraftWork = false;

          if (extra is InsulationDprModel) {
            work = extra;
          } else if (extra is Map<String, dynamic>) {
            isDraftWork = extra.containsKey('draftWork');
            final rawWork = extra['draftWork'] ?? extra['work'];
            if (rawWork is InsulationDprModel) {
              work = rawWork;
            } else if (rawWork is Map<String, dynamic>) {
              work = InsulationDprModel.fromJson(rawWork);
            }
          }

          _logRoute('AddInsulationDescriptionScreen (dprInsuDescription)',
              path: state.uri.toString(), extra: {'workId': work?.id});
          return AddInsulationDescriptionScreen(
            work: work,
            fromDraft: isDraftWork,
          );
        },
      ),
      GoRoute(
        path: Routes.pebDpr,
        builder: (context, state) {
          _logRoute('PebDprHomeScreen', path: state.uri.toString());
          return const PebDprHomeScreen();
        },
      ),
      GoRoute(
        path: Routes.pebDprGa,
        builder: (context, state) {
          _logRoute('PebDprGaScreen', path: state.uri.toString());
          return const PebDprGaScreen();
        },
      ),
      GoRoute(
        path: Routes.pebDprFabrication,
        builder: (context, state) {
          _logRoute('PebDprFabricationScreen', path: state.uri.toString());
          return const PebDprFabricationScreen();
        },
      ),
      GoRoute(
        path: Routes.pebDprProcurement,
        builder: (context, state) {
          _logRoute('PebDprProcurementScreen', path: state.uri.toString());
          return const PebDprProcurementScreen();
        },
      ),
      GoRoute(
        path: Routes.dprViewSelect,
        builder: (context, state) {
          _logRoute('ViewSelectCardGrid (dprViewSelect)',
              path: state.uri.toString());
          return const ViewSelectCardGrid();
        },
      ),
      GoRoute(
        path: Routes.addMoc,
        builder: (context, state) {
          _logRoute('AddMOCPage', path: state.uri.toString());
          return const AddMOCPage();
        },
      ),
      GoRoute(
        path: Routes.addFloor,
        builder: (context, state) {
          _logRoute('AddFloorPage', path: state.uri.toString());
          return const AddFloorPage();
        },
      ),
      GoRoute(
        path: Routes.salarySelectRange,
        builder: (context, state) {
          _logRoute('SelectRangeScreen (salarySelectRange)',
              path: state.uri.toString());
          return const SelectRangeScreen();
        },
      ),
      GoRoute(
        path: Routes.inventoryList,
        builder: (context, state) {
          _logRoute('InventoryListScreen', path: state.uri.toString());
          return const InventoryListScreen();
        },
      ),
      GoRoute(
        path: Routes.editRate,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          _logRoute('EditRateScreen',
              path: state.uri.toString(),
              extra: {'site': extra['site'], 'rate': extra['rate']});
          return EditRateScreen(
            site: extra['site'],
            rate: extra['rate'],
          );
        },
      ),
      GoRoute(
        path: Routes.addRate,
        builder: (context, state) {
          final extra = state.extra;
          final siteId = extra is String
              ? extra
              : extra is Map<String, dynamic>
                  ? extra['siteId'] as String?
                  : null;
          final type =
              extra is Map<String, dynamic> ? extra['type'] as String? : null;
          _logRoute('AddRateScreen',
              path: state.uri.toString(),
              extra: {'siteId': siteId, 'type': type});
          return AddRateScreen(initialSiteId: siteId, initialType: type);
        },
      ),
      GoRoute(
        path: Routes.datePicker,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          _logRoute('DateRangeSelectionScreen (datePicker)',
              path: state.uri.toString());
          return DateRangeSelectionScreen(
            onDatesSelected: extra['onDatesSelected'],
          );
        },
      ),
      GoRoute(
        path: Routes.expenseForm,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          _logRoute('ExpenseFormScreen', path: state.uri.toString(), extra: {
            'siteId': extra['siteId'],
            'expenseType': extra['expenseType'],
            'expenseId': extra['expenseId'],
          });
          return ExpenseFormScreen(
            siteId: extra['siteId'],
            expenseType: extra['expenseType'],
            expenseId: extra['expenseId'],
            expense: extra['expense'],
          );
        },
      ),
      GoRoute(
        path: Routes.editInventory,
        builder: (context, state) {
          final inventory = state.extra as Inventory;
          _logRoute('EditInventoryScreen',
              path: state.uri.toString(), extra: {'inventoryId': inventory.id});
          return EditInventoryScreen(inventory: inventory);
        },
      ),
      GoRoute(
        path: Routes.editTeam,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          _logRoute('EditTeamScreen',
              path: state.uri.toString(),
              extra: {'site': extra['site'], 'team': extra['team']});
          return EditTeamScreen(
            site: extra['site'],
            team: extra['team'],
          );
        },
      ),
      GoRoute(
        path: Routes.deviceOtp,
        builder: (context, state) {
          _logRoute('DeviceOtpScreen', path: state.uri.toString());
          return const DeviceOtpScreen();
        },
      ),
      GoRoute(
        path: Routes.quotationList,
        builder: (context, state) {
          _logRoute('QuotationList', path: state.uri.toString());
          return const QuotationListScreen();
        },
      ),
      GoRoute(
        path: Routes.quotationCreate,
        builder: (context, state) {
          _logRoute('QuotationCreate', path: state.uri.toString());
          return const QuotationCreateScreen();
        },
      ),
      GoRoute(
        path: Routes.projectList,
        builder: (context, state) {
          _logRoute('ProjectList', path: state.uri.toString());
          return const ProjectListScreen();
        },
      ),
      GoRoute(
        path: '${Routes.crmSetup}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CrmLeadDetailScreen(leadId: id);
        },
      ),
      GoRoute(
        path: Routes.coldCall,
        builder: (context, state) {
          final lead = state.extra as CrmLead;
          return ColdCallScreen(lead: lead);
        },
      ),
      ...UpdatesRoutes.routes,
    ],
  );

  var isSyncScheduled = false;
  var isDisposed = false;
  String? pendingConcretePath;

  void scheduleRouterStateSync() {
    final uri = router.routeInformationProvider.value.uri;
    pendingConcretePath =
        uri.path.isEmpty ? '/' : normalizeRouteLocation(uri.path);

    if (isSyncScheduled) return;
    isSyncScheduled = true;

    Future.microtask(() {
      isSyncScheduled = false;
      if (isDisposed) return;

      final concretePath = pendingConcretePath;
      if (concretePath == null) return;

      ref.read(currentRouteProvider.notifier).state = concretePath;
      ref.read(routeTrailProvider.notifier).syncFromLocation(concretePath);
    });
  }

  router.routerDelegate.addListener(scheduleRouterStateSync);
  ref.onDispose(() {
    isDisposed = true;
    router.routerDelegate.removeListener(scheduleRouterStateSync);
  });

  scheduleRouterStateSync();

  return router;
});
