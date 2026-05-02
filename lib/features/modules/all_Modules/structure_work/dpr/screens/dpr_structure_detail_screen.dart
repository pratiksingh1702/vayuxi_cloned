import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/utlis/widgets/premium_app_bar.dart';
import '../models/dpr_structure_model.dart';
import '../providers/dpr_structure_provider.dart';
import 'dpr_structure_create_screen.dart';

const _kBrown = Color(0xFF7B3F00);

class DprStructureDetailScreen extends ConsumerStatefulWidget {
  final String dprId;
  final String siteId;
  final DPRStructure? dpr;

  const DprStructureDetailScreen({
    super.key,
    required this.dprId,
    required this.siteId,
    this.dpr,
  });

  @override
  ConsumerState<DprStructureDetailScreen> createState() =>
      _DprStructureDetailScreenState();
}

class _DprStructureDetailScreenState
    extends ConsumerState<DprStructureDetailScreen> {
  DPRStructure? _dpr;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _dpr = widget.dpr;
    if (_dpr == null) _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(dprStructureRepositoryProvider);
      final d = await repo.getDPRDetail(widget.siteId, widget.dprId);
      if (mounted) setState(() { _dpr = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dpr = _dpr;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: PremiumAppBar(
        title: dpr?.dprName ?? 'DPR Detail',
        onDrawerPressed: () => context.pop(),
        drawerIcon: Icons.arrow_back_ios_new_rounded,
        actions: [
          if (dpr != null)
            PremiumActionIcon(
              icon: Icons.delete_outline_rounded,
              onPressed: () => _confirmDelete(dpr),
              iconColor: cs.error,
            ),
        ],
      ),
      body: _loading
          ? const _LoadingState()
          : dpr == null
              ? _ErrorState(onRetry: _fetchDetail)
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _DetailedHeader(dpr: dpr, cs: cs),
                      const SizedBox(height: 24),
                      _ContextCard(dpr: dpr, cs: cs),
                      const SizedBox(height: 24),
                      _MaterialBreakdownTable(dpr: dpr, cs: cs),
                    ],
                  ),
                ),
    );
  }

  Future<void> _confirmDelete(DPRStructure dpr) async {
    final cs = Theme.of(context).colorScheme;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (b) => _DeleteConfirmSheet(dpr: dpr, cs: cs),
    );

    if (ok == true && mounted) {
      HapticFeedback.heavyImpact();
      final success = await ref
          .read(dprStructureProvider.notifier)
          .deleteDPR(widget.siteId, dpr.id);
      if (success && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('DPR entry has been deleted'),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Components ────────────────────────────────────────────────────────────────

class _DetailedHeader extends StatelessWidget {
  final DPRStructure dpr;
  final ColorScheme cs;
  const _DetailedHeader({required this.dpr, required this.cs});

  @override
  Widget build(BuildContext context) {
    final statusColor = dpr.status == 'approved'
        ? Colors.green
        : dpr.status == 'rejected'
            ? Colors.red
            : Colors.amber.shade700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kBrown,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: _kBrown.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(dpr.status.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(dpr.date ?? DateTime.now()),
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(dpr.dprName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          Text(dpr.dprNumber,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeaderStat(
                  label: 'Total Reporting',
                  value: dpr.totalQtyUsed.toStringAsFixed(0),
                  unit: 'Qty'),
              Container(width: 1, height: 30, color: Colors.white24),
              _HeaderStat(
                  label: 'Net Tonnage',
                  value: (dpr.totalNetWeight / 1000).toStringAsFixed(2),
                  unit: 'MT'),
              Container(width: 1, height: 30, color: Colors.white24),
              _HeaderStat(
                  label: 'Unique Marks',
                  value: '${dpr.items.length}',
                  unit: 'Items'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label, value, unit;
  const _HeaderStat({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(),
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5)),
      ],
    );
  }
}

class _ContextCard extends StatelessWidget {
  final DPRStructure dpr;
  final ColorScheme cs;
  const _ContextCard({required this.dpr, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ContextRow(
            icon: Icons.table_chart_outlined,
            label: 'Reference BOQ',
            value: dpr.boqName ?? '—',
            cs: cs,
          ),
          if (dpr.remarks != null && dpr.remarks!.isNotEmpty) ...[
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1)),
            _ContextRow(
              icon: Icons.notes_rounded,
              label: 'Site Remarks',
              value: dpr.remarks!,
              cs: cs,
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final ColorScheme cs;
  const _ContextRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _kBrown.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _kBrown, size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MaterialBreakdownTable extends StatelessWidget {
  final DPRStructure dpr;
  final ColorScheme cs;
  const _MaterialBreakdownTable({required this.dpr, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                  color: _kBrown, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            const Text('Progress Breakdown',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                color: cs.surfaceContainerHigh,
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('ASSEMBLY MARK',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurfaceVariant,
                                letterSpacing: 0.5))),
                    Expanded(
                        child: Text('QTY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurfaceVariant,
                                letterSpacing: 0.5))),
                    Expanded(
                        child: Text('WEIGHT',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurfaceVariant,
                                letterSpacing: 0.5))),
                  ],
                ),
              ),
              ...dpr.items.map((it) => _BreakdownRow(item: it, cs: cs)),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kBrown.withOpacity(0.06),
                  border: Border(
                      top: BorderSide(color: cs.outlineVariant.withOpacity(0.5))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL SESSION PROGRESS',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w900)),
                    Text(
                      '${dpr.totalQtyUsed.toStringAsFixed(0)} Qty',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _kBrown),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final DPRStructureItem item;
  final ColorScheme cs;
  const _BreakdownRow({required this.item, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(item.assemblyMark,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          Expanded(
            child: Text(item.qtyUsed.toStringAsFixed(0),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 15, color: _kBrown)),
          ),
          Expanded(
            child: Text(
              item.totalNetWeight != null
                  ? '${(item.totalNetWeight! / 1000).toStringAsFixed(2)} mt'
                  : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteConfirmSheet extends StatelessWidget {
  final DPRStructure dpr;
  final ColorScheme cs;
  const _DeleteConfirmSheet({required this.dpr, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.errorContainer.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delete_sweep_rounded, color: cs.error, size: 48),
          ),
          const SizedBox(height: 24),
          const Text('Delete DPR Entry?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(
            'This action will permanently remove this reporting entry and restore ${dpr.totalQtyUsed.toStringAsFixed(0)} units back to the BOQ availability.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, color: cs.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Delete Permanently',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Center(
        child: CircularProgressIndicator(color: _kBrown, strokeWidth: 3));
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('Oops! Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('We couldn\'t load the DPR details.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBrown,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Retry Fetching',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

