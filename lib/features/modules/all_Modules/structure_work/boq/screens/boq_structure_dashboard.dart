import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../models/boq_structure_model.dart';
import '../providers/boq_structure_provider.dart';
import 'boq_detail_screen.dart';
import '../../../../../../core/utlis/widgets/premium_app_bar.dart';

const _kBrown = Color(0xFF7B3F00);

class BOQStructureDashboard extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;
  const BOQStructureDashboard(
      {super.key, required this.siteId, required this.siteName});

  @override
  ConsumerState<BOQStructureDashboard> createState() =>
      _BOQStructureDashboardState();
}

class _BOQStructureDashboardState extends ConsumerState<BOQStructureDashboard>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boqStructureProvider.notifier).fetchBOQs(widget.siteId);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(boqStructureProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!state.isLoading && state.boqs.isNotEmpty) {
      _staggerCtrl.forward();
    }

    return Scaffold(
      backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
      appBar: PremiumAppBar(
        title: 'Structure BOQ',
        subtitle: Text(widget.siteName),
        onDrawerPressed: () => context.pop(),
        drawerIcon: Icons.arrow_back_ios_new_rounded,
        actions: [
          PremiumActionIcon(
            icon: Icons.refresh_rounded,
            onPressed: () => ref
                .read(boqStructureProvider.notifier)
                .fetchBOQs(widget.siteId),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: _BOQShimmerList())
          : state.error != null && state.boqs.isEmpty
              ? _ErrorState(
                  message: state.error!,
                  onRetry: () => ref
                      .read(boqStructureProvider.notifier)
                      .fetchBOQs(widget.siteId),
                )
              : state.boqs.isEmpty
                  ? const _EmptyBOQState()
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 120),
                      children: [
                        _StatsRow(boqs: state.boqs),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: state.boqs.length,
                          itemBuilder: (ctx, i) {
                            final boq = state.boqs[i];
                            final delay = i * 0.12;
                            return AnimatedBuilder(
                              animation: _staggerCtrl,
                              builder: (_, child) {
                                final t = (((_staggerCtrl.value - delay) / 0.5)
                                    .clamp(0.0, 1.0));
                                return Opacity(
                                  opacity: t,
                                  child: Transform.translate(
                                    offset: Offset(0, 24 * (1 - t)),
                                    child: child,
                                  ),
                                );
                              },
                              child: _BOQCard(
                                boq: boq,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => BOQDetailScreen(
                                      boq: boq,
                                      siteId: widget.siteId,
                                    ),
                                  ));
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
      floatingActionButton: _UploadFAB(
        pulseCtrl: _pulseCtrl,
        isUploading: state.isUploading,
        onTap: () => _showUploadSheet(context),
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    PlatformFile? pickedFile;
    int step = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4))),
              const Text('Upload BOQ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Excel files only (.xlsx, .xls)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 18),
              _UploadJourneyHeader(
                currentStep: step,
                steps: const ['Select File', 'Review', 'Upload'],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['xlsx', 'xls'],
                    withData: true,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    setLocal(() {
                      pickedFile = result.files.first;
                      step = 1;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: pickedFile != null
                        ? _kBrown.withOpacity(0.08)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          pickedFile != null ? _kBrown : Colors.grey.shade300,
                      width: pickedFile != null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pickedFile != null
                            ? Icons.check_circle_rounded
                            : Icons.upload_file_rounded,
                        color:
                            pickedFile != null ? _kBrown : Colors.grey.shade500,
                        size: 32,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pickedFile != null
                                  ? pickedFile!.name
                                  : 'Tap to select Excel file',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: pickedFile != null
                                    ? _kBrown
                                    : Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (pickedFile != null)
                              Text(
                                '${((pickedFile!.size) / 1024).toStringAsFixed(1)} KB',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (pickedFile != null) ...[
                const SizedBox(height: 14),
                _UploadReviewCard(
                  title: 'Ready for BOQ validation',
                  description:
                      'The selected Excel file will be sent through the existing BOQ upload process. Quantity splitting and backend validation will run as usual.',
                  rows: [
                    ('File', pickedFile!.name),
                    (
                      'Size',
                      '${(pickedFile!.size / 1024).toStringAsFixed(1)} KB'
                    ),
                    ('Format', pickedFile!.extension?.toUpperCase() ?? 'Excel'),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: pickedFile == null
                      ? null
                      : () async {
                          setLocal(() => step = 2);
                          Navigator.pop(sheetCtx);
                          final ok = await ref
                              .read(boqStructureProvider.notifier)
                              .uploadBOQ(widget.siteId, pickedFile!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(children: [
                                  Icon(
                                      ok
                                          ? Icons.check_circle_rounded
                                          : Icons.error_rounded,
                                      color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text(ok
                                      ? 'BOQ uploaded successfully!'
                                      : (ref.read(boqStructureProvider).error ??
                                          'Upload failed')),
                                ]),
                                backgroundColor: ok ? Colors.green : Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                  child: Text(
                      pickedFile == null
                          ? 'Select File First'
                          : 'Confirm & Upload BOQ',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadJourneyHeader extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const _UploadJourneyHeader({
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final lineIndex = index ~/ 2;
          final isDone = lineIndex < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              color: isDone ? _kBrown : cs.outlineVariant,
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isDone = stepIndex < currentStep;
        final isActive = stepIndex == currentStep;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color:
                    isDone || isActive ? _kBrown : cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check_rounded : Icons.circle,
                size: isDone ? 18 : 9,
                color: isDone || isActive ? Colors.white : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 72,
              child: Text(
                steps[stepIndex],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive ? _kBrown : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _UploadReviewCard extends StatelessWidget {
  final String title;
  final String description;
  final List<(String, String)> rows;

  const _UploadReviewCard({
    required this.title,
    required this.description,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kBrown.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBrown.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_rounded, color: _kBrown, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 62,
                    child: Text(
                      row.$1,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upload FAB ──────────────────────────────────────────────────────────────
class _UploadFAB extends StatelessWidget {
  final AnimationController pulseCtrl;
  final bool isUploading;
  final VoidCallback onTap;
  const _UploadFAB(
      {required this.pulseCtrl,
      required this.isUploading,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, __) => FloatingActionButton.extended(
        onPressed: isUploading ? null : onTap,
        backgroundColor: _kBrown,
        elevation: 6 + pulseCtrl.value * 4,
        icon: isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.upload_rounded, color: Colors.white),
        label: Text(
          isUploading ? 'Uploading…' : 'Upload BOQ',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Stats Row ───────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<BOQStructure> boqs;
  const _StatsRow({required this.boqs});

  @override
  Widget build(BuildContext context) {
    final totalItems = boqs.fold<int>(0, (s, b) => s + b.totalItems);
    final totalWeight = boqs.fold<double>(0, (s, b) => s + b.totalNetWeight);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _StatChip(label: 'BOQs', value: '${boqs.length}', cs: cs),
          const SizedBox(width: 10),
          _StatChip(label: 'Items', value: '$totalItems', cs: cs),
          const SizedBox(width: 10),
          _StatChip(
              label: 'Weight (MT)',
              value: (totalWeight / 1000).toStringAsFixed(2),
              cs: cs),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  const _StatChip({required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _kBrown.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBrown.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: _kBrown)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── BOQ Card ────────────────────────────────────────────────────────────────
class _BOQCard extends StatelessWidget {
  final BOQStructure boq;
  final VoidCallback onTap;
  const _BOQCard({required this.boq, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (boq.progressPercentage / 100).clamp(0.0, 1.0);
    final progressColor = boq.progressPercentage > 50
        ? Colors.green.shade600
        : boq.progressPercentage > 20
            ? Colors.amber.shade600
            : Colors.red.shade400;

    final statusColor = boq.status == 'active'
        ? Colors.green
        : boq.status == 'completed'
            ? Colors.blue
            : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(boq.boqName,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(boq.boqNumber,
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    boq.status.toUpperCase(),
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress
            Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: v,
                          backgroundColor: cs.outlineVariant.withOpacity(0.3),
                          color: progressColor,
                          strokeWidth: 5,
                          strokeCap: StrokeCap.round,
                        ),
                        Text(
                          '${boq.progressPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: progressColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _MiniStat(
                          label: 'Total Qty',
                          value: boq.totalQuantity.toStringAsFixed(0),
                          cs: cs),
                      const SizedBox(height: 6),
                      _MiniStat(
                          label: 'Used Qty',
                          value: boq.usedQuantity.toStringAsFixed(0),
                          cs: cs),
                      const SizedBox(height: 6),
                      _MiniStat(
                          label: 'Remaining',
                          value: boq.remainingQuantity.toStringAsFixed(0),
                          cs: cs,
                          highlight: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Footer
            Row(
              children: [
                Icon(Icons.fitness_center_rounded,
                    size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${(boq.totalNetWeight / 1000).toStringAsFixed(2)} MT',
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: cs.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final bool highlight;
  const _MiniStat(
      {required this.label,
      required this.value,
      required this.cs,
      this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: highlight ? _kBrown : cs.onSurface)),
      ],
    );
  }
}

// ── Shimmer Loading ─────────────────────────────────────────────────────────
class _BOQShimmerList extends StatelessWidget {
  const _BOQShimmerList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 160,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const _ShimmerPulse(),
      ),
    );
  }
}

class _ShimmerPulse extends StatefulWidget {
  const _ShimmerPulse();
  @override
  State<_ShimmerPulse> createState() => _ShimmerPulseState();
}

class _ShimmerPulseState extends State<_ShimmerPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.grey.withOpacity(0.08 + _ctrl.value * 0.08),
        ),
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────────────────
class _EmptyBOQState extends StatelessWidget {
  const _EmptyBOQState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _kBrown.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.table_rows_rounded,
                  size: 44, color: _kBrown),
            ),
            const SizedBox(height: 20),
            const Text('No BOQs Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Upload your first Bill of Quantities\nto start tracking structure progress.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ─────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 52, color: cs.error),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.error)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kBrown, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
