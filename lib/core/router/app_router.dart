import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/features/modules/all_Modules/ai_analyze/model/ai_analyze_model.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteList.dart';
import 'package:untitled2/features/modules/all_Modules/summary/screens/summaru_screen.dart';


import '../../features/auth/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/onboarding/screens/pla_Select_Screen.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/auth/screens/TrialScreen.dart';
import '../../features/auth/screens/login.dart';
import '../../features/auth/screens/manpower_login_Screen.dart';
import '../../features/auth/screens/sign_up.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/toc.dart';
import '../../features/modules/all_Modules/Manpower Details/model/manpower_model.dart';
import '../../features/modules/all_Modules/Manpower Details/screens/addManpower.dart';
import '../../features/modules/all_Modules/Manpower Details/screens/editManpower.dart';
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
import '../../features/modules/all_Modules/site_Details/screens/siteDetailScreen.dart';
import '../../features/modules/all_Modules/site_Details/screens/view_add_site.dart';
import '../../features/modules/all_Modules/site_Details/screens/site_entry_select_page.dart';
import '../../features/modules/all_Modules/team/screens/addTeam.dart';
import '../../features/modules/all_Modules/team/screens/editTeam.dart';
import '../../features/modules/all_Modules/team/screens/teamsList.dart';
import '../../features/modules/all_Modules/team/screens/view_add.dart';
import '../../features/modules/screen/device_id.dart';
import '../../features/pricing/Screens/subsciption_screen.dart';
import '../../features/pricing/providers/razorpay_provider.dart';
import '../../features/profile_page/screens/profilePage.dart';
import '../../features/modules/screen/module_screen.dart';
import '../../features/modules/screen/module_detail.dart';
import '../../work_cat.dart';
import '../../core/router/routes.dart';
import '../utlis/widgets/date_picker_Screen.dart';
import 'app_access.dart';
import 'go_router_refresh.dart';
import 'package:bot_toast/bot_toast.dart';

final appRouterProvider = Provider<GoRouter>((ref) {



  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: ref.watch(routerRefreshProvider),


    redirect: (context, state) {
      final access = ref.read(appAccessProvider);
      final loc = state.matchedLocation;

      print(
        'ROUTER: booting=${access.isBooting} '
            'loggedIn=${access.loggedIn} '
            'loc=$loc',
      );

      // ── 0. Still booting ───────────────────────────────────────────────────
      if (access.isBooting) return Routes.splash;

      // ── 1. Not logged in → public routes only ──────────────────────────────
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
        return isPublic ? null : Routes.login;
      }

      // ── 2. Logged in → only redirect away from hard gate pages.
      //    /trial and /onboarding are intentionally NOT here — logged-in users
      //    can navigate to them from the access overlay.
      const Set<String> gatePages = {
        Routes.splash,
        Routes.login,
        '/manpower-login',
        '/plan-select',
      };

      if (gatePages.contains(loc)) {
        return Routes.workCategory;
      }

      // ── 3. Logged in + already inside the app → free navigation ───────────
      return null;
    },

    observers: [
      BotToastNavigatorObserver(), // ✅ correct place
    ],

    routes: [

      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.planSelect,
        builder: (context, state) => const PlanSelectScreen(),
      ),

      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.manpowerLogin,
        name: 'manpower-login',
        builder: (context, state) => const ManpowerLoginScreen(),
      ),
      GoRoute(
        path: Routes.workCategory,
        builder: (context, state) => const WorkCategoryScreen(),
      ),
      GoRoute(
        path: Routes.selectModule,
        builder: (context, state) => const ModuleScreen(),
      ),
      GoRoute(
        path: '${Routes.siteList}/:module',
        builder: (context, state) {
          final module = state.pathParameters['module'] ?? 'site';

          final bool show = module == 'site';

          return SiteListScreen(
            show: show,
            pageBuilder: (site) {
              switch (module) {
                case 'rate':
                  return RateSelectCardGrid();
                case 'team':
                  return TeamSelectCardGrid();
                case 'dpr':
                  return DprTeamScreen(site: site);
                case 'boq':
                  return BoqDashboardScreen(
                    siteId: site.id,
                    siteName: site.siteName,
                  );
                case 'attendance':
                  return AttendanceScreen();
                case 'siteSalary':
                  return SiteSalaryScreen(siteModel: site);
                case 'expense':
                  return ExpenseEntrySelectCardGrid();
                  case 'addMoc':
                  return DprSelectCardGrid();
                case 'dprReport':
                  return DateRangeSelectionScreen(onDatesSelected: (DateTime startDate, DateTime endDate) {
                    context.push(Routes.dprReportDownload, extra: {
                      'startDate': startDate,
                      'endDate': endDate,
                    });
                  });
                  case 'inv-entry':
                    // return InventorySelectionPage();
                  return InventoryCategorySelectionScreen();
                case 'inv-setup':
                  return ViewAddInventorySetup();
                  case 'inv-Report':
                  return  DateRangeSelectionScreen(onDatesSelected: (DateTime startDate, DateTime endDate) {
                    context.push(Routes.inventoryReportDownload, extra: {
                      'startDate': startDate,
                      'endDate': endDate,
                    });
                  });

                case 'att-sheet':
                  return GenerateAttendanceSheetScreen();
                case 'add-exp':
                  return AddExpenseScreen();




                default:
                  return SiteDetailScreen(site: site);
              }
            },
          );
        },
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.trial,
        builder: (context, state) => const TrialScreen(),
      ),
      GoRoute(
        path: Routes.site,
        name: 'site',
        builder: (context, state) => const SiteSelectCardGrid(),
      ),
      GoRoute(
        path: Routes.analysis,
        name: 'analysis',
        builder: (context, state) => const AudioUploadAnalysisScreen(),
      ),
      GoRoute(
        path: Routes.mocSelection,
        name: 'mocSelection',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;

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
        builder: (context, state) => const ManSelectCardGrid(),
      ),
      GoRoute(
        path: Routes.manpowerAddDetails,
        builder: (context, state) => const NewManpowerScreen(),
      ),
      GoRoute(
        path: Routes.editManpower,
        builder: (context, state) {
          final manpower = state.extra as ManpowerModel;
          return EditManpowerScreen(manpower: manpower);
        },
      ),

      GoRoute(
        path: '${Routes.dprWorkList}/:siteId/:name',
        builder: (context, state) {
          final siteId = state.pathParameters['siteId']!;
          final name = state.pathParameters['name']!;
          final extra = state.extra as Map<String, dynamic>?;

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
          return ProfileScreen();
        },
      ),
      GoRoute(
        path: Routes.theme,
        builder: (context, state) {
          return ThemeScreen();
        },
      ),
      GoRoute(
        path: Routes.upcomingUpdate,
        builder: (context, state) {
          return Updates();
        },
      ),
      GoRoute(
        path: Routes.subscription,
        builder: (context, state) {
          return SubscriptionScreen();
        },
      ),
      GoRoute(
        path: Routes.language,
        builder: (context, state) {
          return LanguageSelectionScreen();
        },
      ),
      GoRoute(
        path: Routes.help,
        builder: (context, state) {
          return HelpCenterScreen();
        },
      ),

      GoRoute(
        path: Routes.salary,
        builder: (context, state) => const CategoryScreen(),
        routes: [
          GoRoute(
            path: 'individual', // 👈 becomes /salary/individual
            builder: (context, state) => const SalarySlipScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.summary,
        builder: (context, state) {
          return SummaryScreen();
        },
      ),

      GoRoute(
        path: '${Routes.moduleDetail}/:name',
        builder: (context, state) {
          final moduleName = state.pathParameters['name']!;
          return ModuleDetailScreen(moduleName: moduleName);
        },
      ),
      GoRoute(
        path: Routes.dprInsuReview,
        name: 'dpr-screen-insu',
        builder: (context, state) {
          return AddInsulationDescriptionScreen();
        },
      ),

      GoRoute(
        path: Routes.terms,
        name: 'terms',
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),

      GoRoute(
        path: Routes.laggingMaterial,
        name: 'lagging-material',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
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
          return CladdingScreen(
            siteId: data['siteId'],
            teamId: data['teamId'],
            siteName: data['siteName'],
            teamName: data['teamName'],
          );
        },
      ),

      // Migration routes
      GoRoute(
        path: Routes.addTeam,
        builder: (context, state) => const AddTeamScreen(),
      ),
      GoRoute(
        path: Routes.siteEntrySelect,
        builder: (context, state) => const SiteEntrySelectCardGrid(),
      ),
      GoRoute(
        path: Routes.dprReportDownload,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
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
           return AddDescriptionScreen(work: work);
         },
       ),
       GoRoute(
         path: Routes.dprInsuDescription,
         builder: (context, state) {
           final work = state.extra as InsulationDprModel?;
           return AddInsulationDescriptionScreen(work: work);
         },
       ),
      GoRoute(
        path: Routes.dprViewSelect,
        builder: (context, state) => const ViewSelectCardGrid(),
      ),
      GoRoute(
        path: Routes.addMoc,
        builder: (context, state) => const AddMOCPage(),
      ),
      GoRoute(
        path: Routes.addFloor,
        builder: (context, state) => const AddFloorPage(),
      ),
      GoRoute(
        path: Routes.salarySelectRange,
        builder: (context, state) => const SelectRangeScreen(),
      ),
      GoRoute(
        path: Routes.inventoryList,
        builder: (context, state) => const InventoryListScreen(),
      ),
      GoRoute(
        path: Routes.editRate,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
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
          return AddRateScreen();
        },
      ),
      GoRoute(
         path: Routes.datePicker,
         builder: (context, state) {
           final extra = state.extra as Map<String, dynamic>;
           return DateRangeSelectionScreen(
             onDatesSelected: extra['onDatesSelected'],
           );
         },
       ),
       GoRoute(
         path: Routes.expenseForm,
         builder: (context, state) {
           final extra = state.extra as Map<String, dynamic>;
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
           return EditInventoryScreen(inventory: inventory);
         },
       ),
       GoRoute(
         path: Routes.editTeam,
         builder: (context, state) {
           final extra = state.extra as Map<String, dynamic>;
           return EditTeamScreen(
             site: extra['site'],
             team: extra['team'],
           );
         },
       ),

      GoRoute(
        path: Routes.deviceOtp,
        builder: (context, state) => const DeviceOtpScreen(),
      ),
      ],
    );
  });
