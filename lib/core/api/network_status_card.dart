import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network_mode.dart';

class NetworkStatusCard extends ConsumerWidget {
  const NetworkStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(networkModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final isOnline = mode.mode == NetworkMode.online;
    final statusLabel = isOnline ? 'Online' : 'Offline';
    final statusColor = isOnline ? Colors.blue : Colors.red;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_rounded, color: statusColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Network: $statusLabel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Offline mode',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Switch(
                value: mode.mode == NetworkMode.offline,
                onChanged: (value) {
                  if (value) {
                    ref
                        .read(networkModeProvider.notifier)
                        .switchToOffline(reason: 'Manual toggle');
                  } else {
                    ref
                        .read(networkModeProvider.notifier)
                        .switchToOnline(reason: 'Manual toggle');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
