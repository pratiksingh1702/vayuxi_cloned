import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/utlis/widgets/premium_app_bar.dart';
import '../models/dpr_structure_model.dart';
import '../providers/dpr_structure_provider.dart';
import '../../boq/providers/boq_structure_provider.dart';
import 'dpr_structure_create_screen.dart';
import 'dpr_structure_detail_screen.dart';

const _kBrown = Color(0xFF7B3F00);

class DprStructureListScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;
  const DprStructureListScreen(
      {super.key, required this.siteId, required this.siteName});

  @override
  ConsumerState<DprStructureListScreen> createState() =>
      _DprStructureListScreenState();
}

class _DprStructureListScreenState
    extends ConsumerState<DprStructureListScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  int _filterIndex = 0; // 0=All,1=Today,2=Week,3=Month
  final List<String> _filterLabels = ['All', 'Today', 'Week', 'Month'];

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilter(0);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _applyFilter(int index) {
    setState(() => _filterIndex = index);
    final notifier = ref.read(dprStructureProvider.notifier);
    DateTime? start, end;
    final now = DateTime.now();
    switch (index) {
      case 1:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 2:
        start = now.subtract(const Duration(days: 7));
        end = now;
        break;
      case 3:
        start = DateTime(now.year, now.month, 1);
        end = now;
        break;
      default:
        break;
    }
    notifier.setFilters(startDate: start, endDate: end, clear: index == 0);
    notifier.fetchDPRList(widget.siteId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dprStructureProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
      appBar: PremiumAppBar(
        title: 'Structure DPR',
        onDrawerPressed: () => context.pop(),
        drawerIcon: Icons.arrow_back_ios_new_rounded,
      ),
      body: Column(
        children: [
          // Header Stats Card
          _buildHeaderDashboard(state, cs, isDark),

          // Filter Row
          _buildFilterBar(cs),

          // List
          Expanded(
            child: state.isLoading
                ? const _DPRShimmerList()
                : state.error != null && state.dprs.isEmpty
                    ? _ErrorView(
                        message: state.error!,
                        onRetry: () => ref
                            .read(dprStructureProvider.notifier)
                            .fetchDPRList(widget.siteId))
                    : state.dprs.isEmpty
                        ? const _EmptyDPRState()
                        : RefreshIndicator(
                            color: _kBrown,
                            onRefresh: () => ref
                                .read(dprStructureProvider.notifier)
                                .fetchDPRList(widget.siteId),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                              itemCount: state.dprs.length,
                              itemBuilder: (ctx, i) {
                                final dpr = state.dprs[i];
                                return _DPRCard(
                                  dpr: dpr,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => DprStructureDetailScreen(
                                          dprId: dpr.id,
                                          siteId: widget.siteId,
                                          dpr: dpr,
                                        ),
                                      ),
                                    );
                                  },
                                  onDelete: () => _confirmDelete(ctx, dpr),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => FloatingActionButton.extended(
          backgroundColor: _kBrown,
          elevation: 6 + _pulseCtrl.value * 3,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DprStructureCreateScreen(
                siteId: widget.siteId,
                siteName: widget.siteName,
                onSuccess: () => ref
                    .read(dprStructureProvider.notifier)
                    .fetchDPRList(widget.siteId),
              ),
            ),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Add DPR',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _buildHeaderDashboard(
      DPRStructureState state, ColorScheme cs, bool isDark) {
    final totalWeight = state.dprs.fold<double>(0, (p, c) => p + c.totalNetWeight);
    final totalQty = state.dprs.fold<double>(0, (p, c) => p + c.totalQtyUsed);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kBrown,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: _kBrown.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/header_bg.webp'),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.siteName,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const Text('Structural Progress',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics_outlined,
                    color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _DashboardStat(
                  label: 'Total Weight',
                  value: '${(totalWeight / 1000).toStringAsFixed(2)} MT',
                  icon: Icons.monitor_weight_outlined),
              const SizedBox(width: 24),
              _DashboardStat(
                  label: 'DPR Entries',
                  value: state.dprs.length.toString(),
                  icon: Icons.description_outlined),
              const SizedBox(width: 24),
              _DashboardStat(
                  label: 'Total Qty',
                  value: totalQty.toStringAsFixed(0),
                  icon: Icons.inventory_2_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ColorScheme cs) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterLabels.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, i) {
          final isSelected = _filterIndex == i;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: GestureDetector(
              onTap: () => _applyFilter(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _kBrown : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? _kBrown
                        : cs.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _filterLabels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : cs.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, DPRStructure dpr) async {
    final cs = Theme.of(ctx).colorScheme;
    final ok = await showModalBottomSheet<bool>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (b) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: cs.errorContainer.withOpacity(0.4),
                  shape: BoxShape.circle),
              child: Icon(Icons.delete_sweep_rounded,
                  color: cs.error, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Delete DPR Entry',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
                'Are you sure you want to delete "${dpr.dprName}"?\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(b, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(b, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Delete',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      HapticFeedback.heavyImpact();
      final success = await ref
          .read(dprStructureProvider.notifier)
          .deleteDPR(widget.siteId, dpr.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'DPR deleted' : 'Delete failed'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }
}

class _DashboardStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _DashboardStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white60, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _DPRCard extends StatelessWidget {
  final DPRStructure dpr;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _DPRCard(
      {required this.dpr, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = dpr.status == 'approved'
        ? Colors.green
        : dpr.status == 'rejected'
            ? Colors.red
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onDelete,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _kBrown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.architecture_rounded,
                            color: _kBrown, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dpr.dprName,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            if (dpr.boqName != null)
                              Text(dpr.boqName!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(dpr.status.toUpperCase(),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DPRStatItem(
                        label: 'Weight',
                        value: '${(dpr.totalNetWeight / 1000).toStringAsFixed(2)}',
                        unit: 'MT',
                        icon: Icons.scale_outlined,
                      ),
                      _DPRStatItem(
                        label: 'Quantity',
                        value: dpr.totalQtyUsed.toStringAsFixed(0),
                        unit: 'Units',
                        icon: Icons.inventory_2_outlined,
                      ),
                      _DPRStatItem(
                        label: 'Date',
                        value: DateFormat('dd MMM').format(dpr.date ?? DateTime.now()),
                        unit: DateFormat('yyyy').format(dpr.date ?? DateTime.now()),
                        icon: Icons.calendar_today_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DPRStatItem extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  const _DPRStatItem(
      {required this.label,
      required this.value,
      required this.unit,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: cs.onSurfaceVariant.withOpacity(0.6)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant.withOpacity(0.6))),
          ],
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DPRShimmerList extends StatelessWidget {
  const _DPRShimmerList();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 160,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

class _EmptyDPRState extends StatelessWidget {
  const _EmptyDPRState();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _kBrown.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.note_add_outlined, size: 48, color: _kBrown),
          ),
          const SizedBox(height: 24),
          const Text('No DPR Entries Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Keep track of your structural work progress by adding your first DPR.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: cs.error),
            const SizedBox(height: 24),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Loading',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
