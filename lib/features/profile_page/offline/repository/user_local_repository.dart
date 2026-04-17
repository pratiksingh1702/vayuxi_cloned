import 'dart:async';

import 'package:isar/isar.dart';

import '../../../../core/local/isar_db.dart';
import '../../userModel/userModel.dart';
import '../isar/user_isar.dart';

class UserLocalRepository {
  const UserLocalRepository();

  Future<User?> getCurrentUser() async {
    final rows = await AppIsarDB.isar.userIsars.where().anyIsarId().findAll();
    if (rows.isEmpty) return null;
    return rows.first.toModel();
  }

  Stream<User?> watchCurrentUser() async* {
    yield await getCurrentUser();
    yield* AppIsarDB.isar.userIsars
        .where()
        .anyIsarId()
        .watchLazy()
        .asyncMap((_) async {
      return getCurrentUser();
    });
  }

  Future<void> saveUser(User user) async {
    final row = UserIsar.fromModel(user);
    await AppIsarDB.isar.writeTxn(() async {
      await AppIsarDB.isar.userIsars.putById(row);
    });
  }

  Future<void> clearUsers() async {
    await AppIsarDB.isar.writeTxn(() async {
      await AppIsarDB.isar.userIsars.clear();
    });
  }
}
