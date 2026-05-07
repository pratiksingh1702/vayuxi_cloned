import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:untitled2/core/router/routes.dart';
import 'peb_dpr_widgets.dart';
import '../../../../core/utlis/widgets/custom_appBar.dart';

class PebDprHomeScreen extends StatelessWidget {
  const PebDprHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _DprStageItem(
        title: 'GA Drawing',
        subtitle: 'Review drawing status and approvals.',
        icon: LucideIcons.fileText,
        routeName: Routes.pebDprGa,
        color: Colors.blue,
      ),
      _DprStageItem(
        title: 'Fabrication',
        subtitle: 'Track production and milestones.',
        icon: LucideIcons.factory,
        routeName: Routes.pebDprFabrication,
        color: Colors.orange,
      ),
      _DprStageItem(
        title: 'Procurement',
        subtitle: 'Monitor items and deliveries.',
        icon: LucideIcons.truck,
        routeName: Routes.pebDprProcurement,
        color: Colors.green,
      ),
    ];

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : colorScheme.surfaceContainerLowest,
      appBar: const CustomAppBar(
        title: 'PEB DPR Entry',
        showDrawer: false,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: const [
                  PebSectionHeader(
                    title: 'DPR Dashboard',
                    subtitle: 'Select a stage to track progress and update daily reports for PEB work.',
                    icon: LucideIcons.layoutDashboard,
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];
                  return _DprStageCard(
                    title: item.title,
                    subtitle: item.subtitle,
                    icon: item.icon,
                    color: item.color,
                    onTap: () => context.push(item.routeName),
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _DprStageItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;
  final Color color;

  const _DprStageItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.routeName,
    required this.color,
  });
}

class _DprStageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DprStageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

