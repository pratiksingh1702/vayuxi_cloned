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

  Future<bool> _online() async {
    return await Connectivity().checkConnectivity() != ConnectivityResult.none;
  }

  Future<void> sync({
    required String siteId,
    required String domain,
    required String designation,
  }) async {
    if (!await _online()) return;

    if (domain != MaterialDomain.insulation.key) return;

    /// 🔹 STEP 1: ALWAYS PULL FROM SERVER
    final res = await remote.fetchInsulationRaw(siteId);

    final raw = res['data'];
    if (raw == null || raw is! List) {
      debugPrint('⚠️ data is not a list');
      return;
    }

    final localMaterials = await local.getAll(
      siteId: siteId,
      domain: domain,
      designation: designation,
    );

    final localByServerId = {
      for (var m in localMaterials)
        if (m.serverId != null) m.serverId!: m
    };

    for (final item in raw) {
      if (item['designation'] != designation) continue;

      final remoteSiteId = item['siteId']?['_id'];
      if (remoteSiteId != siteId) continue;

      final serverId = item['_id'];

      final List<String> localImages = [];

      final images = item['image'];
      if (images is List) {
        await Future.wait(
          images.map((url) async {
            if (url is String && url.startsWith('http')) {
              final path = await ImageCacheService.cacheImage(
                url: url,
                fileName: '${serverId}_${_safeName(url)}.png',
              );
              localImages.add(path);
            }
          }),
        );
      }

      final existing = localByServerId[serverId];

      if (existing == null) {
        /// 🔥 INSERT NEW
        final material = LocalMaterial()
          ..serverId = serverId
          ..siteId = siteId
          ..domain = domain
          ..designation = designation
          ..name = item['name'] ?? ''
          ..uom = item['uom']
          ..images = localImages
          ..isDirty = false
          ..isDeleted = false
          ..updatedAt = DateTime.now();

        await local.upsert(material);
      } else {
        /// 🔥 UPDATE IF SERVER IS NEWER
        existing
          ..name = item['name'] ?? existing.name
          ..uom = item['uom']
          ..images = localImages
          ..isDirty = false
          ..updatedAt = DateTime.now();

        await local.upsert(existing);
      }
    }

    /// 🔹 STEP 2: PUSH LOCAL DIRTY
    final dirty = await local.dirty(siteId);

    for (final m in dirty) {
      if (m.isDeleted) continue;

      if (m.serverId == null) {
        await remote.createInsulation(m);
      } else {
        await remote.updateInsulation(m);
      }

      m.isDirty = false;
      await local.upsert(m);
    }

    /// 🔹 STEP 3: PROCESS DELETES
    final deleted = await local.deleted(siteId);

    for (final m in deleted) {
      if (m.serverId != null) {
        await remote.deleteInsulation(m);
      }
      await local.deleteHard(m.id);
    }

    print("✅ Sync complete");
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

