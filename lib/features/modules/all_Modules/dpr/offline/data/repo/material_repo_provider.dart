import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../materil_sync/material_sync.dart';
import '../local/local_material.dart';
import '../local/local_material_dao.dart';
import '../remote/material_remote_service.dart';
import 'material_repo.dart';

final materialRepositoryProvider = Provider<MaterialRepository>((ref) {
  final localDao = LocalMaterialDao();
  final remoteService = MaterialRemoteService();
  final syncEngine = MaterialSyncEngine(localDao, remoteService);

  return MaterialRepository(
    localDao,
    syncEngine,
  );
});


final syncProgressProvider = StreamProvider.autoDispose<double>((ref) {
  return ref.watch(materialRepositoryProvider).syncProgress;
});


final materialsStreamProvider = StreamProvider.family<
    List<LocalMaterial>,
    ({
    String siteId,
    String domain,
    String designation,
    })>((ref, args) {
  final repo = ref.read(materialRepositoryProvider);

  // // ✅ trigger background sync (DON’T await)
  // repo.syncInBackground(
  //   siteId: args.siteId,
  //   domain: args.domain,
  //   designation: args.designation,
  // );

  // ✅ UI reads only local db
  return repo.watch(
    siteId: args.siteId,
    domain: args.domain,
    designation: args.designation,
  );
});
