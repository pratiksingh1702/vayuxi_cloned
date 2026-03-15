import 'package:isar/isar.dart';
import 'package:untitled2/core/local/isar_db.dart';
import 'isar_db.dart';
import 'local_material.dart';

class LocalMaterialDao {
  Isar get _isar => AppIsarDB.isar;


  Future<void> upsertBatch(List<LocalMaterial> materials) async {
    await _isar.writeTxn(() async {
      await _isar.localMaterials.putAll(materials);
    });
  }

  Stream<List<LocalMaterial>> watchAll({
    required String siteId,
    required String domain,
    required String designation,
  }) {
    final query = _isar.localMaterials
        .filter()
        .siteIdEqualTo(siteId)
        .domainEqualTo(domain)
        .isDeletedEqualTo(false);

    if (designation.trim().isNotEmpty) {
      return query
          .designationEqualTo(designation)
          .sortByUpdatedAt()
          .watch(fireImmediately: true);
    }

    // If designation is empty → return both
    return query
        .sortByUpdatedAt()
        .watch(fireImmediately: true);
  }
  Future<List<LocalMaterial>> getAll({
    required String siteId,
    required String domain,
    required String designation,
  }) {

    final query = _isar.localMaterials
        .filter()
        .siteIdEqualTo(siteId)
        .domainEqualTo(domain)
        .isDeletedEqualTo(false);

    if (designation.trim().isNotEmpty) {
      return query
          .designationEqualTo(designation)
          .findAll();
    }

    // 🔥 return both piping + equipment
    return query.findAll();
  }

  Future<List<LocalMaterial>> dirty(String siteId) {
    return _isar.localMaterials
        .filter()
        .siteIdEqualTo(siteId)
        .isDirtyEqualTo(true)
        .findAll();
  }

  Future<List<LocalMaterial>> deleted(String siteId) {
    return _isar.localMaterials
        .filter()
        .siteIdEqualTo(siteId)
        .isDeletedEqualTo(true)
        .findAll();
  }

  Future<void> upsert(LocalMaterial m) async {
    await _isar.writeTxn(() async {
      await _isar.localMaterials.put(m);
    });
  }

  Future<void> markDeleted(LocalMaterial m) async {
    await _isar.writeTxn(() async {
      m.isDeleted = true;
      m.isDirty = true;
      await _isar.localMaterials.put(m);
    });
  }

  Future<void> deleteHard(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.localMaterials.delete(id);
    });
  }
}
