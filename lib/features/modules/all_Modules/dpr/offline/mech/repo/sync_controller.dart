import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/mech/repo/rate_Repo.dart';

import '../../../../../../../core/local/isar_db.dart';
import '../../../providers/rate_variant_provider.dart';


final rateSyncControllerProvider =
Provider.autoDispose.family<void, String>((ref, siteId) {
  final repo = RateRepository(AppIsarDB.isar);

  Future<void> trySync() async {
    try {
      await repo.syncRateFile(siteId);
      // ✅ invalidate providers after sync
      ref.invalidate(rateFileAnalysisProvider(siteId));
    } catch (_) {
      // ignore
    }
  }

  // ✅ first sync instantly
  trySync();

  // ✅ listen to connectivity changes and sync when online
  final sub = Connectivity().onConnectivityChanged.listen((result) {
    if (result != ConnectivityResult.none) {
      trySync();
    }
  });

  ref.onDispose(() => sub.cancel());
});
