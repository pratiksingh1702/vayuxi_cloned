import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/boq_model.dart';

import '../providers/boq_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BOQ DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class BoqDetailScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String boqId;
  final String boqName;

  const BoqDetailScreen({
    super.key,
    required this.siteId,
    required this.boqId,
    required this.boqName,
  });

  @override
  ConsumerState<BoqDetailScreen> createState() => _BoqDetailScreenState();
}

class _BoqDetailScreenState extends ConsumerState<BoqDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  BoqDetailParams get _params =>
      BoqDetailParams(siteId: widget.siteId, boqId: widget.boqId);

  Future<void> _changeStatus(String status) async {
    await ref.read(boqStatusProvider.notifier).updateStatus(
      siteId: widget.siteId,
      boqId: widget.boqId,
      status: status,
    );
    ref.invalidate(boqDetailProvider(_params));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $status'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete BOQ?'),
        content: const Text(
            'This will soft-delete the BOQ. This action can be reviewed later.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(boqStatusProvider.notifier)
          .delete(siteId: widget.siteId, boqId: widget.boqId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(boqDetailProvider(_params));
    final progressAsync = ref.watch(boqProgressProvider(_params));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.boqName,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'delete') _confirmDelete();
              if (val == 'active' || val == 'completed' || val == 'draft') {
                _changeStatus(val);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'active', child: Text('Mark Active')),
              const PopupMenuItem(
                  value: 'completed', child: Text('Mark Completed')),
              const PopupMenuItem(
                  value: 'draft', child: Text('Move to Draft')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: const Color(0xFF6B7280),
            indicatorColor: const Color(0xFF2563EB),
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'OVERVIEW'),
              Tab(text: 'ITEMS'),
              Tab(text: 'TIMELINE'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Overview ───────────────────────────────────────────────────
          detailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (detail) => _OverviewTab(detail: detail),
          ),

          // ── Items ──────────────────────────────────────────────────────
          detailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (detail) => _ItemsTab(detail: detail),
          ),

          // ── Timeline ───────────────────────────────────────────────────
          progressAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (progress) => _TimelineTab(progress: progress),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERVIEW TAB
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final BoqDetail detail;
  const _OverviewTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    final progress = detail.progressPercentage.clamp(0.0, 100.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Progress card ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall Progress',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13),
                    ),
                    Text(
                      '${progress.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ProgressStat(
                        label: 'Completed',
                        value: _fmt(detail.completedQuantity)),
                    _ProgressStat(
                        label: 'Remaining',
                        value: _fmt(detail.remainingQuantity)),
                    _ProgressStat(
                        label: 'Total',
                        value: _fmt(detail.totalQuantity)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Metrics grid ──────────────────────────────────────────────
          _SectionTitle('Metrics'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              if (detail.isMechanical) ...[
                _MetricCard(
                  label: 'Total Inch Dia',
                  value: _fmt(detail.totalInchDia),
                  icon: Icons.radio_button_unchecked,
                  color: const Color(0xFF7C3AED),
                ),
                _MetricCard(
                  label: 'Total Inch Mtr',
                  value: _fmt(detail.totalInchMtr),
                  icon: Icons.straighten,
                  color: const Color(0xFF2563EB),
                ),
              ] else ...[
                _MetricCard(
                  label: 'Total RMT',
                  value: _fmt(detail.totalRMT),
                  icon: Icons.straighten,
                  color: const Color(0xFF0891B2),
                ),
                _MetricCard(
                  label: 'Total Area (m²)',
                  value: _fmt(detail.totalArea),
                  icon: Icons.square_foot,
                  color: const Color(0xFF059669),
                ),
              ],
              _MetricCard(
                label: 'Total Items',
                value: '${detail.totalItems ?? detail.mechanicalItems.length + detail.insulationItems.length}',
                icon: Icons.list_alt_outlined,
                color: const Color(0xFFF59E0B),
              ),
              _MetricCard(
                label: 'Status',
                value: detail.status.toUpperCase(),
                icon: Icons.info_outline,
                color: _statusColor(detail.status),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── BOQ Info ──────────────────────────────────────────────────
          _SectionTitle('BOQ Information'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                _InfoRow('BOQ Number', detail.boqNumber),
                _InfoRow('Type',
                    detail.isMechanical ? 'Mechanical Work' : 'Insulation Piping'),
                _InfoRow('Upload Method',
                    detail.uploadMethod?.toUpperCase() ?? '—'),
                if (detail.varianceStatus != null)
                  _InfoRow('Variance Status',
                      detail.varianceStatus!.toUpperCase()),
                if (detail.lastSyncedAt != null)
                  _InfoRow('Last Synced', _fmtDate(detail.lastSyncedAt!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double? v) {
    if (v == null) return '—';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return const Color(0xFF059669);
      case 'completed': return const Color(0xFF2563EB);
      default: return const Color(0xFF9CA3AF);
    }
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProgressStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricCard(
      {required this.label,
        required this.value,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF111827))),
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6B7280))),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ITEMS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _ItemsTab extends StatelessWidget {
  final BoqDetail detail;
  const _ItemsTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    if (detail.isMechanical) {
      return _MechanicalItemsList(items: detail.mechanicalItems);
    } else {
      return _InsulationItemsList(items: detail.insulationItems);
    }
  }
}

class _MechanicalItemsList extends StatelessWidget {
  final List<MechanicalBoqItem> items;
  const _MechanicalItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items', style: TextStyle(color: Color(0xFF6B7280))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        final progress = item.progressPercentage.clamp(0.0, 100.0);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${item.srNo}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C3AED)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.matchedMaterialName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF111827)),
                    ),
                  ),
                  Text(
                    '${item.size}"',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF374151)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SmallChip(
                    label: item.uom == 'INCH_MTR' ? 'Inch Mtr' : 'Inch Dia',
                    value: _fmt(item.totalQuantityCalculated),
                  ),
                  const SizedBox(width: 8),
                  _SmallChip(
                    label: 'Done',
                    value: _fmt(item.completedQuantity),
                    highlight: true,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _progressColor(progress)),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _progressColor(progress)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  Color _progressColor(double p) {
    if (p >= 80) return const Color(0xFF059669);
    if (p >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _InsulationItemsList extends StatelessWidget {
  final List<InsulationBoqItem> items;
  const _InsulationItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items', style: TextStyle(color: Color(0xFF6B7280))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        final progress = item.progressPercentage.clamp(0.0, 100.0);
        final layerColor = _layerColor(item.layer);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: layerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.layer.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: layerColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.materialName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF111827)),
                    ),
                  ),
                  Text(
                    '${item.size}" × ${item.qty.toInt()}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF374151)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _SmallChip(
                      label: 'RMT',
                      value: item.calculatedRMT.toStringAsFixed(2)),
                  _SmallChip(
                      label: 'Area m²',
                      value: item.calculatedArea.toStringAsFixed(4)),
                  _SmallChip(
                      label: 'Cladding',
                      value: '${item.claddingMaterial} SWG${item.claddingSwg}'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${item.leggingMaterial1} ${item.leggingThickness1}mm'
                    '${item.leggingMaterial2 != null ? " + ${item.leggingMaterial2} ${item.leggingThickness2}mm" : ""}'
                    '${item.leggingMaterial3 != null ? " + ${item.leggingMaterial3} ${item.leggingThickness3}mm" : ""}',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _progressColor(progress)),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _progressColor(progress)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _layerColor(String layer) {
    switch (layer) {
      case 'double': return const Color(0xFF2563EB);
      case 'triple': return const Color(0xFF7C3AED);
      default: return const Color(0xFF059669);
    }
  }

  Color _progressColor(double p) {
    if (p >= 80) return const Color(0xFF059669);
    if (p >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _SmallChip(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF059669).withOpacity(0.08)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: highlight
                ? const Color(0xFF059669)
                : const Color(0xFF374151)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIMELINE TAB
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineTab extends StatelessWidget {
  final BoqProgress progress;
  const _TimelineTab({required this.progress});

  @override
  Widget build(BuildContext context) {
    if (progress.timeline == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timeline, size: 48, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            const Text('No timeline set',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151))),
            const SizedBox(height: 8),
            const Text('Timeline auto-updates from DPR entries',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    final timeline = progress.timeline!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle('Timeline'),
              const SizedBox(height: 10),
              _InfoRow('Start Date', timeline.startDate),
              _InfoRow('End Date', timeline.endDate),
              _InfoRow('Method',
                  timeline.distributionMethod.toUpperCase()),
              _InfoRow('Daily Targets',
                  '${timeline.dailyTargets.length} days'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionTitle('Daily Progress'),
        const SizedBox(height: 10),
        ...timeline.dailyTargets.map((day) => _DayTargetRow(day: day)),
      ],
    );
  }
}

class _DayTargetRow extends StatelessWidget {
  final BoqDailyTarget day;
  const _DayTargetRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(day.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              _fmtDate(day.date),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'T: ${day.targetQuantity.toStringAsFixed(1)}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF6B7280)),
                ),
                Text(
                  'C: ${day.completedQuantity.toStringAsFixed(1)}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${day.progressPercentage.toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: statusColor),
          ),
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return const Color(0xFF059669);
      case 'in_progress': return const Color(0xFFF59E0B);
      default: return const Color(0xFF9CA3AF);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Widget _SectionTitle(String title) => Text(
  title,
  style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Color(0xFF111827)),
);
//
// class _InfoRow extends StatelessWidget {
//   final String label;
//   final String value;
//   const _InfoRow(this.label, this.value);
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style: const TextStyle(
//                   fontSize: 13, color: Color(0xFF6B7280))),
//           Text(value,
//               style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: Color(0xFF111827))),
//         ],
//       ),
//     );
//   }
// }