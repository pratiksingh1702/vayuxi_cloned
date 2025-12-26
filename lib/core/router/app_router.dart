import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteList.dart';
import 'package:untitled2/features/modules/all_Modules/summary/screens/summaru_screen.dart';


import '../../features/auth/provider/auth_provider.dart';
import '../../features/auth/screens/login.dart';
import '../../features/auth/screens/manpower_login_Screen.dart';
import '../../features/auth/screens/sign_up.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/modules/all_Modules/Manpower Details/model/manpower_model.dart';
import '../../features/modules/all_Modules/Manpower Details/screens/addManpower.dart';
import '../../features/modules/all_Modules/Manpower Details/screens/editManpower.dart';
import '../../features/modules/all_Modules/Manpower Details/screens/manpowerList.dart';

import '../../features/modules/all_Modules/Manpower Details/screens/view_add_manpower.dart';
import '../../features/modules/all_Modules/ai_analyze/screen/audio_upload.dart';
import '../../features/modules/all_Modules/ai_analyze/screen/selection_page.dart';
import '../../features/modules/all_Modules/ai_analyze/screen/tts.dart';
import '../../features/modules/all_Modules/attendance/screen/attendanceScreen.dart';
import '../../features/modules/all_Modules/attendance/screen/dailyAttendanceScreen.dart';
import '../../features/modules/all_Modules/attendance/screen/generate_att.dart';
import '../../features/modules/all_Modules/dpr/dpr-setup/screens/add/add_floor.dart';
import '../../features/modules/all_Modules/dpr/dpr-setup/screens/add/add_moc.dart';
import '../../features/modules/all_Modules/dpr/dpr-setup/screens/add/select_page.dart';
import '../../features/modules/all_Modules/dpr/dpr-setup/screens/view_add.dart';
import '../../features/modules/all_Modules/dpr/dpr_report/screens/download_sheets.dart';
import '../../features/modules/all_Modules/dpr/screens/dprTeamDetails.dart';
import '../../features/modules/all_Modules/dpr/screens/dprTeamPage.dart';
import '../../features/modules/all_Modules/dpr/screens/widgets/moc_selection_page.dart';
import '../../features/modules/all_Modules/expense/screens/add-exp/add_expense.dart';
import '../../features/modules/all_Modules/expense/screens/expense_screen.dart';
import '../../features/modules/all_Modules/inventory/screens/add_bulk_inven.dart';
import '../../features/modules/all_Modules/inventory/screens/add_inven.dart';
import '../../features/modules/all_Modules/inventory/screens/inv_usage/inv_usage.dart';
import '../../features/modules/all_Modules/inventory/screens/inventory_list.dart';
import '../../features/modules/all_Modules/inventory/screens/report/daily_usage.dart';
import '../../features/modules/all_Modules/inventory/screens/view_add_inventory_setup.dart';
import '../../features/modules/all_Modules/more/help.dart';
import '../../features/modules/all_Modules/more/language.dart';
import '../../features/modules/all_Modules/more/more.dart';
import '../../features/modules/all_Modules/more/subscription.dart';
import '../../features/modules/all_Modules/more/themes.dart';
import '../../features/modules/all_Modules/more/upcoming.dart';
import '../../features/modules/all_Modules/rate/screens/rate.dart';
import '../../features/modules/all_Modules/rate/screens/view_add_rate.dart';
import '../../features/modules/all_Modules/salary/screens/individual.dart';
import '../../features/modules/all_Modules/salary/screens/salarycat.dart';
import '../../features/modules/all_Modules/salary/screens/site.dart';
import '../../features/modules/all_Modules/site_Details/screens/siteDetailScreen.dart';
import '../../features/modules/all_Modules/site_Details/screens/view_add_site.dart';
import '../../features/modules/all_Modules/team/screens/addTeam.dart';
import '../../features/modules/all_Modules/team/screens/teamsList.dart';
import '../../features/modules/all_Modules/team/screens/view_add.dart';
import '../../features/profile_page/screens/profilePage.dart';
import '../../features/modules/screen/module_screen.dart';
import '../../features/modules/screen/module_detail.dart';
import '../../work_cat.dart';
import '../../core/router/routes.dart';
import 'go_router_refresh.dart';
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);


  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,

    redirect: (context, state) {
      final authState = ref.watch(authProvider);
      final isLoading = authState.isLoading;
      final loggedIn = authState.isLoggedIn;

      final loggingIn = state.matchedLocation == Routes.login;
      final registering = state.matchedLocation == '/register';
      final manpowerLoggingIn = state.matchedLocation == '/manpower-login';

      final atSplash = state.matchedLocation == Routes.splash;

      print('🔄 ROUTER REDIRECT - isLoading: $isLoading, loggedIn: $loggedIn, location: ${state.matchedLocation}');

      // If still loading, stay at splash
      if (isLoading && !atSplash) {
        return Routes.splash;
      }

      // Define public routes that don't require authentication
      final publicRoutes = [
        Routes.login,
        '/register',
        '/manpower-login',
      ];

      // If not loading and not logged in, only allow access to public routes
      if (!isLoading && !loggedIn && !publicRoutes.contains(state.matchedLocation)) {
        return Routes.login;
      }

      // If logged in and trying to access login/splash, go to appropriate destination
      if (!isLoading && loggedIn && (loggingIn || manpowerLoggingIn || atSplash)) {
        return Routes.workCategory;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/manpower-login',
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
      // GoRoute(
      //   path: Routes.siteList,
      //   builder: (context, state) => const SiteListScreen(),
      // ),
      GoRoute(
        path: '/site-list/:module',
        builder: (context, state) {
          final module = state.pathParameters['module'] ?? 'details';

          return SiteListScreen(
            pageBuilder: (site) {
              switch (module) {
                case 'rate':
                  return RateSelectCardGrid();
                case 'team':
                  return TeamSelectCardGrid();
                case 'dpr':
                  return DprTeamScreen(site: site);
                case 'attendance':
                  return AttendanceScreen();
                case 'siteSalary':
                  return SiteSalaryScreen(siteModel: site);
                case 'expense':
                  return ExpenseListScreen(siteId: site.id);
                  case 'addMoc':
                  return DprSelectCardGrid();
                case 'dprReport':
                  return SheetDownloadPage();
                  case 'inv-entry':
                    return InventorySelectionPage();
                case 'inv-setup':
                  return ViewAddInventorySetup();
                  case 'inv-Report':
                  return DailyUsagePage();

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
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/site',
        name: 'site',
        builder: (context, state) => const SiteSelectCardGrid(),
      ),
      GoRoute(
        path: '/analysis',
        name: 'analysis',
        builder: (context, state) => const AudioUploadAnalysisScreen(),
        // builder: (context, state) =>  TtsTestPage(),
      ),
      GoRoute(
        path: '/moc-selection',
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
        path: '/manpower',
        builder: (context, state) => const ManSelectCardGrid(),
      ),
      GoRoute(
        path: '/manpower/addDetails',
        builder: (context, state) => const NewManpowerScreen(),
      ),
      GoRoute(
        path: '/edit-manpower',
        builder: (context, state) {
          final manpower = state.extra as ManpowerModel;
          return EditManpowerScreen(manpower: manpower);
        },
      ),

      GoRoute(
        path: '/dpr-work-list/:siteId/:teamId/:name',
        builder: (context, state) {
          final siteId = state.pathParameters['siteId']!;
          final teamId = state.pathParameters['teamId']!;
          final name=state.pathParameters['name']!;
          return DprWorkScreen(siteId: siteId, teamId: teamId, name: name,);
        },
      ),

      GoRoute(
        path: '/profile',
        builder: (context, state) {
          return ProfileScreen();


        },
      ),
      GoRoute(
        path: '/theme',
        builder: (context, state) {
          return ThemeSettingsPage();


        },
      ),
      GoRoute(
        path: '/upcoming-update',
        builder: (context, state) {
          return ConstructionSiteScreen();


        },
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) {
          return GetPremiumScreen();


        },
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) {
          return LanguageSelectionScreen();


        },
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) {
          return HelpCenterScreen();


        },
      ),

      GoRoute(
        path: '/salary',
        builder: (context, state) => const CategoryScreen(),
        routes: [
          GoRoute(
            path: 'individual', // 👈 becomes /salary/individual
            builder: (context, state) => const SalarySlipScreen(),
          ),
          // GoRoute(
          //   path: 'many', // 👈 becomes /salary/many
          //   builder: (context, state) => const SalaryBulkScreen(),
          // ),
        ],
      ),
      GoRoute(
        path: '/summary',
        builder: (context, state) {

          return SummaryScreen();
        },
      ),





      GoRoute(
        path: '/module/:name',
        builder: (context, state) {
          final moduleName = state.pathParameters['name']!;
          return ModuleDetailScreen(moduleName: moduleName);
        },
      ),
    ],
  );
});
