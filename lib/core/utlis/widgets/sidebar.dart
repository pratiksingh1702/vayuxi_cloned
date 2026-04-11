import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/router/app_router.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/features/tour/domain/tour_controller.dart';
import 'package:untitled2/features/tour/registry/site_registry.dart';
import '../../../features/auth/provider/auth_provider.dart';
import '../../../features/modules/screen/device_id.dart';
import '../../../features/modules/screen/device_id_helper.dart';

import '../../../features/profile_page/provider/userProvider.dart';
import '../../api/requestQueue.dart';
import '../../api/syncManager.dart';
import 'custom_scrollbar.dart';

final drawerExpandedSectionProvider = StateProvider<String?>((ref) => 'MAIN');

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  ColorScheme _cs(BuildContext context) => Theme.of(context).colorScheme;

  Color _background(BuildContext context) => _cs(context).surface;
  Color _surface(BuildContext context) => _cs(context).surfaceContainerLowest;
  Color _surfaceElevated(BuildContext context) => _cs(context).surfaceContainer;
  Color _primary(BuildContext context) => _cs(context).primary;
  Color _primaryLight(BuildContext context) => _cs(context).primaryContainer;
  Color _textPrimary(BuildContext context) => _cs(context).onSurface;
  Color _textSecondary(BuildContext context) => _cs(context).onSurfaceVariant;
  Color _textMuted(BuildContext context) =>
      _cs(context).onSurfaceVariant.withOpacity(0.8);
  Color _divider(BuildContext context) => _cs(context).outlineVariant;
  Color _danger(BuildContext context) => _cs(context).error;
  Color _dangerLight(BuildContext context) => _cs(context).errorContainer;
  Color _success(BuildContext context) => _cs(context).tertiary;
  Color _successLight(BuildContext context) => _cs(context).tertiaryContainer;

  Future<bool> _checkDeviceVerification() async {
    final id = await DevicePrefs.getDeviceId();
    return id != null && id.isNotEmpty;
  }

  Future<void> _handleNavigation(
    BuildContext context,
    String route,
    bool requiresVerification,
  ) async {
    Navigator.pop(context);

    if (!requiresVerification) {
      context.push(route);
      return;
    }

    final isDeviceVerified = await _checkDeviceVerification();

    if (!isDeviceVerified) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Device not verified. Please verify first to access this feature."),
            backgroundColor: _danger(context),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceOtpScreen(
              redirectRoute: route,
              redirectExtraData: {},
            ),
          ),
        );
      }
    } else {
      if (context.mounted) {
        context.push(route);
      }
    }
  }

  Future<void> _handleManualSync(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sync started")),
    );

    await ref.read(syncManagerProvider).retry();

    if (!context.mounted) return;

    if (RequestQueue.count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All synced")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${RequestQueue.count} still pending")),
      );
    }
  }

  Future<void> _showTourRestartOptions(
      BuildContext context, WidgetRef ref) async {
    final ctrl = ref.read(tourControllerProvider.notifier);
    final router = ref.read(appRouterProvider);

    Navigator.pop(context);

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Restart Demo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose full replay or a specific module.',
                  style: TextStyle(
                    color: _textSecondary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.refresh_rounded, color: _primary(context)),
                  title: const Text('Complete Demo'),
                  subtitle: const Text(
                      'Reset all tour progress and replay from start'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await ctrl.resetAllAndStartModule(SiteRegistry.module);
                    // Use router directly because drawer/sheet contexts can unmount after pop.
                    router.go(SiteRegistry.module.steps.first.route);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Complete demo restarted')),
                      );
                    }
                  },
                ),
                const Divider(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Text('🏗️', style: TextStyle(fontSize: 20)),
                  title: const Text('Site Module Demo'),
                  subtitle: const Text('Replay only the Site onboarding flow'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await ctrl
                        .resetModuleAndStartFromBeginning(SiteRegistry.module);
                    // Use router directly because drawer/sheet contexts can unmount after pop.
                    router.go(Routes.site);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Site module demo restarted')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = ScrollController();
    return Drawer(
      child: Container(
        color: _background(context),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollbar(
                  controller: scrollController,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 4),
                      _buildNavItem(
                        context,
                        imagePath: "assets/images/icons/dashboard.webp",
                        title: 'Home',
                        route: '/workCategory',
                        requiresVerification: false,
                      ),
                      const SizedBox(height: 8),
                      _buildFastEntryPremiumCard(context),
                      const SizedBox(height: 8),
                      _buildManualSyncCard(context, ref),
                      const SizedBox(height: 8),
                      AccordionSection(
                        title: 'DAILY OPERATIONS',
                        children: [
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/attendance.webp",
                            title: 'Attendance',
                            route: '/site-list/attendance',
                            requiresVerification: false,
                          ),
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/dpr.webp",
                            title: 'Daily Progress',
                            route: '/site-list/dpr',
                            requiresVerification: false,
                          ),
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/expense_daily.webp",
                            title: 'Expense Entry',
                            route: '/site-list/add-exp',
                            requiresVerification: false,
                          ),
                          _buildNavItem(
                            context,
                            imagePath:
                                "assets/images/icons/inventory_entry.webp",
                            title: 'Inventory Entry',
                            route: '/site-list/inv-entry',
                            requiresVerification: false,
                          ),
                        ],
                      ),
                      AccordionSection(
                        title: 'SETUP & CONFIGURATION',
                        children: [
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/site_details.webp",
                            title: 'Site Details',
                            route: '/site',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/rate.webp",
                            title: 'Rate Management',
                            route: '/site-list/rate',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath:
                                "assets/images/icons/manpower_setup.webp",
                            title: 'Manpower Details',
                            route: '/manpower',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/add_team.webp",
                            title: 'Team Management',
                            route: '/site-list/team',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/dpr_setup.webp",
                            title: 'DPR Setup',
                            route: '/site-list/addMoc',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath:
                                "assets/images/icons/inventory_setup.webp",
                            title: 'Inventory Setup',
                            route: '/site-list/inv-setup',
                            requiresVerification: true,
                          ),
                        ],
                      ),
                      AccordionSection(
                        title: 'REPORTS & ANALYSIS',
                        children: [
                          _buildNavItem(
                            context,
                            imagePath:
                                "assets/images/icons/summary_analysis.webp",
                            title: 'Summary & Analysis',
                            route: '/summary',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/ai_analysis.webp",
                            title: 'AI Analysis',
                            route: '/analysis',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/salary_slip.webp",
                            title: 'Salary Reports',
                            route: '/salary',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/dpr_report.webp",
                            title: 'DPR Sheets',
                            route: '/site-list/dprReport',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/expense_sheet.webp",
                            title: 'Expense Report',
                            route: '/site-list/expense',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath:
                                "assets/images/icons/attendance_sheet.webp",
                            title: 'Attendance Sheet',
                            route: '/site-list/att-sheet',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath:
                                "assets/images/icons/inventory_summary.webp",
                            title: 'Inventory Report',
                            route: '/site-list/inv-Report',
                            requiresVerification: true,
                          ),
                        ],
                      ),
                      AccordionSection(
                        title: 'SETTINGS',
                        children: [
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/profile.webp",
                            title: 'Profile',
                            route: '/profile',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/subscription.webp",
                            title: 'Subscription',
                            route: '/subscription',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/theme.webp",
                            title: 'Theme',
                            route: '/theme',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/language.webp",
                            title: 'Language',
                            route: '/language',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/updates.webp",
                            title: 'What\'s New',
                            route: '/upcoming-update',
                            requiresVerification: true,
                          ),
                          _buildNavItem(
                            context,
                            imagePath: "assets/images/icons/help.webp",
                            title: 'Help & Support',
                            route: '/help',
                            requiresVerification: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildDrawerFooter(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String imagePath,
    required String title,
    required String route,
    required bool requiresVerification,
  }) {
    String currentRoute = '';
    bool isActive = false;

    final router = GoRouter.maybeOf(context);

    if (router != null) {
      currentRoute = router.routeInformationProvider.value.uri.path;
      isActive = currentRoute == route || currentRoute.startsWith(route);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: _cs(context).surface.withOpacity(0),
        child: InkWell(
          onTap: () => _handleNavigation(context, route, requiresVerification),
          borderRadius: BorderRadius.circular(12),
          splashColor: _primary(context).withOpacity(0.08),
          highlightColor: _cs(context).surface.withOpacity(0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? _primaryLight(context)
                  : _cs(context).surface.withOpacity(0),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: _primary(context).withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child: Image.asset(
                    imagePath,
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.circle_outlined,
                        color: isActive
                            ? _primary(context)
                            : _textSecondary(context),
                        size: 20,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isActive ? _primary(context) : _textPrimary(context),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 3,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _primary(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualSyncCard(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: _cs(context).surface.withOpacity(0),
        child: InkWell(
          onTap: () => _handleManualSync(context, ref),
          borderRadius: BorderRadius.circular(12),
          splashColor: _success(context).withOpacity(0.08),
          highlightColor: _cs(context).surface.withOpacity(0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _successLight(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _success(context).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _success(context).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.sync,
                    color: _success(context),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual Sync',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary(context),
                        ),
                      ),
                      Text(
                        'Sync pending data',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: _textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _success(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.cloud_upload,
                    color: _success(context),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFastEntryPremiumCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: _cs(context).surface.withOpacity(0),
        child: InkWell(
          onTap: () => _handleNavigation(context, Routes.automatedEntry, true),
          borderRadius: BorderRadius.circular(14),
          splashColor: _primary(context).withOpacity(0.08),
          highlightColor: _cs(context).surface.withOpacity(0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryLight(context).withOpacity(0.72),
                  _primaryLight(context).withOpacity(0.94),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primary(context).withOpacity(0.24)),
              boxShadow: [
                BoxShadow(
                  color: _primary(context).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primary(context).withOpacity(0.9),
                        _primary(context),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: _cs(context).onPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fast Entry',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary(context),
                        ),
                      ),
                      Text(
                        'Premium guided upload wizard',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _primary(context),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Container(
      decoration: BoxDecoration(
        color: _background(context),
        border: Border(
          top: BorderSide(color: _divider(context), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User Profile Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surface(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _surfaceElevated(context),
                      ),
                      child: ClipOval(
                        child: user?.profilePhoto != null &&
                                user!.profilePhoto!.isNotEmpty
                            ? Image.network(
                                user.profilePhoto!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person_outline,
                                    size: 24,
                                    color: _textSecondary(context),
                                  );
                                },
                              )
                            : Icon(
                                Icons.person_outline,
                                size: 24,
                                color: _textSecondary(context),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Guest User',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary(context),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'Not signed in',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: _textSecondary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: _cs(context).surface.withOpacity(0),
                child: InkWell(
                  onTap: () => _showTourRestartOptions(context, ref),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _primaryLight(context),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: _primary(context).withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assistant_navigation,
                          size: 16,
                          color: _primary(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Restart Demo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _primary(context),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Logout Button
              Material(
                color: _cs(context).surface.withOpacity(0),
                child: InkWell(
                  onTap: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _dangerLight(context),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.logout,
                                color: _danger(context),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        content: const Text(
                          'Are you sure you want to logout?',
                          style: TextStyle(fontSize: 14),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: _textSecondary(context),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: _danger(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    _cs(context).surface.withOpacity(0),
                                foregroundColor: _cs(context).onError,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      final authNotifier = ref.read(authProvider.notifier);
                      await authNotifier.logout();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _surface(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout,
                          size: 16,
                          color: _danger(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _danger(context),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Version
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _textMuted(context),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccordionSection extends ConsumerWidget {
  final String title;
  final List<Widget> children;

  const AccordionSection({
    super.key,
    required this.title,
    required this.children,
  });

  // Mapping from section title to ModuleScreen tab index
  static const Map<String, int> _sectionToTabIndex = {
    'DAILY OPERATIONS': 0,
    'SETUP & CONFIGURATION': 1,
    'REPORTS & ANALYSIS': 2,
    'SETTINGS': 3,
  };

  ColorScheme _cs(BuildContext context) => Theme.of(context).colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedSection = ref.watch(drawerExpandedSectionProvider);
    final isExpanded = expandedSection == title;
    final tabIndex = _sectionToTabIndex[title];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
          child: Row(
            children: [
              // 1. Section Title (Navigation Trigger)
              Material(
                color: _cs(context).surface.withOpacity(0),
                child: InkWell(
                  onTap: () {
                    if (tabIndex != null) {
                      Navigator.pop(context); // Close drawer
                      context.push('/select-module?index=$tabIndex');
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _cs(context).onSurfaceVariant.withOpacity(0.8),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 2. Divider (Visual only)
              Expanded(
                child: Container(
                  height: 1,
                  color: _cs(context).outlineVariant,
                ),
              ),
              const SizedBox(width: 8),
              // 3. Arrow Icon (Expand/Collapse Trigger)
              Material(
                color: _cs(context).surface.withOpacity(0),
                child: InkWell(
                  onTap: () {
                    ref.read(drawerExpandedSectionProvider.notifier).state =
                        isExpanded ? null : title;
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: _cs(context).onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ClipRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            heightFactor: isExpanded ? 1.0 : 0.0,
            child: Column(
              children: [
                ...children,
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
