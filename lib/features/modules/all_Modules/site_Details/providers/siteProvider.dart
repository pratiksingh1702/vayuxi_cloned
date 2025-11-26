import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_service.dart';
import '../../../../../core/api/baseNotifier.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../repository/siteHive/siteHiveService.dart';
import '../repository/siteHive/siteLocalStorage.dart';
import '../repository/siteModel.dart';

class SiteState {
  final bool isLoading;
  final List<SiteModel> sites;
  final String? error;
  final bool hasData;

  SiteState({
    this.isLoading = false,
    this.sites = const [],
    this.error,
    this.hasData = false,
  });

  SiteState copyWith({
    bool? isLoading,
    List<SiteModel>? sites,
    String? error,
    bool? hasData,
  }) {
    return SiteState(
      isLoading: isLoading ?? this.isLoading,
      sites: sites ?? this.sites,
      error: error ?? this.error,
      hasData: hasData ?? this.hasData,
    );
  }
}

class SiteNotifier extends BaseNotifier<SiteState> {
  SiteNotifier(Ref ref) : super(ref, SiteState());

  @override
  Future<void> onSync() async {
    await fetchSites();
  }

  Future<void> fetchSites() async {
    final type = ref.read(typeProvider);

    if (type == null || type.isEmpty) {
      state = state.copyWith(
          sites: [],
          isLoading: false,
          hasData: false,
          error: 'Type not available'
      );
      print("[SYNC] Type is null/empty → cleared sites");
      return;
    }

    // Only set loading if we don't already have data
    if (state.sites.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }

    print("[SYNC] Fetching sites for type: $type");

    try {
      // 1️⃣ Load cache first for immediate UI
      final cachedSites = SiteHiveStorage.getAllSites()
          .where((cachedSite) => cachedSite.type == type) // Filter by current type
          .map((e) => e.toSiteModel())
          .toList();

      print("[CACHE] Loaded ${cachedSites.length} sites from Hive for type: $type");

      // Show cached data immediately if available
      if (cachedSites.isNotEmpty && state.sites.isEmpty) {
        state = state.copyWith(
            sites: cachedSites,
            isLoading: false,
            hasData: true
        );
        print("[UI] Showing cached sites immediately");
      }

      // 2️⃣ Fetch fresh data from API
      final res = await SiteAPI.fetchSites(type);
      final siteList = res.map((e) => SiteModel.fromJson(e)).toList();
      print("[API] Fetched ${siteList.length} sites from backend");

      // Save to Hive
      final apiIds = <String>{};
      for (final site in siteList) {
        apiIds.add(site.id);
        await SiteHiveStorage.saveSite(SiteModelHive.fromSiteModel(site));
      }

      // Clean up stale sites for this type
      final allCached = SiteHiveStorage.getAllSites();
      for (final cached in allCached) {
        if (cached.type == type && !apiIds.contains(cached.id)) {
          await SiteHiveStorage.deleteSite(cached.id);
        }
      }

      // Update state with fresh data
      state = state.copyWith(
          isLoading: false,
          sites: siteList,
          hasData: true,
          error: null
      );
      print("[SYNC DONE] Synced ${siteList.length} sites");

    } catch (e) {
      print("[ERROR] API fetch failed: $e");

      // Fallback to cache if available
      final cachedSites = SiteHiveStorage.getAllSites()
          .where((cachedSite) => cachedSite.type == type)
          .map((e) => e.toSiteModel())
          .toList();

      if (cachedSites.isNotEmpty) {
        state = state.copyWith(
            isLoading: false,
            sites: cachedSites,
            hasData: true,
            error: 'Using cached data - ${e.toString()}'
        );
        print("[FALLBACK] Showing ${cachedSites.length} cached sites");
      } else {
        state = state.copyWith(
            isLoading: false,
            sites: [],
            hasData: false,
            error: e.toString()
        );
        print("[FALLBACK] No cache available → showing error");
      }
    }
  }

  Future<void> updateSite(String siteId, FormData updatedData) async {
    try {
      await SiteAPI.updateSite(siteId, updatedData);
      await fetchSites();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}


final siteProvider = StateNotifierProvider<SiteNotifier, SiteState>((ref) => SiteNotifier(ref));