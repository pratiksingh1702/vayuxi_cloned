import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/network_mode.dart';
import '../api/network_metrics.dart';
import '../api/syncManager.dart';
import '../api/requestQueue.dart';
import '../utlis/widgets/premium_app_bar.dart';

class NetworkSettingsScreen extends ConsumerStatefulWidget {
  const NetworkSettingsScreen({super.key});

  @override
  ConsumerState<NetworkSettingsScreen> createState() => _NetworkSettingsScreenState();
}

class _NetworkSettingsScreenState extends ConsumerState<NetworkSettingsScreen> {
  bool _isClearing = false;
  bool _isSyncing = false;

  Future<void> _handleManualSync() async {
    setState(() => _isSyncing = true);
    try {
      await ref.read(syncManagerProvider).retryNow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync check triggered!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleClearQueue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clean Waiting Data?'),
        content: const Text('This will delete all data that is waiting to be sent to the office. Only use this if the data is wrong.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Data'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clean Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isClearing = true);
    await RequestQueue.clearAll();
    setState(() => _isClearing = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting data cleaned!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final networkMode = ref.watch(networkModeProvider);
    final metrics = ref.watch(networkMetricsProvider);
    final queueCount = RequestQueue.count;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PremiumAppBar(
        title: 'Internet & Data',
        showDrawerButton: false,
        height: 74,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Internet Mode Card ──────────────────────────────────────────
          _HeaderCard(
            isOffline: networkMode.isOffline,
            onToggle: (val) {
              if (val) {
                ref.read(networkModeProvider.notifier).switchToOffline(reason: 'User manual toggle');
              } else {
                ref.read(networkModeProvider.notifier).switchToOnline(reason: 'User manual toggle');
              }
            },
          ),
          const SizedBox(height: 20),

          // ── Data Sync Section ──────────────────────────────────────────
          _SectionTitle(title: 'Sending Data (Sync)', icon: Icons.sync_rounded),
          const SizedBox(height: 10),
          _ActionCard(
            title: 'Send All Data Now',
            subtitle: queueCount > 0 
                ? '$queueCount items are waiting to be sent.' 
                : 'All data has been sent to the office.',
            icon: Icons.cloud_upload_rounded,
            accent: const Color(0xFF0D7A62),
            isLoading: _isSyncing,
            onTap: queueCount > 0 ? _handleManualSync : null,
            trailing: queueCount > 0 ? _Badge(count: queueCount) : null,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            title: 'Clean Up Waiting Data',
            subtitle: 'Only use if data is stuck or wrong.',
            icon: Icons.delete_sweep_rounded,
            accent: colorScheme.error,
            isLoading: _isClearing,
            onTap: queueCount > 0 ? _handleClearQueue : null,
          ),
          const SizedBox(height: 24),

          // ── Internet Speed Section ─────────────────────────────────────
          _SectionTitle(title: 'Internet Speed', icon: Icons.speed_rounded),
          const SizedBox(height: 10),
          _SpeedInfoCard(metrics: metrics),
          
          const SizedBox(height: 32),
          Center(
            child: Text(
              'App is currently working in ${networkMode.isOffline ? "SAVE" : "LIVE"} mode.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.isOffline, required this.onToggle});
  final bool isOffline;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = isOffline ? const Color(0xFFB42318) : const Color(0xFF0D7A62);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                  color: accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOffline ? 'Save Mode (Offline)' : 'Live Mode (Online)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      isOffline 
                          ? 'Data stays on phone until sync.' 
                          : 'Data goes to office instantly.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Work without Internet?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Switch.adaptive(
                  value: isOffline,
                  activeColor: accent,
                  onChanged: onToggle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.isLoading = false,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;
  final bool isLoading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(isEnabled ? 0.12 : 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isLoading 
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                    )
                  : Icon(icon, color: accent.withOpacity(isEnabled ? 1 : 0.4)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isEnabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (isEnabled && !isLoading && trailing == null)
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedInfoCard extends StatelessWidget {
  const _SpeedInfoCard({required this.metrics});
  final NetworkMetricsState metrics;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    String quality = 'Testing...';
    Color qualityColor = colorScheme.onSurfaceVariant;
    
    if (metrics.lastCheckedAt != null) {
      final latency = metrics.avgLatencyMs ?? 0;
      if (latency == 0) {
        quality = 'Offline';
        qualityColor = colorScheme.error;
      } else if (latency < 500) {
        quality = 'Super Fast';
        qualityColor = const Color(0xFF0D7A62);
      } else if (latency < 2000) {
        quality = 'Good';
        qualityColor = Colors.blue;
      } else {
        quality = 'Slow';
        qualityColor = Colors.orange;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricItem(
                label: 'Speed',
                value: quality,
                valueColor: qualityColor,
                icon: Icons.bolt_rounded,
              ),
              _MetricItem(
                label: 'Response',
                value: metrics.lastLatencyMs != null ? '${metrics.lastLatencyMs}ms' : '--',
                icon: Icons.timer_rounded,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricItem(
                label: 'Download',
                value: metrics.downloadKbps != null ? '${metrics.downloadKbps!.toStringAsFixed(1)} kbps' : '--',
                icon: Icons.download_rounded,
              ),
              _MetricItem(
                label: 'Upload',
                value: metrics.uploadKbps != null ? '${metrics.uploadKbps!.toStringAsFixed(1)} kbps' : '--',
                icon: Icons.upload_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFB42318),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
