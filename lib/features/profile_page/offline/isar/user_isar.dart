import 'dart:convert';

import 'package:isar/isar.dart';

import '../../userModel/userModel.dart';

part 'user_isar.g.dart';

@collection
class UserIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  // Stores full user payload to keep schema flexible with backend changes.
  late String userJson;

  static UserIsar fromModel(User user) {
    final entity = UserIsar();
    entity.id = user.id;
    entity.userJson = jsonEncode(user.toJson());
    return entity;
  }

  User toModel() {
    final decoded = jsonDecode(userJson);
    if (decoded is Map<String, dynamic>) {
      return User.fromJson(decoded);
    }
    return const User(
      id: '',
      email: '',
      fullName: '',
      phoneNumber: '',
      selectedServices: [],
    );
  }
}
