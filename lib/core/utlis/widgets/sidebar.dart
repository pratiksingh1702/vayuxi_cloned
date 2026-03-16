import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/provider/auth_provider.dart';
import '../../../features/modules/screen/device_id.dart';
import '../../../features/modules/screen/device_id_helper.dart';

import '../../api/requestQueue.dart';
import '../../api/syncManager.dart'; // Add this import

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

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
          const SnackBar(
            content: Text("Device not verified. Please verify first to access this feature."),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildSectionTitle('MAIN'),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/dashboard.webp",
                      title: 'Dashboard',
                      route: '/workCategory',
                      gradient: [Colors.blue.shade400, Colors.blue.shade600],
                      requiresVerification: false,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/modules.webp",
                      title: 'Modules',
                      route: '/select-module',
                      gradient: [Colors.purple.shade400, Colors.purple.shade600],
                      requiresVerification: false,
                    ),

                    // MANUAL SYNC BUTTON
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.deepOrange.shade400, Colors.deepOrange.shade600],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.sync,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        title: const Text(
                          'Manual Sync',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.cloud_upload,
                          color: Colors.white,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () => _handleManualSync(context, ref),
                      ),
                    ),

                    const SizedBox(height: 12),
                    _buildSectionTitle('DAILY OPERATIONS'),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/attendance.webp",
                      title: 'Attendance',
                      route: '/site-list/attendance',
                      gradient: [Colors.red.shade400, Colors.red.shade600],
                      requiresVerification: false,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/dpr.webp",
                      title: 'Daily Progress',
                      route: '/site-list/dpr',
                      gradient: [Colors.indigo.shade400, Colors.indigo.shade600],
                      requiresVerification: false,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/expense_daily.webp",
                      title: 'Expense Entry',
                      route: '/site-list/add-exp',
                      gradient: [Colors.orange.shade400, Colors.orange.shade600],
                      requiresVerification: false,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/inventory_entry.webp",
                      title: 'Inventory Entry',
                      route: '/site-list/inv-entry',
                      gradient: [Colors.teal.shade400, Colors.teal.shade600],
                      requiresVerification: false,
                    ),
                    const SizedBox(height: 12),
                    _buildSectionTitle('SETUP & CONFIGURATION'),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/site_details.webp",
                      title: 'Site Details',
                      route: '/site',
                      gradient: [Colors.cyan.shade400, Colors.cyan.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/rate.webp",
                      title: 'Rate Management',
                      route: '/site-list/rate',
                      gradient: [Colors.green.shade400, Colors.green.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/manpower_setup.webp",
                      title: 'Manpower Details',
                      route: '/manpower',
                      gradient: [Colors.amber.shade400, Colors.amber.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/add_team.webp",
                      title: 'Team Management',
                      route: '/site-list/team',
                      gradient: [Colors.lightBlue.shade400, Colors.lightBlue.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/dpr_setup.webp",
                      title: 'DPR Setup',
                      route: '/site-list/addMoc',
                      gradient: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/inventory_setup.webp",
                      title: 'Inventory Setup',
                      route: '/site-list/inv-setup',
                      gradient: [Colors.teal.shade400, Colors.teal.shade600],
                      requiresVerification: true,
                    ),
                    const SizedBox(height: 12),
                    _buildSectionTitle('REPORTS & ANALYSIS'),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/summary_analysis.webp",
                      title: 'Summary & Analysis',
                      route: '/summary',
                      gradient: [Colors.deepOrange.shade400, Colors.deepOrange.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/ai_analysis.webp",
                      title: 'AI Analysis',
                      route: '/analysis',
                      gradient: [Colors.pink.shade400, Colors.pink.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/salary_slip.webp",
                      title: 'Salary Reports',
                      route: '/salary',
                      gradient: [Colors.brown.shade400, Colors.brown.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/dpr_report.webp",
                      title: 'DPR Sheets',
                      route: '/site-list/dprReport',
                      gradient: [Colors.indigo.shade400, Colors.indigo.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/expense_sheet.webp",
                      title: 'Expense Report',
                      route: '/site-list/expense',
                      gradient: [Colors.orange.shade400, Colors.orange.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/attendance_sheet.webp",
                      title: 'Attendance Sheet',
                      route: '/site-list/att-sheet',
                      gradient: [Colors.red.shade400, Colors.red.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/inventory_summary.webp",
                      title: 'Inventory Report',
                      route: '/site-list/inv-Report',
                      gradient: [Colors.teal.shade400, Colors.teal.shade600],
                      requiresVerification: true,
                    ),
                    const SizedBox(height: 12),
                    _buildSectionTitle('SETTINGS'),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/profile.webp",
                      title: 'Profile',
                      route: '/profile',
                      gradient: [Colors.blue.shade400, Colors.blue.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/subscription.webp",
                      title: 'Subscription',
                      route: '/subscription',
                      gradient: [Colors.amber.shade400, Colors.amber.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/theme.webp",
                      title: 'Theme',
                      route: '/theme',
                      gradient: [Colors.purple.shade400, Colors.purple.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/language.webp",
                      title: 'Language',
                      route: '/language',
                      gradient: [Colors.green.shade400, Colors.green.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/updates.webp",
                      title: 'What\'s New',
                      route: '/upcoming-update',
                      gradient: [Colors.lightGreen.shade400, Colors.lightGreen.shade600],
                      requiresVerification: true,
                    ),
                    _buildNavItem(
                      context,
                      imagePath: "assets/images/icons/help.webp",
                      title: 'Help & Support',
                      route: '/help',
                      gradient: [Colors.blueGrey.shade400, Colors.blueGrey.shade600],
                      requiresVerification: true,
                    ),
                  ],
                ),
              ),
              _buildDrawerFooter(context,ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required String imagePath,
        required String title,
        required String route,
        required List<Color> gradient,
        required bool requiresVerification,
      }) {
    String currentRoute = '';
    bool isActive = false;

    final router = GoRouter.maybeOf(context);

    if (router != null) {
      currentRoute =
          router.routeInformationProvider.value.uri.path;
      isActive =
          currentRoute == route || currentRoute.startsWith(route);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: gradient,
        )
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            width: 24,
            height: 24,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.image_not_supported,
                  color: isActive ? Colors.white : Colors.grey.shade700,
                  size: 22,
                );
              },
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.white : Colors.grey.shade800,
          ),
        ),
        trailing: isActive
            ? const Icon(Icons.chevron_right, color: Colors.white, size: 20)
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () => _handleNavigation(context, route, requiresVerification),
      ),
    );
  }

  Widget _buildDrawerFooter(BuildContext context,WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          TextButton.icon(
            onPressed: () async {

                final authNotifier = ref.read(authProvider.notifier);
                await authNotifier.logout();

            },
            icon: Icon(Icons.logout, size: 16, color: Colors.red.shade600),
            label: Text(
              'Logout',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}