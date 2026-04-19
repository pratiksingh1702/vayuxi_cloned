import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/upload_job.dart';
import '../../models/upload_status.dart';
import '../../manager/upload_manager.dart';
import '../widgets/auto_dismiss_timer.dart';

class FloatingStatusPanel extends ConsumerStatefulWidget {
  final List<UploadJob> jobs;
  final Offset ballPosition;
  final Size screenSize;
  final VoidCallback onDismiss;
  final void Function(String jobId) onRetry;
  final void Function(String route) onNavigate;
  final void Function(UploadJob job) onEdit;

  const FloatingStatusPanel({
    super.key,
    required this.jobs,
    required this.ballPosition,
    required this.screenSize,
    required this.onDismiss,
    required this.onRetry,
    required this.onNavigate,
    required this.onEdit,
  });

  @override
  ConsumerState<FloatingStatusPanel> createState() =>
      _FloatingStatusPanelState();
}

class _FloatingStatusPanelState extends ConsumerState<FloatingStatusPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // Panel opens right/left depending on ball position
  bool get _openRight => widget.ballPosition.dx < widget.screenSize.width / 2;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _statusColor(UploadStatus s) {
    switch (s) {
      case UploadStatus.uploading:
        return const Color(0xFF2196F3);
      case UploadStatus.processing:
        return const Color(0xFFFF9800);
      case UploadStatus.success:
        return const Color(0xFF4CAF50);
      case UploadStatus.failed:
        return const Color(0xFFF44336);
      case UploadStatus.queued:
        return const Color(0xFF607D8B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        alignment: _openRight ? Alignment.topLeft : Alignment.topRight,
        child: Transform.translate(
          offset: _openRight ? const Offset(64, -8) : const Offset(-240, -8),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 240,
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                      child: Row(
                        children: [
                          const Text(
                            'Upload Queue',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: widget.onDismiss,
                            child: const Icon(Icons.close,
                                color: Colors.white38, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                        color: Colors.white10, height: 1, thickness: 1),

                    // Jobs
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: widget.jobs.length,
                        itemBuilder: (_, i) => _PanelJobTile(
                          job: widget.jobs[i],
                          statusColor: _statusColor(widget.jobs[i].status),
                          onRetry: widget.jobs[i].status == UploadStatus.failed
                              ? () => widget.onRetry(widget.jobs[i].jobId)
                              : null,
                          onEdit:
                              widget.jobs[i].status == UploadStatus.failed &&
                                      (widget.jobs[i].moduleId == 'dpr' ||
                                          widget.jobs[i].moduleId == 'dpr_insu')
                                  ? () => widget.onEdit(widget.jobs[i])
                                  : null,
                          onNavigate: widget.jobs[i].targetRoute != null &&
                                  widget.jobs[i].status == UploadStatus.success
                              ? () {
                                  ref
                                      .read(uploadManagerProvider.notifier)
                                      .stopAutoDismiss(widget.jobs[i].jobId);
                                  widget
                                      .onNavigate(widget.jobs[i].targetRoute!);
                                }
                              : null,
                          onDismiss: () => ref
                              .read(uploadManagerProvider.notifier)
                              .removeJob(widget.jobs[i].jobId),
                          onStopTimer: () => ref
                              .read(uploadManagerProvider.notifier)
                              .stopAutoDismiss(widget.jobs[i].jobId),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelJobTile extends StatelessWidget {
  final UploadJob job;
  final Color statusColor;
  final VoidCallback? onRetry;
  final VoidCallback? onEdit;
  final VoidCallback? onNavigate;
  final VoidCallback onDismiss;
  final VoidCallback onStopTimer;

  const _PanelJobTile({
    required this.job,
    required this.statusColor,
    this.onRetry,
    this.onEdit,
    this.onNavigate,
    required this.onDismiss,
    required this.onStopTimer,
  });

  @override
  Widget build(BuildContext context) {
    final showProgress = job.status == UploadStatus.uploading ||
        job.status == UploadStatus.processing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.message,
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onNavigate != null)
                GestureDetector(
                  onTap: onNavigate,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Text('View',
                        style: TextStyle(
                            color: Color(0xFF64B5F6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              if (onRetry != null)
                GestureDetector(
                  onTap: onRetry,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Text('Retry',
                        style: TextStyle(
                            color: Color(0xFFFFB74D),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Text('Edit',
                        style: TextStyle(
                            color: Color(0xFF64B5F6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              if (job.status == UploadStatus.failed)
                GestureDetector(
                  onTap: onDismiss,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Text('Remove',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              if (job.autoDismissAt != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: AutoDismissTimer(
                    job: job,
                    onStop: onStopTimer,
                    onDismiss: onDismiss,
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
                minHeight: 2.5,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
