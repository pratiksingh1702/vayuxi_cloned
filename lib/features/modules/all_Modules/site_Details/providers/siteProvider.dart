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

  List<SiteModel> _sortSites(List<SiteModel> sites) {
    final sorted = List<SiteModel>.from(sites);

    DateTime parseDate(String value) {
      return DateTime.tryParse(value)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    sorted.sort((a, b) {
      final byCreatedAt =
          parseDate(b.createdAt).compareTo(parseDate(a.createdAt));
      if (byCreatedAt != 0) return byCreatedAt;

      final byName =
          a.siteName.toLowerCase().compareTo(b.siteName.toLowerCase());
      if (byName != 0) return byName;

      return a.id.compareTo(b.id);
    });

    return sorted;
  }

  List<SiteModel> _getDummySites(String type) {
    final now = DateTime.now().toIso8601String();
    switch (type) {
      case 'civil_work':
        return [
          SiteModel(
            id: 'dummy_civil_1',
            siteName: 'Dummy Civil Site (Test)',
            address: '123 Civil Ave, Infrastructure City',
            shippingAddress: '123 Civil Ave, Infrastructure City',
            contactPerson: 'John Builder',
            gstNo: 'DUMMYGSTCIVIL',
            phoneNumber: '9876543210',
            emailId: 'civil@dummy.com',
            documentDate: now,
            documentNumber: 'DOC-CIVIL-001',
            isDeleted: false,
            company: 'Dummy Corp',
            type: 'civil_work',
            createdAt: now,
            updatedAt: now,
            siteImage: 'https://images.unsplash.com/photo-1541913080-214307cc393a?w=500',
          )
        ];
      case 'erection_work':
        return [
          SiteModel(
            id: 'dummy_erection_1',
            siteName: 'Dummy Erection Site (Test)',
            address: '456 Steel St, Sky High',
            shippingAddress: '456 Steel St, Sky High',
            contactPerson: 'Steve Crane',
            gstNo: 'DUMMYGSTERECTION',
            phoneNumber: '9876543211',
            emailId: 'erection@dummy.com',
            documentDate: now,
            documentNumber: 'DOC-ERECT-001',
            isDeleted: false,
            company: 'Dummy Corp',
            type: 'erection_work',
            createdAt: now,
            updatedAt: now,
            siteImage: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=500',
          )
        ];
      case 'roofing_work':
        return [
          SiteModel(
            id: 'dummy_roofing_1',
            siteName: 'Dummy Roofing Site (Test)',
            address: '789 Shelter Rd, Peak Heights',
            shippingAddress: '789 Shelter Rd, Peak Heights',
            contactPerson: 'Ron Sheet',
            gstNo: 'DUMMYGSTROOF',
            phoneNumber: '9876543212',
            emailId: 'roofing@dummy.com',
            documentDate: now,
            documentNumber: 'DOC-ROOF-001',
            isDeleted: false,
            company: 'Dummy Corp',
            type: 'roofing_work',
            createdAt: now,
            updatedAt: now,
            siteImage: 'https://images.unsplash.com/photo-1635424710928-0544e8512eae?w=500',
          )
        ];
      case 'fabrication_work':
        return [
          SiteModel(
            id: 'dummy_fab_1',
            siteName: 'Dummy Fab Workshop (Test)',
            address: '321 Workshop Way, Industrial Zone',
            shippingAddress: '321 Workshop Way, Industrial Zone',
            contactPerson: 'Fred Weld',
            gstNo: 'DUMMYGSTFAB',
            phoneNumber: '9876543213',
            emailId: 'fab@dummy.com',
            documentDate: now,
            documentNumber: 'DOC-FAB-001',
            isDeleted: false,
            company: 'Dummy Corp',
            type: 'fabrication_work',
            createdAt: now,
            updatedAt: now,
            siteImage: 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?w=500',
          )
        ];
      default:
        return [];
    }
  }

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
          error: 'Type not available');
      print("[SYNC] Type is null/empty → cleared sites");
      return;
    }

    // Always reset UI for a new fetch request (new type or manual refresh).
    state = state.copyWith(
      sites: [],
      isLoading: true,
      hasData: false,
      error: null,
    );

    print("[SYNC] Fetching sites for type: $type");

    try {
      // 1️⃣ Load cache first for immediate UI
      final cachedSites = SiteHiveStorage.getAllSites()
          .where(
              (cachedSite) => cachedSite.type == type) // Filter by current type
          .map((e) => e.toSiteModel())
          .toList();
      final sortedCachedSites = _sortSites(cachedSites);

      print(
          "[CACHE] Loaded ${sortedCachedSites.length} sites from Hive for type: $type");

      // Show cached data immediately if available
      if (sortedCachedSites.isNotEmpty) {
        state = state.copyWith(
            sites: sortedCachedSites, isLoading: false, hasData: true);
        print("[UI] Showing cached sites immediately");
      }

      // 2️⃣ Fetch fresh data from API
      final res = await SiteAPI.fetchSites(type);
      final siteList =
          _sortSites(res.map((e) => SiteModel.fromJson(e)).toList());
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
      var finalSites = siteList;
      if (finalSites.isEmpty) {
        finalSites = _getDummySites(type);
      }

      state = state.copyWith(
          isLoading: false, sites: finalSites, hasData: finalSites.isNotEmpty, error: null);
      print("[SYNC DONE] Synced ${finalSites.length} sites");
    } catch (e) {
      print("[ERROR] API fetch failed: $e");

      // Fallback to cache if available
      final cachedSites = SiteHiveStorage.getAllSites()
          .where((cachedSite) => cachedSite.type == type)
          .map((e) => e.toSiteModel())
          .toList();
      final sortedCachedSites = _sortSites(cachedSites);

      if (sortedCachedSites.isNotEmpty) {
        state = state.copyWith(
            isLoading: false,
            sites: sortedCachedSites,
            hasData: true,
            error: 'Using cached data - ${e.toString()}');
        print("[FALLBACK] Showing ${sortedCachedSites.length} cached sites");
      } else {
        // FINAL FALLBACK: Dummy data for testing
        final dummySites = _getDummySites(type);
        if (dummySites.isNotEmpty) {
          state = state.copyWith(
              isLoading: false,
              sites: dummySites,
              hasData: true,
              error: 'TESTING MODE: Using dummy data');
          print("[FALLBACK] Showing dummy sites for testing");
        } else {
          state = state.copyWith(
              isLoading: false, sites: [], hasData: false, error: e.toString());
          print("[FALLBACK] No cache or dummy available → showing error");
        }
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

final siteProvider =
    StateNotifierProvider<SiteNotifier, SiteState>((ref) => SiteNotifier(ref));
