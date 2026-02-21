import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/rate_file_uplaod_model.dart';
import '../data/rate_upload_provider.dart';

class GlobalUploadBanner extends ConsumerWidget {
  const GlobalUploadBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(rateUploadQueueProvider);

    final visibleJobs = jobs.where((j) =>
    j.status == UploadStatus.uploading ||
        j.status == UploadStatus.processing ||
        j.status == UploadStatus.success ||
        j.status == UploadStatus.failed).toList();

    if (visibleJobs.isEmpty) return const SizedBox.shrink();

    // ✅ priority: uploading > processing > success > failed
    RateUploadJob current;
    current = visibleJobs.firstWhere(
          (j) => j.status == UploadStatus.uploading,
      orElse: () => visibleJobs.firstWhere(
            (j) => j.status == UploadStatus.processing,
        orElse: () => visibleJobs.firstWhere(
              (j) => j.status == UploadStatus.success,
          orElse: () => visibleJobs.first,
        ),
      ),
    );

    Widget leftIcon() {
      switch (current.status) {
        case UploadStatus.success:
          return const Icon(Icons.check_circle, color: Colors.green, size: 28);

        case UploadStatus.failed:
          return const Icon(Icons.error, color: Colors.red, size: 28);

        case UploadStatus.processing:
          return const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          );

        case UploadStatus.uploading:
          return SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              value: current.progress.clamp(0.0, 1.0),
              strokeWidth: 2.5,
            ),
          );

        case UploadStatus.queued:
          return const Icon(Icons.schedule, color: Colors.orange, size: 28);
      }
    }

    return Material(
      elevation: 12,
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              leftIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  current.message,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${visibleJobs.length}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () {
                  // open upload manager screen (optional)
                },
                icon: const Icon(Icons.open_in_new, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
