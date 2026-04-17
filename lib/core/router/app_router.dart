import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/router/site_aware.dart';
import 'package:untitled2/exit_wrapper.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/screens/ManFieldMappingScreen.dart';
import 'package:untitled2/features/modules/all_Modules/ai_analyze/model/ai_analyze_model.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteList.dart';
import 'package:untitled2/features/modules/all_Modules/summary/screens/summaru_screen.dart';

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
import '../../features/modules/all_Modules/dpr/screens/widgets/moc_selection_page.dart';
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
import '../../features/modules/all_Modules/inventory/screens/view_add_inventory_setup.dart';
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
import '../../features/modules/all_Modules/site_Details/screens/siteDetailScreen.dart';
import '../../features/modules/all_Modules/site_Details/screens/view_add_site.dart';
import '../../features/modules/all_Modules/site_Details/screens/site_entry_select_page.dart';
import '../../features/modules/all_Modules/site_Details/screens/site_import.dart';
import '../../features/modules/all_Modules/team/screens/addTeam.dart';
import '../../features/modules/all_Modules/team/screens/editTeam.dart';
import '../../features/modules/all_Modules/team/screens/teamsList.dart';
import '../../features/modules/all_Modules/team/screens/view_add.dart';
import '../../features/modules/screen/device_id.dart';
import '../../features/pricing/Screens/subsciption_screen.dart';
import '../../features/pricing/providers/razorpay_provider.dart';
import '../../features/profile_page/screens/profilePage.dart';
import '../../features/noti_system/updates/presentation/navigation/updates_routes.dart';
import '../../features/modules/screen/module_screen.dart';
import '../../features/modules/screen/module_detail.dart';
import '../../work_cat.dart';
import '../../core/router/routes.dart';
import '../utlis/widgets/date_picker_Screen.dart';
import 'app_access.dart';
import 'go_router_refresh.dart';
import 'not_found_screen.dart';
import 'package:bot_toast/bot_toast.dart';
import 'route_tracker.dart';

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

  void _updateRoute(Route<dynamic>? route) {
    final name = route?.settings.name ?? route?.settings.arguments?.toString();
    // GoRouter often doesn't put the path in settings.name, so we might need a better way.
    // However, GoRouter state is usually enough.
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => const NotFoundScreen(),
    refreshListenable: ref.watch(routerRefreshProvider),
    redirect: (context, state) {
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
        debugPrint(
            '🔀 [ROUTER REDIRECT] → ${Routes.workCategory}  (reason: logged in, was at gate page: $loc)');
        return Routes.workCategory;
      }

      // ── 3. Logged in + inside app → free navigation ─────────────────────
      debugPrint(
          '🔀 [ROUTER REDIRECT] → null  (reason: logged in, free navigation to $loc)');
      return null;
    },
    observers: [
      BotToastNavigatorObserver(),
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
          return ModuleScreen(initialIndex: initialIndex);
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

          // ── Build the pageBuilder switch once ──────────────────────────────
          Widget buildDestination(SiteModel site) {
            debugPrint(
                '📍 [ROUTER] pageBuilder called | module=$module | siteId=${site.id}');

            Widget screen;
            switch (module) {
              case 'rate':
                screen = RateSelectCardGrid();
                break;
              case 'team':
                screen = TeamSelectCardGrid();
                break;
              case 'dpr':
                screen = DprFlowGate(site: site);
                break;
              case 'boq':
                screen = BoqDashboardScreen(
                    siteId: site.id, siteName: site.siteName);
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
              
                screen = ViewAddInventorySetup();
                break;
              case 'att-sheet':
                screen = GenerateAttendanceSheetScreen();
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
              default:
                screen = SiteDetailScreen(site: site);
            }

            // ✅ Wrap so selectedSiteIdProvider syncs safely after build
            return SiteAwareWrapper(site: site, child: screen);
          }

          // ── Read the container to check if a site is already selected ──────
          final container = ProviderScope.containerOf(context, listen: false);
          final preSelectedSite = container.read(siteDropdownValueProvider);

          // ── If site already chosen AND this is not the site-management screen,
          //    skip SiteListScreen entirely and go straight to destination ──────
          if (preSelectedSite != null && !show) {
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
          _logRoute('SiteSelectCardGrid', path: state.uri.toString());
          return const SiteSelectCardGrid();
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
          final data = state.extra as Map<String, dynamic>;
          _logRoute('MOCSelectionPage', path: state.uri.toString(), extra: {
            'siteId': data['siteId'],
            'teamId': data['teamId'],
            'teamName': data['teamName'],
          });
          return MOCSelectionPage(
            siteId: data['siteId'],
            teamId: data['teamId'],
            teamName: data['teamName'],
            onMOCSelected: data['onMOCSelected'],
          );
        },
      ),
      GoRoute(
        path: Routes.manpower,
        builder: (context, state) {
          _logRoute('ManSelectCardGrid', path: state.uri.toString());
          return const ManSelectCardGrid();
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
          final work = state.extra as DprModel?;
          _logRoute('AddDescriptionScreen (dprDescription)',
              path: state.uri.toString(), extra: {'workId': work?.id});
          return AddDescriptionScreen(work: work);
        },
      ),
      GoRoute(
        path: Routes.dprInsuDescription,
        builder: (context, state) {
          final work = state.extra as InsulationDprModel?;
          _logRoute('AddInsulationDescriptionScreen (dprInsuDescription)',
              path: state.uri.toString(), extra: {'workId': work?.id});
          return AddInsulationDescriptionScreen(work: work);
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
          final siteId = state.extra as String;
          _logRoute('AddRateScreen',
              path: state.uri.toString(), extra: {'siteId': siteId});
          return AddRateScreen();
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
      ...UpdatesRoutes.routes,
    ],
  );

  void syncFromRouterState() {
    final uri = router.routeInformationProvider.value.uri;
    final concretePath = uri.path.isEmpty ? '/' : normalizeRouteLocation(uri.path);
    ref.read(currentRouteProvider.notifier).state = concretePath;
    ref.read(routeTrailProvider.notifier).syncFromLocation(concretePath);
  }

  router.routerDelegate.addListener(syncFromRouterState);
  ref.onDispose(() {
    router.routerDelegate.removeListener(syncFromRouterState);
  });

  Future.microtask(syncFromRouterState);

  return router;
});
