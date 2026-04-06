import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import '../models/upload_job.dart';
import '../models/upload_status.dart';
import 'widgets/auto_dismiss_timer.dart';
import '../manager/upload_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UploadBannerExpanded extends ConsumerWidget {
  final List<UploadJob> jobs;
  final VoidCallback onCollapse;
  final VoidCallback onToggleMode;
  final void Function(String route) onNavigate;
  final void Function(String jobId) onRetry;
  final void Function(String jobId) onDismiss;

  const UploadBannerExpanded({
    super.key,
    required this.jobs,
    required this.onCollapse,
    required this.onToggleMode,
    required this.onNavigate,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group by module
    final grouped = <String, List<UploadJob>>{};
    for (final j in jobs) {
      grouped.putIfAbsent(j.moduleId, () => []).add(j);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Text(
                  'Uploads',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                      fontSize: 16),
                ),
                const Spacer(),
                // ── Mode Switch Icon ──
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onToggleMode,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.open_in_full_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 16,
                      ),
                    ),
                  ),
                ),
                // ── Collapse Arrow ──
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCollapse,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white54,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Jobs list — max 5 visible, scrollable
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                for (final entry in grouped.entries) ...[
                  if (grouped.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                            letterSpacing: 1.2),
                      ),
                    ),
                  for (final job in entry.value)
                    _JobTile(
                      job: job,
                      onNavigate: job.targetRoute != null &&
                          job.status == UploadStatus.success
                          ? () {
                              ref.read(uploadManagerProvider.notifier).stopAutoDismiss(job.jobId);
                              onNavigate(job.targetRoute!);
                            }
                          : null,
                      onRetry: job.status == UploadStatus.failed &&
                          job.retryCount < job.maxRetries
                          ? () => onRetry(job.jobId)
                          : null,
                      onDismiss: () => onDismiss(job.jobId),
                      onStopTimer: () => ref.read(uploadManagerProvider.notifier).stopAutoDismiss(job.jobId),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  final UploadJob job;
  final VoidCallback? onNavigate;
  final VoidCallback? onRetry;
  final VoidCallback onDismiss;
  final VoidCallback onStopTimer;

  const _JobTile({
    required this.job,
    this.onNavigate,
    this.onRetry,
    required this.onDismiss,
    required this.onStopTimer,
  });

  Color get _statusColor {
    switch (job.status) {
      case UploadStatus.success:   return Colors.greenAccent;
      case UploadStatus.failed:    return Colors.redAccent;
      case UploadStatus.uploading: return Colors.lightBlueAccent;
      case UploadStatus.processing:return Colors.amberAccent;
      case UploadStatus.queued:    return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showProgress = job.status == UploadStatus.uploading ||
        job.status == UploadStatus.processing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.message,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onNavigate != null)
                _ActionChip(
                    label: 'View', color: Colors.lightBlueAccent, onTap: onNavigate!),
              if (onRetry != null)
                _ActionChip(
                    label: 'Retry', color: Colors.orange, onTap: onRetry!),
              
              if (job.autoDismissAt != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: AutoDismissTimer(
                    job: job,
                    onStop: onStopTimer,
                    onDismiss: onDismiss,
                  ),
                ),

              if (job.status.isTerminal && job.autoDismissAt == null)
                GestureDetector(
                  onTap: onDismiss,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.close, color: Colors.white30, size: 16),
                  ),
                ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: job.status == UploadStatus.processing
                    ? null
                    : job.progress.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(_statusColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}