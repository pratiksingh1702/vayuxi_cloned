// providers/insulation_combined_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/profile_page/provider/userProvider.dart';

import '../model/language_storage.dart';
import '../repository/language_repo.dart';
import 'language_Service.dart';

final languageApiProvider = Provider(
      (ref) => LanguageApiService(),
);
final languageRepositoryProvider = Provider(
      (ref) => LanguageRepository(
    ref.read(languageApiProvider),
    LanguageStorage(),
  ),
);
final activeLanguageProvider = Provider<String>((ref) {
  return LanguageStorage().getActiveLanguage();
});

final languageModuleProvider =
FutureProvider.family<Map<String, dynamic>, String>((ref, moduleName) async {
  ref.watch(activeLanguageProvider); // re-trigger

  final user = ref.watch(userNotifierProvider).user;
  if (user == null) throw Exception("User not loaded");

  final repo = ref.read(languageRepositoryProvider);
  return repo.loadModule(
    userId: user.id,
    moduleName: moduleName,
  );
});


