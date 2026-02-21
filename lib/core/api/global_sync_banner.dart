import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/api/requestQueue.dart';
import 'package:untitled2/core/api/sync_job.dart';

class GlobalSyncBanner extends ConsumerStatefulWidget {
  const GlobalSyncBanner({super.key});

  @override
  ConsumerState<GlobalSyncBanner> createState() => _GlobalSyncBannerState();
}

class _GlobalSyncBannerState extends ConsumerState<GlobalSyncBanner> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(syncJobsProvider);

    /// ⭐ show ONLY when retry is happening
    final visible = jobs.where((j) =>
    j.status == SyncJobStatus.running ||
        j.status == SyncJobStatus.success ||
        j.status == SyncJobStatus.failed
    ).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    final current = visible.first;




    /// queued for expanded list
    final queued =
    jobs.where((j) => j.status == SyncJobStatus.queued).toList();

    Widget icon;

    switch (current.status) {
      case SyncJobStatus.running:
        icon = const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        );
        break;

      case SyncJobStatus.success:
        icon = const Icon(Icons.check_circle, color: Colors.green, size: 22);
        break;

      case SyncJobStatus.failed:
        icon = const Icon(Icons.error, color: Colors.red, size: 22);
        break;

      case SyncJobStatus.queued:
      case SyncJobStatus.cancelled:
        icon = const Icon(Icons.schedule, color: Colors.orange, size: 22);
        break;
    }

    return Material(
      elevation: 12,
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// 🔹 HEADER (ACTIVE JOB)
              Row(
                children: [
                  icon,
                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      current.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                  /// show how many are waiting after this
                  if (queued.isNotEmpty)
                    Text(
                      "+${queued.length}",
                      style: const TextStyle(color: Colors.white70),
                    ),

                  IconButton(
                    icon: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white,
                    ),
                    onPressed: () => setState(() => expanded = !expanded),
                  ),
                ],
              ),

              /// 🔹 UPCOMING QUEUE
              if (expanded && queued.isNotEmpty) ...[
                const Divider(color: Colors.white24),

                ...queued.map(
                      (job) => Row(
                    children: [
                      const Icon(Icons.schedule,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          job.label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      IconButton(
                        icon:
                        const Icon(Icons.close, color: Colors.red, size: 18),
                        onPressed: () async {
                          await RequestQueue.remove(job.id);
                          ref
                              .read(syncJobsProvider.notifier)
                              .cancel(job.id);
                        },
                      )
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
