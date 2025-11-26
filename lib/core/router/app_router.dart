import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteList.dart';
import 'package:untitled2/features/modules/all_Modules/summary/screens/summaru_screen.dart';


import '../../features/auth/provider/auth_provider.dart';
import '../../features/auth/screens/login.dart';
import '../../features/auth/screens/sign_up.dart';
import '../../features/modules/all_Modules/Manpower Details/model/manpower_model.dart';
import '../../features/modules/all_Modules/Manpower Details/screens/addManpower.dart';
import '../../features/modules/all_Modules/Manpower Details/screens/editManpower.dart';
import '../../features/modules/all_Modules/Manpower Details/screens/manpowerList.dart';

import '../../features/modules/all_Modules/attendance/screen/dailyAttendanceScreen.dart';
import '../../features/modules/all_Modules/dpr/dpr-setup/screens/add/add_floor.dart';
import '../../features/modules/all_Modules/dpr/dpr-setup/screens/add/add_moc.dart';
import '../../features/modules/all_Modules/dpr/dpr-setup/screens/add/select_page.dart';
import '../../features/modules/all_Modules/dpr/dpr-setup/screens/view_add.dart';
import '../../features/modules/all_Modules/dpr/dpr_report/screens/download_sheets.dart';
import '../../features/modules/all_Modules/dpr/screens/dprTeamDetails.dart';
import '../../features/modules/all_Modules/dpr/screens/dprTeamPage.dart';
import '../../features/modules/all_Modules/expense/screens/expense_screen.dart';
import '../../features/modules/all_Modules/inventory/screens/add_inven.dart';
import '../../features/modules/all_Modules/rate/screens/rate.dart';
import '../../features/modules/all_Modules/salary/screens/individual.dart';
import '../../features/modules/all_Modules/salary/screens/salarycat.dart';
import '../../features/modules/all_Modules/salary/screens/site.dart';
import '../../features/modules/all_Modules/site_Details/screens/siteDetailScreen.dart';
import '../../features/modules/all_Modules/team/screens/addTeam.dart';
import '../../features/modules/all_Modules/team/screens/teamsList.dart';
import '../../features/profile_page/screens/profilePage.dart';
import '../../features/modules/screen/module_screen.dart';
import '../../features/modules/screen/module_detail.dart';
import '../../work_cat.dart';
import '../../core/router/routes.dart';
import 'go_router_refresh.dart';
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);


  return GoRouter(
    initialLocation: Routes.login, // Always start at login
    debugLogDiagnostics: true,
      redirect: (context, state) {
        final loggedIn = authState.isLoggedIn;
        final loggingIn = state.matchedLocation == Routes.login;
        final registering = state.matchedLocation == '/register';

        // If NOT logged in → allow only login & register
        if (!loggedIn && !loggingIn && !registering) {
          return Routes.login;
        }

        // If logged in and trying to access login/register → move to home
        if (loggedIn && (loggingIn || registering)) {
          return Routes.workCategory;
        }

        return null;
      },


    refreshListenable: GoRouterRefreshNotifier(authProvider, ref),
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
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
                  return RateScreen(site: site);
                case 'team':
                  return TeamListPage(site: site);
                case 'dpr':
                  return DprTeamScreen(site: site);
                case 'attendance':
                  return DailyAttendanceScreen(siteId:site.id, siteName: site.siteName);
                case 'siteSalary':
                  return SiteSalaryScreen(siteModel: site);
                case 'expense':
                  return ExpenseListScreen(siteId: site.id);
                  case 'addMoc':
                  return SelectCardGrid();
                case 'dprReport':
                  return SheetDownloadPage();
                case 'inv-setup':
                  return BulkUploadScreen(siteId: '',siteName: '',);


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
        path: '/manpower',
        builder: (context, state) => const ManpowerListScreen(),
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
        path: '/add-team',
        builder: (context, state) {
          final site = state.extra as SiteModel; // retrieve it
          return AddTeamScreen(site: site);
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
