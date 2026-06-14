import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../materil_sync/material_sync.dart';
import '../local/local_material.dart';
import '../local/local_material_dao.dart';
import '../remote/material_remote_service.dart';
import 'material_repo.dart';
import 'material_repo_provider.dart';

final materialsProvider = FutureProvider.family<
    List<LocalMaterial>,
    ({
    String siteId,
    String domain,
    String designation,
    })>((ref, args) async {
  final repo = ref.read(materialRepositoryProvider);

  // 🔥 FORCE SYNC BEFORE READ
  await repo.sync(
    siteId: args.siteId,
    domain: args.domain,
    designation: args.designation,
  );

  return repo.load(
    siteId: args.siteId,
    domain: args.domain,
    designation: args.designation,
  );
});
