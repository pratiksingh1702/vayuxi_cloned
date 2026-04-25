import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/core/local/isar_db.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/data/constants/material_constants.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/data/local/cached_image.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/data/local/local_material.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/data/repo/material_repo_provider.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/mech/isar/dpr_work.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/mech/isar/outbox.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/mech/isar/rate_file_isar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/mech/isar/sync_meta_isar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/mech/repo/rate_Repo.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';

final dprOfflineDashboardProvider = StreamProvider.autoDispose
    .family<DprOfflineDashboardData, String?>((ref, siteId) {
  return watchDprOfflineDashboard(siteId);
});

Stream<DprOfflineDashboardData> watchDprOfflineDashboard(
    String? siteId) async* {
  final isar = AppIsarDB.isar;

  Future<DprOfflineDashboardData> loadSnapshot() async {
    final localMaterials =
        await isar.localMaterials.filter().siteIdIsNotEmpty().findAll();
    final cachedImages =
        await isar.cachedImages.filter().serverUrlIsNotEmpty().findAll();
    final rateAnalyses =
        await isar.rateFileAnalysisIsars.filter().siteIdIsNotEmpty().findAll();
    final rateMaterials =
        await isar.rateFileMaterialIsars.filter().siteIdIsNotEmpty().findAll();
    final rateVariants =
        await isar.rateVariantIsars.filter().siteIdIsNotEmpty().findAll();
    final dprWorks = await isar.dprIsars.filter().siteIdIsNotEmpty().findAll();
    final outbox = await isar.outboxIsars.filter().siteIdIsNotEmpty().findAll();
    final syncMeta =
        await isar.syncMetaIsars.filter().keyIsNotEmpty().findAll();

    final scopedMaterials =
        _filterBySite(localMaterials, (m) => m.siteId, siteId);
    final scopedRateAnalyses =
        _filterBySite(rateAnalyses, (m) => m.siteId, siteId);
    final scopedRateMaterials =
        _filterBySite(rateMaterials, (m) => m.siteId, siteId);
    final scopedRateVariants =
        _filterBySite(rateVariants, (m) => m.siteId, siteId);
    final scopedDprWorks = _filterBySite(dprWorks, (m) => m.siteId, siteId);
    final scopedOutbox = _filterBySite(outbox, (m) => m.siteId, siteId);

    final insulationMaterials = scopedMaterials
        .where((m) => m.domain == MaterialDomain.insulation.key && !m.isDeleted)
        .toList();

    final insulationPiping = insulationMaterials
        .where((m) =>
            m.designation.toLowerCase() == MaterialDesignation.piping.key)
        .length;
    final insulationEquipment = insulationMaterials
        .where((m) =>
            m.designation.toLowerCase() == MaterialDesignation.equipment.key)
        .length;

    final dirtyMaterials = insulationMaterials.where((m) => m.isDirty).length;
    final cardStatesSaved = insulationMaterials
        .where((m) => (m.cardFormStateJson ?? '').trim().isNotEmpty)
        .length;

    final latestRateAnalysis = scopedRateAnalyses.isEmpty
        ? null
        : (scopedRateAnalyses.toList()
              ..sort((a, b) => b.syncedAt.compareTo(a.syncedAt)))
            .first;

    final detectedSnapshot = _extractDetectedFieldSnapshot(
      latestRateAnalysis?.detectedFieldsJson,
    );

    final mechanicalWorks = scopedDprWorks
        .where((w) => w.workType == 'mechanical_work' && !w.isDeleted)
        .toList();
    final insulationWorks = scopedDprWorks
        .where((w) => w.workType == 'insulation_work' && !w.isDeleted)
        .toList();

    final unsyncedMechanical = mechanicalWorks.where((w) => !w.isSynced).length;
    final unsyncedInsulation = insulationWorks.where((w) => !w.isSynced).length;

    final pendingOutbox = scopedOutbox.where((o) => !o.isDone).length;
    final outboxFailed = scopedOutbox
        .where((o) => !o.isDone && (o.error ?? '').isNotEmpty)
        .length;

    final syncKeys = syncMeta.map((s) => s.key).toList()..sort();
    DateTime? lastSyncAt;
    for (final meta in syncMeta) {
      if (lastSyncAt == null || meta.lastSyncAt.isAfter(lastSyncAt)) {
        lastSyncAt = meta.lastSyncAt;
      }
    }

    final draftStats = await _readDraftStats();

    return DprOfflineDashboardData(
      siteId: siteId,
      insulationMaterials: insulationMaterials.length,
      insulationPiping: insulationPiping,
      insulationEquipment: insulationEquipment,
      insulationDirty: dirtyMaterials,
      insulationWithCardState: cardStatesSaved,
      cachedImages: cachedImages.length,
      rateFileAnalyses: scopedRateAnalyses.length,
      rateMaterials: scopedRateMaterials.length,
      rateVariants: scopedRateVariants.length,
      lastRateSyncAt: latestRateAnalysis?.syncedAt,
      latestRateFileName: latestRateAnalysis?.fileName,
      latestRateStatus: latestRateAnalysis?.status,
      detectedFieldSnapshot: detectedSnapshot,
      mechanicalDprRecords: mechanicalWorks.length,
      insulationDprRecords: insulationWorks.length,
      unsyncedMechanicalDpr: unsyncedMechanical,
      unsyncedInsulationDpr: unsyncedInsulation,
      outboxPending: pendingOutbox,
      outboxFailed: outboxFailed,
      syncMetaEntries: syncMeta.length,
      syncKeys: syncKeys,
      lastGlobalSyncAt: lastSyncAt,
      mechanicalDrafts: draftStats.mechanicalDrafts,
      insulationDrafts: draftStats.insulationDrafts,
      expiredDrafts: draftStats.expiredDrafts,
      totalDraftEntries: draftStats.totalEntries,
    );
  }

  yield await loadSnapshot();

  final trigger = StreamController<void>();

  final subs = <StreamSubscription<dynamic>>[
    isar.localMaterials.watchLazy().listen((_) => trigger.add(null)),
    isar.cachedImages.watchLazy().listen((_) => trigger.add(null)),
    isar.rateFileAnalysisIsars.watchLazy().listen((_) => trigger.add(null)),
    isar.rateFileMaterialIsars.watchLazy().listen((_) => trigger.add(null)),
    isar.rateVariantIsars.watchLazy().listen((_) => trigger.add(null)),
    isar.dprIsars.watchLazy().listen((_) => trigger.add(null)),
    isar.outboxIsars.watchLazy().listen((_) => trigger.add(null)),
    isar.syncMetaIsars.watchLazy().listen((_) => trigger.add(null)),
  ];

  final timer = Timer.periodic(const Duration(seconds: 20), (_) {
    trigger.add(null);
  });

  try {
    await for (final _ in trigger.stream) {
      yield await loadSnapshot();
    }
  } finally {
    timer.cancel();
    for (final sub in subs) {
      await sub.cancel();
    }
    await trigger.close();
  }
}

class DprOfflineDashboardScreen extends ConsumerStatefulWidget {
  const DprOfflineDashboardScreen({super.key});

  @override
  ConsumerState<DprOfflineDashboardScreen> createState() =>
      _DprOfflineDashboardScreenState();
}

class _DprOfflineDashboardScreenState
    extends ConsumerState<DprOfflineDashboardScreen> {
  bool _syncingMaterials = false;
  bool _syncingRate = false;

  Future<void> _syncMaterials(String? siteId) async {
    if (siteId == null || siteId.isEmpty) {
      _showSnack('Please select a site first.');
      return;
    }

    setState(() => _syncingMaterials = true);
    try {
      await ref.read(materialRepositoryProvider).sync(
            siteId: siteId,
            domain: MaterialDomain.insulation.key,
            designation: '',
          );
      _showSnack('Materials synced successfully.');
    } catch (e) {
      _showSnack('Material sync failed: $e');
    } finally {
      if (mounted) {
        setState(() => _syncingMaterials = false);
      }
    }
  }

  Future<void> _syncRate(String? siteId) async {
    if (siteId == null || siteId.isEmpty) {
      _showSnack('Please select a site first.');
      return;
    }

    setState(() => _syncingRate = true);
    try {
      final repo = RateRepository(AppIsarDB.isar);
      await repo.syncRateFile(siteId);
      _showSnack('Rate file synced successfully.');
    } catch (e) {
      _showSnack('Rate file sync failed: $e');
    } finally {
      if (mounted) {
        setState(() => _syncingRate = false);
      }
    }
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentSite = ref.watch(currentSiteProvider);
    final selectedSiteId = currentSite?.id;
    final dashboard = ref.watch(dprOfflineDashboardProvider(selectedSiteId));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('DPR Offline Dashboard'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surface,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(dprOfflineDashboardProvider(selectedSiteId));
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Could not load dashboard.\n$error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        data: (data) {
          final health = _deriveHealth(data);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
            children: [
              _HeroStatusCard(
                siteName: currentSite?.siteName,
                siteId: selectedSiteId,
                health: health,
                pendingWorkCount: data.outboxPending +
                    data.insulationDirty +
                    data.unsyncedMechanicalDpr +
                    data.unsyncedInsulationDpr,
              ),
              const SizedBox(height: 14),
              _ActionBar(
                syncingMaterials: _syncingMaterials,
                syncingRate: _syncingRate,
                onSyncMaterials: () => _syncMaterials(selectedSiteId),
                onSyncRate: () => _syncRate(selectedSiteId),
              ),
              const SizedBox(height: 14),
              _SectionHeader(
                title: 'Storage Summary',
                subtitle: 'Live numbers from local storage',
                icon: Icons.storage_rounded,
              ),
              const SizedBox(height: 8),
              _MetricGrid(
                metrics: [
                  _MetricCardData(
                    label: 'Insulation Materials',
                    value: data.insulationMaterials.toString(),
                    helper:
                        '${data.insulationPiping} piping, ${data.insulationEquipment} equipment',
                    icon: Icons.inventory_2_rounded,
                    accent: const Color(0xFF1F6EA0),
                  ),
                  _MetricCardData(
                    label: 'Dirty Materials',
                    value: data.insulationDirty.toString(),
                    helper: 'Not yet sent to server',
                    icon: Icons.sync_problem_rounded,
                    accent: data.insulationDirty > 0
                        ? const Color(0xFFB45309)
                        : const Color(0xFF1E824C),
                  ),
                  _MetricCardData(
                    label: 'Saved Form Cards',
                    value: data.insulationWithCardState.toString(),
                    helper: 'Saved form data per card',
                    icon: Icons.auto_awesome_motion_rounded,
                    accent: const Color(0xFF6C47B6),
                  ),
                  _MetricCardData(
                    label: 'Cached Images',
                    value: data.cachedImages.toString(),
                    helper: 'Images saved on this device',
                    icon: Icons.image_rounded,
                    accent: const Color(0xFF0B7A75),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionHeader(
                title: 'Work + Upload Status',
                subtitle: 'DPR records, upload queue, and drafts',
                icon: Icons.engineering_rounded,
              ),
              const SizedBox(height: 8),
              _MetricGrid(
                metrics: [
                  _MetricCardData(
                    label: 'Mechanical DPR Records',
                    value: data.mechanicalDprRecords.toString(),
                    helper: '${data.unsyncedMechanicalDpr} not synced',
                    icon: Icons.precision_manufacturing_rounded,
                    accent: const Color(0xFF3454D1),
                  ),
                  _MetricCardData(
                    label: 'Insulation DPR Records',
                    value: data.insulationDprRecords.toString(),
                    helper: '${data.unsyncedInsulationDpr} not synced',
                    icon: Icons.layers_rounded,
                    accent: const Color(0xFF2F7E5D),
                  ),
                  _MetricCardData(
                    label: 'Pending Uploads',
                    value: data.outboxPending.toString(),
                    helper: '${data.outboxFailed} failed',
                    icon: Icons.outbox_rounded,
                    accent: data.outboxPending > 0
                        ? const Color(0xFFB42318)
                        : const Color(0xFF1E824C),
                  ),
                  _MetricCardData(
                    label: 'Saved Drafts',
                    value: data.totalDraftEntries.toString(),
                    helper:
                        '${data.mechanicalDrafts} mech, ${data.insulationDrafts} insulation, ${data.expiredDrafts} expired',
                    icon: Icons.drafts_rounded,
                    accent: const Color(0xFF805AD5),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionHeader(
                title: 'Rate File Summary',
                subtitle: 'Rate file data used by mechanical DPR',
                icon: Icons.analytics_rounded,
              ),
              const SizedBox(height: 8),
              _RateAnalysisPanel(data: data),
              const SizedBox(height: 14),
              _SectionHeader(
                title: 'How Data Moves',
                subtitle: 'How data moves from server to local save and upload',
                icon: Icons.account_tree_rounded,
              ),
              const SizedBox(height: 8),
              _ArchitectureTimeline(
                  syncKeys: data.syncKeys, lastSyncAt: data.lastGlobalSyncAt),
            ],
          );
        },
      ),
    );
  }

  _HealthStatus _deriveHealth(DprOfflineDashboardData data) {
    final pending = data.outboxPending +
        data.insulationDirty +
        data.unsyncedMechanicalDpr +
        data.unsyncedInsulationDpr;

    if (pending == 0 && data.outboxFailed == 0) {
      return _HealthStatus.healthy;
    }
    if (data.outboxFailed > 0 || pending > 20) {
      return _HealthStatus.needsAttention;
    }
    return _HealthStatus.warning;
  }
}

class _HeroStatusCard extends StatelessWidget {
  const _HeroStatusCard({
    required this.siteName,
    required this.siteId,
    required this.health,
    required this.pendingWorkCount,
  });

  final String? siteName;
  final String? siteId;
  final _HealthStatus health;
  final int pendingWorkCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tone = _healthTone(health);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.withOpacity(0.22),
            colorScheme.surfaceContainerLow,
          ],
        ),
        border: Border.all(color: tone.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tone.withOpacity(0.18),
                ),
                child: Icon(_healthIcon(health), color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _healthTitle(health),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pendingWorkCount == 0
                          ? 'Everything is up to date for offline work.'
                          : '$pendingWorkCount items are waiting to sync.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipLabel(
                label: siteName?.trim().isNotEmpty == true
                    ? 'Site: ${siteName!.trim()}'
                    : 'Site: Not selected',
              ),
              _ChipLabel(
                label: siteId?.trim().isNotEmpty == true
                    ? 'Site ID: ${siteId!.trim()}'
                    : 'No site selected',
              ),
              _ChipLabel(label: 'Scope: Insulation + Mechanical DPR'),
            ],
          ),
        ],
      ),
    );
  }

  Color _healthTone(_HealthStatus status) {
    switch (status) {
      case _HealthStatus.healthy:
        return const Color(0xFF1E824C);
      case _HealthStatus.warning:
        return const Color(0xFFB45309);
      case _HealthStatus.needsAttention:
        return const Color(0xFFB42318);
    }
  }

  IconData _healthIcon(_HealthStatus status) {
    switch (status) {
      case _HealthStatus.healthy:
        return Icons.verified_rounded;
      case _HealthStatus.warning:
        return Icons.warning_amber_rounded;
      case _HealthStatus.needsAttention:
        return Icons.error_outline_rounded;
    }
  }

  String _healthTitle(_HealthStatus status) {
    switch (status) {
      case _HealthStatus.healthy:
        return 'Offline Status: Good';
      case _HealthStatus.warning:
        return 'Offline Sync: In Progress';
      case _HealthStatus.needsAttention:
        return 'Offline Sync: Needs Attention';
    }
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.syncingMaterials,
    required this.syncingRate,
    required this.onSyncMaterials,
    required this.onSyncRate,
  });

  final bool syncingMaterials;
  final bool syncingRate;
  final VoidCallback onSyncMaterials;
  final VoidCallback onSyncRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: syncingMaterials ? null : onSyncMaterials,
            icon: syncingMaterials
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            label: Text(syncingMaterials
                ? 'Syncing Materials...'
                : 'Sync Materials Now'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: syncingRate ? null : onSyncRate,
            icon: syncingRate
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.analytics_rounded),
            label:
                Text(syncingRate ? 'Syncing Rate File...' : 'Sync Rate File'),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricCardData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 740;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: isWide
                    ? (constraints.maxWidth - 10) / 2
                    : constraints.maxWidth,
                child: _MetricCard(data: metric),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color accent;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricCardData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: data.accent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.helper,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
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

class _RateAnalysisPanel extends StatelessWidget {
  const _RateAnalysisPanel({required this.data});

  final DprOfflineDashboardData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.latestRateFileName?.trim().isNotEmpty == true
                ? data.latestRateFileName!
                : 'No rate file saved for this site yet',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Status: ${data.latestRateStatus ?? 'N/A'} | Last sync: ${_formatDate(data.lastRateSyncAt)}',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipLabel(label: 'Files ${data.rateFileAnalyses}'),
              _ChipLabel(label: 'Materials ${data.rateMaterials}'),
              _ChipLabel(label: 'Variants ${data.rateVariants}'),
              _ChipLabel(
                  label: 'Floors ${data.detectedFieldSnapshot.floorsCount}'),
              _ChipLabel(label: 'MOC ${data.detectedFieldSnapshot.mocsCount}'),
              _ChipLabel(
                  label: 'Sizes ${data.detectedFieldSnapshot.sizesCount}'),
              _ChipLabel(label: 'UOMs ${data.detectedFieldSnapshot.uomCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArchitectureTimeline extends StatelessWidget {
  const _ArchitectureTimeline({
    required this.syncKeys,
    required this.lastSyncAt,
  });

  final List<String> syncKeys;
  final DateTime? lastSyncAt;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final nodes = <_ArchitectureNode>[
      const _ArchitectureNode(
        title: '1) Data from Server',
        subtitle:
            'Material data and rate-file data are downloaded from the server.',
        icon: Icons.cloud_download_rounded,
      ),
      const _ArchitectureNode(
        title: '2) Sync Services',
        subtitle: 'Sync services convert server data into local records.',
        icon: Icons.sync_alt_rounded,
      ),
      const _ArchitectureNode(
        title: '3) Local Storage',
        subtitle:
            'Data is saved in Isar collections for materials, images, rate data, DPR, and uploads.',
        icon: Icons.storage_rounded,
      ),
      const _ArchitectureNode(
        title: '4) Draft and Upload',
        subtitle:
            'Drafts are kept locally and upload manager retries failed uploads.',
        icon: Icons.upload_rounded,
      ),
      const _ArchitectureNode(
        title: '5) Dashboard View',
        subtitle:
            'Dashboard first shows local data, then updates in background when online.',
        icon: Icons.dashboard_customize_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < nodes.length; i++)
            _TimelineRow(
              node: nodes[i],
              isLast: i == nodes.length - 1,
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Last overall sync update: ${_formatDate(lastSyncAt)}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (syncKeys.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sync tags: ${syncKeys.take(6).join(' | ')}${syncKeys.length > 6 ? ' ...' : ''}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArchitectureNode {
  const _ArchitectureNode({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.node, required this.isLast});

  final _ArchitectureNode node;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(0.14),
              ),
              child: Icon(node.icon, size: 16, color: colorScheme.primary),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: colorScheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  node.subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.8,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

enum _HealthStatus { healthy, warning, needsAttention }

String _formatDate(DateTime? value) {
  if (value == null) return 'Never';
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}

List<T> _filterBySite<T>(
  List<T> source,
  String Function(T item) siteOf,
  String? siteId,
) {
  if (siteId == null || siteId.isEmpty) return source;
  return source.where((item) => siteOf(item) == siteId).toList();
}

class _DetectedFieldSnapshot {
  const _DetectedFieldSnapshot({
    required this.floorsCount,
    required this.mocsCount,
    required this.sizesCount,
    required this.uomCount,
  });

  final int floorsCount;
  final int mocsCount;
  final int sizesCount;
  final int uomCount;
}

_DetectedFieldSnapshot _extractDetectedFieldSnapshot(String? jsonRaw) {
  if (jsonRaw == null || jsonRaw.trim().isEmpty) {
    return const _DetectedFieldSnapshot(
      floorsCount: 0,
      mocsCount: 0,
      sizesCount: 0,
      uomCount: 0,
    );
  }

  try {
    final data = jsonDecode(jsonRaw);
    if (data is! Map<String, dynamic>) {
      return const _DetectedFieldSnapshot(
        floorsCount: 0,
        mocsCount: 0,
        sizesCount: 0,
        uomCount: 0,
      );
    }

    return _DetectedFieldSnapshot(
      floorsCount: (data['floors'] as List?)?.length ?? 0,
      mocsCount: (data['mocs'] as List?)?.length ?? 0,
      sizesCount: (data['sizes'] as List?)?.length ?? 0,
      uomCount: (data['uoms'] as List?)?.length ?? 0,
    );
  } catch (_) {
    return const _DetectedFieldSnapshot(
      floorsCount: 0,
      mocsCount: 0,
      sizesCount: 0,
      uomCount: 0,
    );
  }
}

class _DraftStats {
  const _DraftStats({
    required this.mechanicalDrafts,
    required this.insulationDrafts,
    required this.expiredDrafts,
    required this.totalEntries,
  });

  final int mechanicalDrafts;
  final int insulationDrafts;
  final int expiredDrafts;
  final int totalEntries;
}

Future<_DraftStats> _readDraftStats() async {
  const mechPrefix = 'dpr_draft_';
  const insuPrefix = 'insu_dpr_draft_';

  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();

  int mechanical = 0;
  int insulation = 0;
  int expired = 0;

  for (final key in keys) {
    final isMech = key.startsWith(mechPrefix);
    final isInsu = key.startsWith(insuPrefix);
    if (!isMech && !isInsu) continue;

    if (isMech) {
      mechanical += 1;
    } else if (isInsu) {
      insulation += 1;
    }

    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) continue;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) continue;
      final expiresAtRaw = decoded['expiresAt']?.toString();
      final expiresAt =
          expiresAtRaw == null ? null : DateTime.tryParse(expiresAtRaw);
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        expired += 1;
      }
    } catch (_) {
      // Ignore malformed entries; they are counted in totals only.
    }
  }

  return _DraftStats(
    mechanicalDrafts: mechanical,
    insulationDrafts: insulation,
    expiredDrafts: expired,
    totalEntries: mechanical + insulation,
  );
}

class DprOfflineDashboardData {
  const DprOfflineDashboardData({
    required this.siteId,
    required this.insulationMaterials,
    required this.insulationPiping,
    required this.insulationEquipment,
    required this.insulationDirty,
    required this.insulationWithCardState,
    required this.cachedImages,
    required this.rateFileAnalyses,
    required this.rateMaterials,
    required this.rateVariants,
    required this.lastRateSyncAt,
    required this.latestRateFileName,
    required this.latestRateStatus,
    required this.detectedFieldSnapshot,
    required this.mechanicalDprRecords,
    required this.insulationDprRecords,
    required this.unsyncedMechanicalDpr,
    required this.unsyncedInsulationDpr,
    required this.outboxPending,
    required this.outboxFailed,
    required this.syncMetaEntries,
    required this.syncKeys,
    required this.lastGlobalSyncAt,
    required this.mechanicalDrafts,
    required this.insulationDrafts,
    required this.expiredDrafts,
    required this.totalDraftEntries,
  });

  final String? siteId;
  final int insulationMaterials;
  final int insulationPiping;
  final int insulationEquipment;
  final int insulationDirty;
  final int insulationWithCardState;
  final int cachedImages;
  final int rateFileAnalyses;
  final int rateMaterials;
  final int rateVariants;
  final DateTime? lastRateSyncAt;
  final String? latestRateFileName;
  final String? latestRateStatus;
  final _DetectedFieldSnapshot detectedFieldSnapshot;
  final int mechanicalDprRecords;
  final int insulationDprRecords;
  final int unsyncedMechanicalDpr;
  final int unsyncedInsulationDpr;
  final int outboxPending;
  final int outboxFailed;
  final int syncMetaEntries;
  final List<String> syncKeys;
  final DateTime? lastGlobalSyncAt;
  final int mechanicalDrafts;
  final int insulationDrafts;
  final int expiredDrafts;
  final int totalDraftEntries;
}
