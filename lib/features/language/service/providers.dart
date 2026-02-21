// core/providers/translation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/language/service/lang_providers.dart';
import 'package:untitled2/features/language/service/translator.dart';

import '../model/translation_helper.dart';

// Provider to get translator for any module
final translatorProvider = Provider.family<Translator, String>((ref, moduleName) {
  final asyncModule = ref.watch(languageModuleProvider(moduleName));
  return asyncModule.when(
    data: (data) => Translator(data),
    loading: () => Translator({}),
    error: (_, __) => Translator({}),
  );
});

// Provider for common translations (used across multiple modules)
final commonTranslatorProvider = Provider<Translator>((ref) {
  return ref.watch(translatorProvider('common'));
});



// Home Module Translation Helper Provider
final homeTranslationHelperProvider = Provider<HomeTranslationHelper>((ref) {
  final translator = ref.watch(translatorProvider('home'));
  return HomeTranslationHelper(translator);
});

// Report Module Translation Helper Provider
final reportTranslationHelperProvider = Provider<ReportTranslationHelper>((ref) {
  final translator = ref.watch(translatorProvider('report'));
  return ReportTranslationHelper(translator);
});

// Setup Module Translation Helper Provider
final setupTranslationHelperProvider = Provider<SetupTranslationHelper>((ref) {
  final translator = ref.watch(translatorProvider('setup'));
  return SetupTranslationHelper(translator);
});

// Daily Entry Module Translation Helper Provider
final dailyEntryTranslationHelperProvider = Provider<DailyEntryTranslationHelper>((ref) {
  final translator = ref.watch(translatorProvider('daily_entry'));
  return DailyEntryTranslationHelper(translator);
});

// Settings Module Translation Helper Provider
final settingsTranslationHelperProvider = Provider<SettingsTranslationHelper>((ref) {
  final translator = ref.watch(translatorProvider('setting'));
  return SettingsTranslationHelper(translator);
});

// Landing Screen Translation Helper Provider
final landingTranslationHelperProvider = Provider<LandingTranslationHelper>((ref) {
  final translator = ref.watch(translatorProvider('landing_screen'));
  return LandingTranslationHelper(translator);
});

// Theme & Language Settings Helper Provider
final themeLanguageHelperProvider = Provider<ThemeLanguageTranslationHelper>((ref) {
  final translator = ref.watch(translatorProvider('setting_theme_language_help'));
  return ThemeLanguageTranslationHelper(translator);
});

// Manpower/Team/Inventory Setup Helper Provider
final manpowerTeamInventoryHelperProvider = Provider<ManpowerTeamInventoryTranslationHelper>((ref) {
  final translator = ref.watch(translatorProvider('setup_manpower_team_inventory'));
  return ManpowerTeamInventoryTranslationHelper(translator);
});

// Site & Rate Setup Helper Provider
final siteRateHelperProvider = Provider<SiteRateTranslationHelper>((ref) {
  final translator = ref.watch(translatorProvider('setup_site_and_rate'));
  return SiteRateTranslationHelper(translator);
});

// DPR Setup Helper Provider
final dprSetupHelperProvider = Provider<DprSetupTranslationHelper>((ref) {
  final translator = ref.watch(translatorProvider('setup_dpr'));
  return DprSetupTranslationHelper(translator);
});

// Profile & Subscription Helper Provider
final profileSubscriptionHelperProvider = Provider<ProfileSubscriptionTranslationHelper>((ref) {
  final translator = ref.watch(translatorProvider('setting_profile_and_subscription'));
  return ProfileSubscriptionTranslationHelper(translator);
});

// Additional helper classes for more specific modules
class ManpowerTeamInventoryTranslationHelper extends TranslationHelper {
  ManpowerTeamInventoryTranslationHelper(super.translator);

  // Add specific methods for this module
  String get selectEntryMethodTitle => t('select_entry_method_title');
  String get manualOption => t('manual_option');
  String get importOption => t('import_option');
}

class SiteRateTranslationHelper extends TranslationHelper {
  SiteRateTranslationHelper(super.translator);

  String get selectEntryMethodTitle => t('select_entry_method_title');
  String get manualEntryOption => t('manual_entry_option');
  String get importEntryOption => t('import_entry_option');
}

class DprSetupTranslationHelper extends TranslationHelper {
  DprSetupTranslationHelper(super.translator);

  String get selectSiteTitle => t('select_site_title');
  String get bookButton => t('book_button');
}

class ProfileSubscriptionTranslationHelper extends TranslationHelper {
  ProfileSubscriptionTranslationHelper(super.translator);

  String get currentPlan => t('current_plan');
  String get planPremium => t('plan_premium');
}

class ThemeLanguageTranslationHelper extends TranslationHelper {
  ThemeLanguageTranslationHelper(super.translator);

  String get sectionAppearance => t('section_appearance');
  String get toggleDarkMode => t('toggle_dark_mode');
}