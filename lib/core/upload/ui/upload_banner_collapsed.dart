import 'package:flutter/material.dart';
import '../models/upload_job.dart';
import '../models/upload_status.dart';
import 'widgets/auto_dismiss_timer.dart';

class UploadBannerCollapsed extends StatelessWidget {
  final UploadJob job;
  final int totalCount;
  final VoidCallback onTap;
  final VoidCallback onToggleMode;
  final VoidCallback? onNavigate;
  final VoidCallback onDismiss;
  final VoidCallback onStopTimer;

  const UploadBannerCollapsed({
    super.key,
    required this.job,
    required this.totalCount,
    required this.onTap,
    required this.onToggleMode,
    this.onNavigate,
    required this.onDismiss,
    required this.onStopTimer,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 12)],
        ),
        child: Row(
          children: [
            _StatusIcon(job: job),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    job.message,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    job.moduleId.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            if (totalCount > 1)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${totalCount - 1}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            if (onNavigate != null)
              TextButton(
                onPressed: onNavigate,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.lightBlueAccent,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            if (job.autoDismissAt != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: AutoDismissTimer(
                  job: job,
                  onStop: onStopTimer,
                  onDismiss: onDismiss,
                ),
              ),
            const SizedBox(width: 8),
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
            // ── Expand Arrow ──
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final UploadJob job;
  const _StatusIcon({required this.job});

  @override
  Widget build(BuildContext context) {
    switch (job.status) {
      case UploadStatus.success:
        return const Icon(Icons.check_circle, color: Colors.greenAccent, size: 26);
      case UploadStatus.failed:
        return const Icon(Icons.error_rounded, color: Colors.redAccent, size: 26);
      case UploadStatus.processing:
        return const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Colors.white70),
        );
      case UploadStatus.uploading:
        return SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            value: job.progress.clamp(0.0, 1.0),
            strokeWidth: 2.5,
            color: Colors.lightBlueAccent,
          ),
        );
      case UploadStatus.queued:
        return const Icon(Icons.schedule, color: Colors.orange, size: 26);
    }
  }
}