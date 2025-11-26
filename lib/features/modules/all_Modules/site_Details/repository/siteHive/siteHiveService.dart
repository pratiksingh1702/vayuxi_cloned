// site_hive_storage.dart
import 'package:hive/hive.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteHive/siteLocalStorage.dart';


class SiteHiveStorage {
  static const String _boxName = 'sitesBox';
  static Box<SiteModelHive>? _box;

  // Initialize Hive and open the box
  static Future<void> init() async {
    await Hive.openBox<SiteModelHive>(_boxName);
    _box = Hive.box<SiteModelHive>(_boxName);
  }

  // Add or update a site
  static Future<void> saveSite(SiteModelHive site) async {
    await _box?.put(site.id, site);
  }

  // Get a site by ID
  static SiteModelHive? getSite(String id) {
    return _box?.get(id);
  }

  // Get all sites
  static List<SiteModelHive> getAllSites() {
    return _box?.values.toList() ?? [];
  }

  // Delete a site
  static Future<void> deleteSite(String id) async {
    await _box?.delete(id);
  }

  // Clear all sites
  static Future<void> clearAllSites() async {
    await _box?.clear();
  }

  // Check if site exists
  static bool containsSite(String id) {
    return _box?.containsKey(id) ?? false;
  }

  // Get sites count
  static int get sitesCount {
    return _box?.length ?? 0;
  }

  // Watch for changes (useful for Riverpod)
  static Stream<BoxEvent> watchSite(String id) {
    return _box?.watch(key: id) ?? const Stream.empty();
  }

  // Watch all sites
  static Stream<BoxEvent> watchAllSites() {
    return _box?.watch() ?? const Stream.empty();
  }
}