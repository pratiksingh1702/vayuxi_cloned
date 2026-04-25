import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/notification_priority.dart';
import '../widgets/notification_action_button.dart';
import '../widgets/notification_media_widget.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSyncUpdate = notification.metadata['source'] == 'sync_queue';
    final syncSummary = _extractSyncSummary(notification.metadata);
    final draftWork = _extractDraftWork(notification.metadata);
    final draftName =
        (notification.metadata['draftName'] ?? '').toString().trim();
    final detailsMetadata = _filterDetailsMetadata(notification.metadata);

    return Material(
      color: theme.colorScheme.surface,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: notification.media != null ? 280 : 120,
              flexibleSpace: FlexibleSpaceBar(
                background: notification.media != null
                    ? NotificationMediaWidget(
                        media: notification.media!,
                        isExpanded: true,
                      )
                    : null,
                titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
                title: Text(
                  notification.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: notification.media != null ? Colors.white : null,
                    shadows: notification.media != null
                        ? [const Shadow(blurRadius: 6, color: Colors.black54)]
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _MetaRow(notification: notification),
                  if (isSyncUpdate && syncSummary != null) ...[
                    const SizedBox(height: 16),
                    _SyncRequestOverview(summary: syncSummary),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    notification.description,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                  ),
                  if (draftWork != null) ...[
                    const SizedBox(height: 20),
                    _DprDraftSnapshot(
                      draftWork: draftWork,
                      draftName: draftName,
                    ),
                  ],
                  if (detailsMetadata.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _MetadataSection(metadata: detailsMetadata),
                  ],
                ]),
              ),
            ),
          ],
        ),
        bottomSheet: notification.actions.isNotEmpty
            ? _StickyActions(notification: notification)
            : null,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _TypeChip(type: notification.type.name),
        const Spacer(),
        _PriorityChip(priority: notification.priority),
        const SizedBox(width: 10),
        Text(
          DateFormat('MMM d, y • h:mm a').format(notification.timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(type.toUpperCase()),
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});
  final NotificationPriority priority;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (priority) {
      NotificationPriority.high => (Colors.red.shade600, 'HIGH'),
      NotificationPriority.medium => (Colors.orange.shade600, 'MED'),
      NotificationPriority.low => (Colors.green.shade600, 'LOW'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.metadata});
  final Map<String, dynamic> metadata;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Details', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        ...metadata.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text('${e.key}: ',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text('${e.value}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Map<String, dynamic> _filterDetailsMetadata(Map<String, dynamic> metadata) {
  final filtered = <String, dynamic>{};
  const hiddenKeys = {
    'actions',
    'draftWork',
    'data',
    'query',
    'files',
    'method',
    'endpoint',
    'requestId',
    'source',
    'syncStatus',
    'taskLabel',
    'queuedAt',
    'syncedAt',
    'lastTriedAt',
    'friendlyReason',
  };

  for (final entry in metadata.entries) {
    if (hiddenKeys.contains(entry.key)) {
      continue;
    }
    filtered[entry.key] = entry.value;
  }
  return filtered;
}

Map<String, dynamic>? _extractSyncSummary(Map<String, dynamic> metadata) {
  if (metadata['source'] != 'sync_queue') return null;

  String read(String key) => (metadata[key] ?? '').toString().trim();
  final rawData = metadata['data'];
  final rawQuery = metadata['query'];
  final rawFiles = metadata['files'];

  return {
    'taskLabel': read('taskLabel'),
    'syncStatus': read('syncStatus'),
    'friendlyReason': read('friendlyReason'),
    'data': rawData is Map ? Map<String, dynamic>.from(rawData) : null,
    'query': rawQuery is Map ? Map<String, dynamic>.from(rawQuery) : null,
    'files': rawFiles is List ? List<dynamic>.from(rawFiles) : null,
  };
}

Map<String, dynamic>? _extractDraftWork(Map<String, dynamic> metadata) {
  final raw = metadata['draftWork'];
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is String && raw.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }
  return null;
}

class _DprDraftSnapshot extends StatelessWidget {
  const _DprDraftSnapshot({
    required this.draftWork,
    required this.draftName,
  });

  final Map<String, dynamic> draftWork;
  final String draftName;

  String _s(dynamic value) => (value ?? '').toString().trim();

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final dprName = _s(draftWork['dprName']).isNotEmpty
        ? _s(draftWork['dprName'])
        : _s(draftWork['work_description']);
    final plant = _s(draftWork['plant']);
    final location = _s(draftWork['location']);
    final size = _s(draftWork['size']);
    final moc = _s(draftWork['moc']);
    final date = _s(draftWork['date']);
    final layerType = _s(draftWork['layerType']);

    final piping = _list(draftWork['piping']).isNotEmpty
        ? _list(draftWork['piping'])
        : _list(draftWork['pipingMaterials']);
    final equipment = _list(draftWork['equipment']).isNotEmpty
        ? _list(draftWork['equipment'])
        : _list(draftWork['equipmentMaterials']);

    final isInsulation = _s(draftWork['work_description']).isNotEmpty ||
        draftWork.containsKey('pipingMaterials') ||
        draftWork.containsKey('equipmentMaterials');

    String itemName(Map<String, dynamic> item) {
      if (isInsulation) {
        final direct = _s(item['name']);
        if (direct.isNotEmpty) return direct;
      }
      final name = _s(item['materialName']);
      if (name.isNotEmpty) return name;
      return 'Unnamed';
    }

    String itemQty(Map<String, dynamic> item) {
      final qty = item['qty'];
      if (qty != null) return '$qty';
      final area = item['totalArea'];
      if (area != null) return '$area';
      return '-';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isInsulation ? 'Insulation DPR Snapshot' : 'DPR Snapshot',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (draftName.isNotEmpty) _kv(theme, 'Draft Name', draftName),
          _kv(theme, 'Name', dprName.isEmpty ? '-' : dprName),
          _kv(theme, 'Date', date.isEmpty ? '-' : date),
          _kv(theme, 'Plant', plant.isEmpty ? '-' : plant),
          _kv(theme, 'Location', location.isEmpty ? '-' : location),
          _kv(theme, 'MOC', moc.isEmpty ? '-' : moc),
          _kv(theme, 'Size', size.isEmpty ? '-' : size),
          if (layerType.isNotEmpty) _kv(theme, 'Layer Type', layerType),
          const SizedBox(height: 8),
          _kv(theme, 'Piping Items', '${piping.length}'),
          _kv(theme, 'Equipment Items', '${equipment.length}'),
          if (piping.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Piping', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            ...piping.take(6).map((item) {
              final name = itemName(item);
              final qty = itemQty(item);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $name (qty/area: $qty)',
                  style: theme.textTheme.bodySmall,
                ),
              );
            }),
            if (piping.length > 6)
              Text(
                '+${piping.length - 6} more',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
          ],
          if (equipment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Equipment', style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            ...equipment.take(6).map((item) {
              final name = itemName(item);
              final qty = itemQty(item);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $name (qty/area: $qty)',
                  style: theme.textTheme.bodySmall,
                ),
              );
            }),
            if (equipment.length > 6)
              Text(
                '+${equipment.length - 6} more',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _kv(ThemeData theme, String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$key: ',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _SyncRequestOverview extends StatelessWidget {
  const _SyncRequestOverview({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = (summary['syncStatus'] ?? '').toString();
    final taskLabel = (summary['taskLabel'] ?? '').toString();
    final reason = (summary['friendlyReason'] ?? '').toString();
    final data = summary['data'] as Map<String, dynamic>?;
    final query = summary['query'] as Map<String, dynamic>?;
    final files = summary['files'] as List<dynamic>?;

    final (statusLabel, statusColor) = switch (status) {
      'running' => ('Sending now', Colors.teal),
      'success' => ('Sent', Colors.green),
      'retry_failed' => ('Will retry automatically', Colors.orange),
      _ => ('Saved offline', Colors.blue),
    };

    String mapPreview(Map<String, dynamic>? map) {
      if (map == null || map.isEmpty) return 'None';
      final entries =
          map.entries.take(4).map((e) => '${e.key}: ${e.value}').join(' • ');
      if (map.length > 4) return '$entries • +${map.length - 4} more';
      return entries;
    }

    final filesCount = files?.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: statusColor.withOpacity(0.10),
        border: Border.all(color: statusColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync_alt_rounded, size: 18, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  taskLabel.isNotEmpty ? taskLabel : 'Saved request',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'What you were saving: ${taskLabel.isNotEmpty ? taskLabel : 'Update details'}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reason,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ],
          const SizedBox(height: 10),
          _SyncInfoRow(
            label: 'Saved details',
            value: mapPreview(data),
          ),
          const SizedBox(height: 6),
          _SyncInfoRow(
            label: 'Query details',
            value: mapPreview(query),
          ),
          const SizedBox(height: 6),
          _SyncInfoRow(
            label: 'Attached files',
            value: filesCount == 0 ? 'None' : '$filesCount file(s)',
          ),
        ],
      ),
    );
  }
}

class _SyncInfoRow extends StatelessWidget {
  const _SyncInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 98,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _StickyActions extends StatelessWidget {
  const _StickyActions({required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: notification.actions
            .map((a) => NotificationActionButton(
                  action: a,
                  notificationId: notification.id,
                ))
            .toList(),
      ),
    );
  }
}
