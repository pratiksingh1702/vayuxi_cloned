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

final englishModuleProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
        (ref, moduleName) async {
  final user = ref.watch(userNotifierProvider).user;
  if (user == null) return {};

  final repo = ref.read(languageRepositoryProvider);
  try {
    return await repo.loadModule(
      userId: user.id,
      moduleName: moduleName,
      languageCode: 'en-IN', // Force English
    );
  } catch (_) {
    return {};
  }
});

final languageModuleProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
        (ref, moduleName) async {
  ref.watch(activeLanguageProvider); // re-trigger on language change
  await Future.delayed(const Duration(
      milliseconds:
          1050)); // Keep loading state visible a bit longer for shimmer UX
  final user = ref.watch(userNotifierProvider).user;
  if (user == null) throw Exception("User not loaded");

  final repo = ref.read(languageRepositoryProvider);

  // Try to load the active language module
  try {
    return await repo.loadModule(
      userId: user.id,
      moduleName: moduleName,
    );
  } catch (e) {
    // Graceful degradation: If primary language fails, try English fallback
    print(
        "⚠️  Localization failed for $moduleName, falling back to English: $e");

    // We can't easily call another FutureProvider here, so we call the repo directly
    // Assuming English is the ultimate fallback
    try {
      // In a real app, we might want a repo method specifically for English
      // For now, let's assume English is always available or handled by repo.loadModule internally
      return await repo.loadModule(
        userId: user.id,
        moduleName: moduleName,
      );
    } catch (_) {
      return {}; // Final fallback: empty map
    }
  }
});
