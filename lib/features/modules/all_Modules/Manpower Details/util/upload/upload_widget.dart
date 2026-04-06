// lib/features/modules/all_Modules/Manpower Details/upload/widget/upload_progress_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/util/upload/upload_provider.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/util/upload/upload_state.dart';



/// Drop this widget into ManImportCsvScreen's body Column,
/// just below the Upload button. It shows/hides itself automatically.
class UploadProgressWidget extends ConsumerWidget {
  const UploadProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(uploadJobProvider);

    // Hide completely when idle
    if (job.isIdle) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusRow(job: job),
            const SizedBox(height: 12),
            _ProgressBar(job: job),
            if (job.isCompleted || job.isPolling) ...[
              const SizedBox(height: 10),
              _StatsRow(job: job),
            ],
            if (job.isFailed && job.message != null) ...[
              const SizedBox(height: 10),
              _ErrorMessage(message: job.message!),
            ],
            if (job.isCompleted && job.hasDuplicates) ...[
              const SizedBox(height: 10),
              _DuplicatesInfo(job: job),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.job});
  final UploadJobState job;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (job.status) {
      UploadJobStatus.uploading => (Icons.cloud_upload_outlined, Colors.blue, 'Uploading...'),
      UploadJobStatus.polling => (Icons.hourglass_top_rounded, Colors.orange, 'Processing...'),
      UploadJobStatus.completed => (Icons.check_circle_outline, Colors.green, 'Import complete'),
      UploadJobStatus.failed => (Icons.error_outline, Colors.red, 'Import failed'),
      _ => (Icons.info_outline, Colors.grey, ''),
    };

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          '${(job.percentage * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.job});
  final UploadJobState job;

  @override
  Widget build(BuildContext context) {
    final color = switch (job.status) {
      UploadJobStatus.failed => Colors.red,
      UploadJobStatus.completed => Colors.green,
      _ => Colors.blue,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: job.isUploading ? null : job.percentage, // indeterminate while uploading
        backgroundColor: Colors.grey.shade200,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        minHeight: 8,
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.job});
  final UploadJobState job;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _Chip(label: 'Total', value: '${job.totalRows}', color: Colors.grey),
        _Chip(label: 'Success', value: '${job.successCount}', color: Colors.green),
        _Chip(label: 'Errors', value: '${job.errorCount}', color: Colors.red),
        _Chip(label: 'Duplicates', value: '${job.duplicatesFound}', color: Colors.orange),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
      ),
    );
  }
}

class _DuplicatesInfo extends StatelessWidget {
  const _DuplicatesInfo({required this.job});
  final UploadJobState job;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${job.duplicatesFound} duplicate(s) — site assigned to existing records.',
            style: TextStyle(
              color: Colors.orange.shade900,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (job.duplicateDetails.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...job.duplicateDetails.take(3).map(
                  (d) => Text(
                '• Row ${d['row']}: ${d['name']}',
                style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
              ),
            ),
            if (job.duplicateDetails.length > 3)
              Text(
                '...and ${job.duplicateDetails.length - 3} more',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ],
      ),
    );
  }
}