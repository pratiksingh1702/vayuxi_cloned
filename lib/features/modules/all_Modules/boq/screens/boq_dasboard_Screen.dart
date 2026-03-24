import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/boq_model.dart';
import '../providers/boq_provider.dart';
import 'boq_Settings.dart';
import 'boq_add_screen.dart';
import 'boq_detail_screen.dart';


// ─────────────────────────────────────────────────────────────────────────────
// BOQ DASHBOARD SCREEN
// Entry point: receives siteId from navigation extras (as in your project)
// typeProvider (given by you) drives which sub-type is shown in ADD tab
// ─────────────────────────────────────────────────────────────────────────────

class BoqDashboardScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;

  const BoqDashboardScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  ConsumerState<BoqDashboardScreen> createState() => _BoqDashboardScreenState();
}

class _BoqDashboardScreenState extends ConsumerState<BoqDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Kick off the initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boqListParamsProvider.notifier).state = BoqListParams(
        siteId: widget.siteId,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BOQ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            Text(
              widget.siteName,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: const Color(0xFF2563EB),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'VIEW'),
                Tab(text: 'ADD'),
                Tab(text: 'SETTINGS'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BoqViewTab(siteId: widget.siteId),
          BoqAddScreen(siteId: widget.siteId),
          BoqSettingsScreen(siteId: widget.siteId),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW TAB
// ─────────────────────────────────────────────────────────────────────────────

class _BoqViewTab extends ConsumerStatefulWidget {
  final String siteId;
  const _BoqViewTab({required this.siteId});

  @override
  ConsumerState<_BoqViewTab> createState() => _BoqViewTabState();
}

class _BoqViewTabState extends ConsumerState<_BoqViewTab> {
  String? _filterStatus;

  static const _statusFilters = [
    (label: 'All', value: null),
    (label: 'Active', value: 'active'),
    (label: 'Draft', value: 'draft'),
    (label: 'Completed', value: 'completed'),
  ];

  void _applyFilter(String? status) {
    setState(() => _filterStatus = status);
    ref.read(boqListParamsProvider.notifier).state = BoqListParams(
      siteId: widget.siteId,
      status: status,
    );
  }

  @override
  Widget build(BuildContext context) {
    final params = ref.watch(boqListParamsProvider);
    final boqListAsync = params != null
        ? ref.watch(boqListProvider(params))
        : const AsyncValue<({List<BoqListItem> boqs, BoqPagination pagination})>.loading();

    return Column(
      children: [
        // ── Filter chips ─────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: _statusFilters.map((f) {
              final isActive = _filterStatus == f.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f.label),
                  selected: isActive,
                  onSelected: (_) => _applyFilter(f.value),
                  selectedColor: const Color(0xFF2563EB).withOpacity(0.12),
                  checkmarkColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(
                    color: isActive
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF6B7280),
                    fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isActive
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE5E7EB),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              );
            }).toList(),
          ),
        ),

        // ── BOQ List ─────────────────────────────────────────────────────────
        Expanded(
          child: boqListAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
            error: (e, _) => _ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(boqListProvider),
            ),
            data: (data) {
              if (data.boqs.isEmpty) {
                return _EmptyBoqView(siteId: widget.siteId);
              }
              return RefreshIndicator(
                color: const Color(0xFF2563EB),
                onRefresh: () async {
                  ref.invalidate(boqListProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: data.boqs.length,
                  itemBuilder: (ctx, i) => _BoqCard(
                    boq: data.boqs[i],
                    siteId: widget.siteId,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOQ CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BoqCard extends StatelessWidget {
  final BoqListItem boq;
  final String siteId;

  const _BoqCard({required this.boq, required this.siteId});

  @override
  Widget build(BuildContext context) {
    final progress = boq.progressPercentage.clamp(0, 100).toDouble();
    final statusColor = _statusColor(boq.status);
    final typeLabel =
    boq.isMechanical ? 'Mechanical' : 'Insulation';
    final typeColor =
    boq.isMechanical ? const Color(0xFF7C3AED) : const Color(0xFF0891B2);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BoqDetailScreen(
            siteId: siteId,
            boqId: boq.id,
            boqName: boq.boqName,
          ),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              boq.boqNumber,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              boq.boqName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _Badge(label: typeLabel, color: typeColor),
                          const SizedBox(height: 4),
                          _Badge(
                            label: boq.status.toUpperCase(),
                            color: statusColor,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Metrics row ───────────────────────────────────────────
                  Row(
                    children: [
                      if (boq.isMechanical) ...[
                        _MetricChip(
                          label: 'Inch Dia',
                          value: _fmt(boq.totalInchDia),
                        ),
                        const SizedBox(width: 8),
                        _MetricChip(
                          label: 'Inch Mtr',
                          value: _fmt(boq.totalInchMtr),
                        ),
                      ] else ...[
                        _MetricChip(
                          label: 'RMT',
                          value: _fmt(boq.totalRMT),
                        ),
                        const SizedBox(width: 8),
                        _MetricChip(
                          label: 'Area (m²)',
                          value: _fmt(boq.totalArea),
                        ),
                      ],
                      const Spacer(),
                      if (boq.totalItems != null)
                        Text(
                          '${boq.totalItems} items',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── Progress ──────────────────────────────────────────────
                  Row(
                    children: [
                      const Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${progress.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _progressColor(progress),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _progressColor(progress)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double? v) {
    if (v == null) return '—';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF059669);
      case 'completed':
        return const Color(0xFF2563EB);
      case 'draft':
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  Color _progressColor(double p) {
    if (p >= 80) return const Color(0xFF059669);
    if (p >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY / ERROR VIEWS
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyBoqView extends StatelessWidget {
  final String siteId;
  const _EmptyBoqView({required this.siteId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 48,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No BOQs yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first BOQ via the ADD tab',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          const Text(
            'Something went wrong',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}