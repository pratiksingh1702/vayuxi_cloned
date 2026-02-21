import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../provider/inventory_provider.dart';
import 'inventory_repo.dart';

final inventorySyncControllerProvider =
Provider.family<InventorySyncController, String>((ref, siteId) {
  final repo = ref.read(repositoryProvider);

  final controller = InventorySyncController(repo, siteId);

  ref.onDispose(controller.dispose);

  return controller;
});

class InventorySyncController {
  final InventoryRepository repo;
  final String siteId;

  StreamSubscription? _sub;

  InventorySyncController(this.repo, this.siteId) {
    _init();
  }

  void _init() {
    // initial attempt
    runSync();

    // listen for internet return
    _sub = Connectivity().onConnectivityChanged.listen((r) {
      if (r != ConnectivityResult.none) {
        runSync();
      }
    });
  }

  Future<void> runSync() async {
    final status = await Connectivity().checkConnectivity();
    if (status == ConnectivityResult.none) return;

    try {
      await repo.syncAll(siteId);
    } catch (_) {}
  }

  void dispose() {
    _sub?.cancel();
  }
}
