import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/boq_structure_model.dart';
import '../providers/boq_structure_provider.dart';

const _kBrown = Color(0xFF7B3F00);

class BOQDetailScreen extends ConsumerStatefulWidget {
  final BOQStructure boq;
  final String siteId;
  const BOQDetailScreen(
      {super.key, required this.boq, required this.siteId});

  @override
  ConsumerState<BOQDetailScreen> createState() => _BOQDetailScreenState();
}

class _BOQDetailScreenState extends ConsumerState<BOQDetailScreen> {
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  BOQStructure? _detail;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _detail = widget.boq;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(boqStructureRepositoryProvider);
      final d = await repo.getBOQDetail(widget.siteId, widget.boq.id);
      if (mounted) setState(() { _detail = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = (_detail?.items ?? widget.boq.items)
        .where((it) => it.assemblyMark
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) => b.remainingQty.compareTo(a.remainingQty));

    return Scaffold(
      backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: _kBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.boq.boqName,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: Colors.white)),
            Text(widget.boq.boqNumber,
                style: const TextStyle(
                    fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          _SummaryCard(boq: _detail ?? widget.boq),
          // Search
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search assembly mark…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: cs.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _kBrown))
                : items.isEmpty
                    ? Center(
                        child: Text('No items found',
                            style: TextStyle(
                                color: cs.onSurfaceVariant)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (_, i) =>
                            _BOQItemCard(item: items[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BOQStructure boq;
  const _SummaryCard({required this.boq});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (boq.progressPercentage / 100).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kBrown.withOpacity(0.12), _kBrown.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBrown.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoCol(
                  label: 'Total Items',
                  value: '${boq.totalItems}',
                  cs: cs),
              _InfoCol(
                  label: 'Total Qty',
                  value: boq.totalQuantity.toStringAsFixed(0),
                  cs: cs),
              _InfoCol(
                  label: 'Weight (MT)',
                  value:
                      (boq.totalNetWeight / 1000).toStringAsFixed(2),
                  cs: cs),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (_, v, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Overall Progress',
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                    Text('${boq.progressPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _kBrown)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    color: _kBrown,
                    backgroundColor: _kBrown.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCol extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  const _InfoCol(
      {required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _kBrown)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _BOQItemCard extends StatefulWidget {
  final BOQStructureItem item;
  const _BOQItemCard({required this.item});

  @override
  State<_BOQItemCard> createState() => _BOQItemCardState();
}

class _BOQItemCardState extends State<_BOQItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = widget.item;
    final progress = (item.progressPercentage / 100).clamp(0.0, 1.0);
    final pColor = item.progressPercentage > 50
        ? Colors.green.shade600
        : item.progressPercentage > 20
            ? Colors.amber.shade600
            : Colors.red.shade400;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: cs.outlineVariant.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.assemblyMark,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                      '${item.progressPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: pColor)),
                ),
                const SizedBox(width: 6),
                Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ItemStat(
                    label: 'Qty',
                    value: item.quantity.toStringAsFixed(0),
                    cs: cs),
                _ItemStat(
                    label: 'Used',
                    value: item.usedQty.toStringAsFixed(0),
                    cs: cs),
                _ItemStat(
                    label: 'Remaining',
                    value: item.remainingQty.toStringAsFixed(0),
                    cs: cs,
                    highlight: true),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              if (item.length != null || item.width != null || item.height != null)
                Row(
                  children: [
                    if (item.length != null)
                      _DimChip(label: 'L', value: '${item.length}m'),
                    if (item.width != null)
                      _DimChip(label: 'W', value: '${item.width}m'),
                    if (item.height != null)
                      _DimChip(label: 'H', value: '${item.height}m'),
                  ],
                ),
              if (item.netWeightPerUnit != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Weight/unit: ${item.netWeightPerUnit} kg  •  Total: ${(item.totalNetWeight ?? 0).toStringAsFixed(1)} kg',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemStat extends StatelessWidget {
  final String label, value;
  final ColorScheme cs;
  final bool highlight;
  const _ItemStat(
      {required this.label,
      required this.value,
      required this.cs,
      this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: highlight ? _kBrown : cs.onSurface)),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _DimChip extends StatelessWidget {
  final String label, value;
  const _DimChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kBrown.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value',
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kBrown)),
    );
  }
}
