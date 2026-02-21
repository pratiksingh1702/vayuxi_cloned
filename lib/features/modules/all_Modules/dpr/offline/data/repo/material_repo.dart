import 'dart:async';
import 'dart:convert';

import '../../materil_sync/material_sync.dart';
import '../local/local_material.dart';
import '../local/local_material_dao.dart';

class MaterialRepository {
  final LocalMaterialDao local;
  final MaterialSyncEngine syncEngine;

  MaterialRepository(this.local, this.syncEngine);
  Stream<List<LocalMaterial>> watch({
    required String siteId,
    required String domain,
    required String designation,
  }) {
    return local.watchAll(
      siteId: siteId,
      domain: domain,
      designation: designation,
    );
  }
  Future<void> updateAllSizes({
    required String siteId,
    required String domain,
    required String designation,
    required String size,
    required String unit,
  }) async {
    final locald=local;
    final materials = await local.getAll(
      siteId: siteId,
      domain: domain,
      designation: designation,
    );

    for (final local in materials) {
      final piping = local.toPiping().copyWith(
        size: size,
        sizeUom: unit,
      );

      local
        ..materialDataJson = jsonEncode(piping.toJson())
        ..isDirty = true
        ..updatedAt = DateTime.now();

      await locald.upsert(local);
    }
  }
  Future<void> syncInBackground({
    required String siteId,
    required String domain,
    required String designation,
  }) async {
    // IMPORTANT: don’t await in provider, but repo should still await internally
    unawaited(syncEngine.sync(
      siteId: siteId,
      domain: domain,
      designation: designation,
    ));
  }

  Future<void> sync({
    required String siteId,
    required String domain,
    required String designation,
  }) {
    return syncEngine.sync(
      siteId: siteId,
      domain: domain,
      designation: designation,
    );
  }

  Future<List<LocalMaterial>> load({
    required String siteId,
    required String domain,
    required String designation,
  }) {
    return local.getAll(
      siteId: siteId,
      domain: domain,
      designation: designation,
    );
  }

  Future<void> add(LocalMaterial m) async {
    m.isDirty = true;
    await local.upsert(m);
  }

  Future<void> delete(LocalMaterial m) async {
    await local.markDeleted(m);
  }
  Future<void> update(LocalMaterial m) async {
    m.isDirty = false;
    m.updatedAt = DateTime.now();
    await local.upsert(m);
  }
}
