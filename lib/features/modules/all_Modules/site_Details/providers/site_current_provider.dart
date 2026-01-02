import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/siteProvider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_service.dart';
import '../../../../../core/api/baseNotifier.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../team/model/teamModel.dart';
import '../../team/provider/teamProvider.dart';
import '../repository/siteHive/siteHiveService.dart';
import '../repository/siteHive/siteLocalStorage.dart';
import '../repository/siteModel.dart';

final siteDropdownValueProvider = StateProvider<SiteModel?>((ref) => null);


final selectedSiteIdProvider = StateProvider<String?>((ref) => null);

class SelectedSiteNotifier extends StateNotifier<SiteModel?> {
  SelectedSiteNotifier(this.ref) : super(null);
  final Ref ref;

  void select(SiteModel site) {
    state = site;
    ref.read(selectedSiteIdProvider.notifier).state = site.id;
    ref.read(siteDropdownValueProvider.notifier).state = site;
  }

  void clear() {
    state = null;
    ref.read(selectedSiteIdProvider.notifier).state = null;
    ref.read(siteDropdownValueProvider.notifier).state = null;
  }
}

final selectedSiteProvider =
    StateNotifierProvider<SelectedSiteNotifier, SiteModel?>(
      (ref) => SelectedSiteNotifier(ref),
    );

/// Optional: auto-derives selected site from list & selected ID
final currentSiteProvider = Provider<SiteModel?>((ref) {
  final allSites = ref.watch(siteProvider).sites;
  final selectedId = ref.watch(selectedSiteIdProvider);
  if (selectedId == null) return null;
  return allSites.firstWhere(
    (site) => site.id == selectedId,
    orElse: () => allSites.first,
  );
});
class ModuleScreenSyncNotifier extends Notifier<void> {
  @override
  void build() {}

  void syncDropdownToGlobal() {
    final siteDropdown = ref.read(siteDropdownValueProvider);
    final teamDropdown = ref.read(teamDropdownValueProvider);

    print("[SYNC] Site Dropdown: ${siteDropdown?.siteName}");
    print("[SYNC] Team Dropdown: ${teamDropdown?.teamName}");
    print("🫂🫂");

    // 🔥 SITE
    if (siteDropdown == null) {
      ref.read(selectedSiteIdProvider.notifier).state = null;
      ref.read(selectedSiteProvider.notifier).clear();
    }

    // 🔥 TEAM (Same pattern as site)
    if (teamDropdown == null) {
      ref.read(selectedTeamIdProvider.notifier).state = null;
      ref.read(selectedTeamProvider.notifier).clear();
    }
  }
}

final moduleScreenSyncProvider =
NotifierProvider<ModuleScreenSyncNotifier, void>(
  ModuleScreenSyncNotifier.new,
);
