import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import '../data/constants/material_constants.dart';
import '../data/local/local_material_dao.dart';
import '../data/local/local_material.dart';
import '../data/remote/image_cache_service.dart';
import '../data/remote/material_remote_service.dart';


class MaterialSyncEngine {
  final LocalMaterialDao local;
  final MaterialRemoteService remote;

  MaterialSyncEngine(this.local, this.remote);

  bool _syncRunning = false;

  Future<bool> _online() async {
    return await Connectivity().checkConnectivity() != ConnectivityResult.none;
  }

  Future<void> sync({
    required String siteId,
    required String domain,
    required String designation,
  }) async {

    debugPrint("🔵 SYNC STARTED $designation");

    if (!await _online()) {
      debugPrint("❌ Device offline");
      return;
    }

    if (_syncRunning) {
      debugPrint("⚠️ Sync already running");
      return;
    }

    _syncRunning = true;

    try {

      if (domain != MaterialDomain.insulation.key) {
        debugPrint("⚠️ Domain not insulation");
        return;
      }

      /// 🔹 FETCH SERVER DATA
      final res = await remote.fetchInsulationRaw(siteId);
      final raw = res['data'];

      if (raw == null || raw is! List) {
        debugPrint("❌ Invalid API response");
        return;
      }

      debugPrint("📦 Server returned ${raw.length} materials");

      /// 🔹 LOAD LOCAL MATERIALS
      final localMaterials = await local.getAll(
        siteId: siteId,
        domain: domain,
        designation: '',
      );

      final localByServerId = {
        for (var m in localMaterials)
          if (m.serverId != null) m.serverId!: m
      };

      /// 🔹 COLLECT UPSERT LIST
      final List<LocalMaterial> materialsToUpsert = [];

      /// 🔹 PROCESS SERVER MATERIALS
      for (final item in raw) {

        final remoteDesignation =
        (item['designation'] ?? '').toString().toLowerCase();

        if (designation.isNotEmpty &&
            remoteDesignation != designation.toLowerCase()) {
          continue;
        }

        final remoteSiteId = item['siteId']?['_id'];
        if (remoteSiteId != siteId) continue;

        final serverId = item['_id'];

        /// 🔹 IMAGE CACHE (PARALLEL)
        final images = item['image'];

        List<String> localImages = [];

        if (images is List) {

          final futures = images
              .whereType<String>()
              .where((e) => e.startsWith("http"))
              .map((url) {
            return ImageCacheService.cacheImage(
              url: url,
              fileName: '${serverId}_${_safeName(url)}.png',
            );
          }).toList();

          localImages = await Future.wait(futures);
        }

        final existing = localByServerId[serverId];

        if (existing == null) {

          final material = LocalMaterial()
            ..serverId = serverId
            ..siteId = siteId
            ..domain = domain
            ..designation = remoteDesignation
            ..name = item['name'] ?? ''
            ..uom = item['uom']
            ..images = localImages
            ..isDirty = false
            ..isDeleted = false
            ..updatedAt = DateTime.now();

          materialsToUpsert.add(material);

        } else {

          existing
            ..name = item['name'] ?? existing.name
            ..uom = item['uom']
            ..images = localImages
            ..isDirty = false
            ..updatedAt = DateTime.now();

          materialsToUpsert.add(existing);
        }
      }

      /// 🔹 BATCH DATABASE WRITE (VERY FAST)
      if (materialsToUpsert.isNotEmpty) {
        await local.upsertBatch(materialsToUpsert);
        debugPrint("💾 Upserted ${materialsToUpsert.length} materials");
      }

      /// 🔹 PUSH LOCAL DIRTY
      final dirty = await local.dirty(siteId);

      if (dirty.isNotEmpty) {

        debugPrint("⬆️ ${dirty.length} dirty materials");

        for (final m in dirty) {

          if (m.isDeleted) continue;

          if (m.serverId == null) {
            await remote.createInsulation(m);
          } else {
            await remote.updateInsulation(m);
          }

          m.isDirty = false;
        }

        await local.upsertBatch(dirty);
      }

      /// 🔹 PROCESS DELETES
      final deleted = await local.deleted(siteId);

      if (deleted.isNotEmpty) {

        debugPrint("🗑 ${deleted.length} deleted materials");

        for (final m in deleted) {

          if (m.serverId != null) {
            await remote.deleteInsulation(m);
          }

          await local.deleteHard(m.id);
        }
      }

      debugPrint("✅ SYNC COMPLETE");

    } catch (e) {

      debugPrint("❌ Sync failed: $e");

    } finally {

      _syncRunning = false;
      debugPrint("🔵 SYNC FINISHED");
    }
  }

  /// 🔥 THIS WAS MISSING
  Future<void> _initialPull(
      String siteId,
      String domain,
      String designation,
      ) async {
    if (domain != MaterialDomain.insulation.key) return;

    final res = await remote.fetchInsulationRaw(siteId);

    final raw = res['data'];
    if (raw == null || raw is! List) {
      debugPrint('⚠️ data is not a list');
      return;
    }

    for (final item in raw) {
      // designation filter
      if (item['designation'] != designation) continue;

      // siteId filter (OBJECT → _id)
      final remoteSiteId = item['siteId']?['_id'];
      if (remoteSiteId != siteId) continue;
      final List<String> localImages = [];

      final images = item['image'];
      if (images is List) {

        await Future.wait(
          List.generate(images.length, (i) async {
            final url = images[i];
            print(url);
            if (url is String && url.startsWith('http')) {
              final path = await ImageCacheService.cacheImage(
                url: url,
                  fileName: '${item['_id']}_${_safeName(url)}.png'

              );
              localImages.add(path);
            }
          }),
        );
      }


      final material = LocalMaterial()
        ..serverId = item['_id']
        ..siteId = siteId
        ..domain = domain
        ..designation = item['designation']
        ..name = item['name'] ?? ''
        ..uom = item['uom']
        ..images = localImages   // 🔥 LOCAL PATHS ONLY
        ..isDirty = false
        ..isDeleted = false;

      await local.upsert(material);

    }
  }
  String _safeName(String url) {
    return url.hashCode.toString();
  }



}

