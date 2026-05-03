import 'package:dio/dio.dart';
import 'package:isar_community/isar.dart';
import '../../../../../../core/local/isar_db.dart';
import '../../../../../../core/api/dio.dart';
import '../isar/assembly_card_isar.dart';

class DPRSetupService {
  final _isar = AppIsarDB.isar;
  final Dio _dio = DioClient.dio;

  Future<List<AssemblyCardIsar>> getLocalAssemblyCards(String siteId) async {
    return await _isar.assemblyCardIsars.where().siteIdEqualTo(siteId).findAll();
  }

  Future<void> saveAssemblyCardLocal(AssemblyCardIsar card) async {
    await _isar.writeTxn(() async {
      await _isar.assemblyCardIsars.put(card);
    });
  }

  Future<void> deleteAssemblyCardLocal(int id) async {
    await _isar.writeTxn(() async {
      await _isar.assemblyCardIsars.delete(id);
    });
  }

  // Placeholder for online API sync
  Future<void> syncAssemblyCards(String siteId) async {
    // TODO: Implement sync logic using Dio when backend API is ready
    // final response = await _dio.get('/structure/assembly-cards', queryParameters: {'siteId': siteId});
    // ...
  }
}
