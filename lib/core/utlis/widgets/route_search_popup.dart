import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/router/routes.dart';

class RouteSearchItem {
  final String title;
  final String route;
  final IconData icon;
  final String category;

  const RouteSearchItem({
    required this.title,
    required this.route,
    required this.icon,
    required this.category,
  });
}

const List<RouteSearchItem> _allRoutes = [
  RouteSearchItem(title: 'Home', route: Routes.workCategory, icon: Icons.home_rounded, category: 'Main'),
  RouteSearchItem(title: 'Fast Entry', route: Routes.automatedEntry, icon: Icons.auto_awesome_rounded, category: 'Main'),
  
  RouteSearchItem(title: 'Attendance', route: '${Routes.siteList}/attendance', icon: Icons.how_to_reg_rounded, category: 'Daily Operations'),
  RouteSearchItem(title: 'Daily Progress', route: '${Routes.siteList}/dpr', icon: Icons.description_rounded, category: 'Daily Operations'),
  RouteSearchItem(title: 'Expense Entry', route: '${Routes.siteList}/add-exp', icon: Icons.receipt_long_rounded, category: 'Daily Operations'),
  RouteSearchItem(title: 'Inventory Entry', route: '${Routes.siteList}/inv-entry', icon: Icons.inventory_2_rounded, category: 'Daily Operations'),
  
  RouteSearchItem(title: 'Site Details', route: Routes.site, icon: Icons.location_city_rounded, category: 'Setup'),
  RouteSearchItem(title: 'Rate Management', route: '${Routes.siteList}/rate', icon: Icons.currency_rupee_rounded, category: 'Setup'),
  RouteSearchItem(title: 'Manpower Details', route: Routes.manpower, icon: Icons.engineering_rounded, category: 'Setup'),
  RouteSearchItem(title: 'Team Management', route: '${Routes.siteList}/team', icon: Icons.groups_rounded, category: 'Setup'),
  RouteSearchItem(title: 'DPR Setup', route: '${Routes.siteList}/addMoc', icon: Icons.settings_suggest_rounded, category: 'Setup'),
  RouteSearchItem(title: 'Inventory Setup', route: '${Routes.siteList}/inv-setup', icon: Icons.warehouse_rounded, category: 'Setup'),
  
  RouteSearchItem(title: 'Summary & Analysis', route: Routes.summary, icon: Icons.analytics_rounded, category: 'Reports'),
  RouteSearchItem(title: 'AI Analysis', route: Routes.analysis, icon: Icons.auto_awesome_rounded, category: 'Reports'),
  RouteSearchItem(title: 'Salary Reports', route: Routes.salary, icon: Icons.payments_rounded, category: 'Reports'),
  RouteSearchItem(title: 'DPR Sheets', route: '${Routes.siteList}/dprReport', icon: Icons.table_chart_rounded, category: 'Reports'),
  RouteSearchItem(title: 'Expense Report', route: '${Routes.siteList}/expense', icon: Icons.request_quote_rounded, category: 'Reports'),
  RouteSearchItem(title: 'Attendance Sheet', route: '${Routes.siteList}/att-sheet', icon: Icons.fact_check_rounded, category: 'Reports'),
  RouteSearchItem(title: 'Inventory Report', route: '${Routes.siteList}/inv-Report', icon: Icons.assessment_rounded, category: 'Reports'),
  
  RouteSearchItem(title: 'Profile', route: Routes.profile, icon: Icons.account_circle_rounded, category: 'Settings'),
  RouteSearchItem(title: 'Subscription', route: Routes.subscription, icon: Icons.workspace_premium_rounded, category: 'Settings'),
  RouteSearchItem(title: 'Theme', route: Routes.theme, icon: Icons.palette_rounded, category: 'Settings'),
  RouteSearchItem(title: 'Language', route: Routes.language, icon: Icons.translate_rounded, category: 'Settings'),
  RouteSearchItem(title: "What's New", route: Routes.upcomingUpdate, icon: Icons.new_releases_rounded, category: 'Settings'),
  RouteSearchItem(title: 'Help & Support', route: Routes.help, icon: Icons.support_agent_rounded, category: 'Settings'),
  RouteSearchItem(title: 'App Settings', route: Routes.settings, icon: Icons.settings, category: 'Settings'),
  RouteSearchItem(title: 'Network Settings', route: Routes.networkSettings, icon: Icons.wifi, category: 'Settings'),
];

Future<void> showRouteSearchPopup(BuildContext context) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.3),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const RouteSearchDialog();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10 * animation.value,
          sigmaY: 10 * animation.value,
        ),
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      );
    },
  );
}

class RouteSearchDialog extends StatefulWidget {
  const RouteSearchDialog({super.key});

  @override
  State<RouteSearchDialog> createState() => _RouteSearchDialogState();
}

class _RouteSearchDialogState extends State<RouteSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<RouteSearchItem> _filteredRoutes = _allRoutes;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterRoutes);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterRoutes);
    _searchController.dispose();
    super.dispose();
  }

  void _filterRoutes() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredRoutes = _allRoutes;
      });
      return;
    }

    setState(() {
      _filteredRoutes = _allRoutes.where((item) {
        final titleMatch = _fuzzyMatch(query, item.title.toLowerCase());
        final categoryMatch = _fuzzyMatch(query, item.category.toLowerCase());
        return titleMatch || categoryMatch;
      }).toList();
    });
  }

  bool _fuzzyMatch(String query, String text) {
    int textIndex = 0;
    for (int i = 0; i < query.length; i++) {
      final char = query[i];
      if (char == ' ') continue;
      bool found = false;
      while (textIndex < text.length) {
        if (text[textIndex] == char) {
          found = true;
          textIndex++;
          break;
        }
        textIndex++;
      }
      if (!found) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              _buildSearchBar(cs),
              Divider(height: 1, color: cs.outlineVariant.withOpacity(0.5)),
              Expanded(
                child: _filteredRoutes.isEmpty
                    ? _buildEmptyState(cs)
                    : _buildResultsList(cs),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: cs.surfaceContainerLowest.withOpacity(0.5),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: cs.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(
                fontSize: 18,
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search pages or routes...',
                hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
              onPressed: () {
                _searchController.clear();
              },
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: cs.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No matching routes found',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredRoutes.length,
      itemBuilder: (context, index) {
        final item = _filteredRoutes[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pop(context); // Close the dialog
              context.push(item.route); // Navigate to the selected route
            },
            hoverColor: cs.primaryContainer.withOpacity(0.3),
            splashColor: cs.primaryContainer.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      color: cs.onSecondaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
