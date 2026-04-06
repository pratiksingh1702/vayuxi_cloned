// lib/features/modules/all_Modules/Manpower Details/upload/provider/upload_job_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/util/upload/upload_notifier.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/util/upload/upload_state.dart';


/// Main provider — scoped per-screen via ProviderScope override if needed,
/// but a single global instance works fine for most apps.
final uploadJobProvider =
StateNotifierProvider<UploadJobNotifier, UploadJobState>(
      (ref) => UploadJobNotifier(),
);

// ─── Convenience selectors (avoid rebuilding entire widget tree) ───

/// Just the completion state — use in navigation listener
final uploadJobStatusProvider = Provider<UploadJobStatus>(
      (ref) => ref.watch(uploadJobProvider).status,
);

/// Progress 0.0 → 1.0 — use in LinearProgressIndicator
final uploadJobPercentageProvider = Provider<double>(
      (ref) => ref.watch(uploadJobProvider).percentage,
);

/// True while uploading or polling
final uploadJobInProgressProvider = Provider<bool>(
      (ref) => ref.watch(uploadJobProvider).isInProgress,
);