import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/model/material_setup.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/service/material_service.dart';
import 'local/local_material_dao.dart';

/// Service to sync material setup configurations between server and local database
class MaterialSyncService {
  final LocalMaterialDao _localDao = LocalMaterialDao();
  final InsulationMaterialSetupService _apiService = InsulationMaterialSetupService();

  /// Sync materials from server to local database
  /// This should be called when:
  /// 1. User opens the app (initial sync)
  /// 2. User pulls to refresh
  /// 3. After creating/updating materials on server
  Future<SyncResult> syncFromServer({
    required String siteId,
    bool forceRefresh = false,
  }) async {
    try {
      // Fetch material setups from server
      final serverMaterials = await _apiService.fetchMaterialSetup(
        siteId: siteId,
      );

      if (serverMaterials.isEmpty) {
        return SyncResult(
          success: true,
          message: 'No materials to sync',
          syncedCount: 0,
        );
      }

      // Store in local database
      await _localDao.syncMaterialSetup(
        siteId: siteId,
        materialSetups: serverMaterials,
      );

      return SyncResult(
        success: true,
        message: 'Successfully synced ${serverMaterials.length} materials',
        syncedCount: serverMaterials.length,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        syncedCount: 0,
        error: e.toString(),
      );
    }
  }

  /// Sync specific designation (piping or equipment)
  Future<SyncResult> syncDesignation({
    required String siteId,
    required String designation,
  }) async {
    try {
      final serverMaterials = await _apiService.fetchMaterialSetup(
        siteId: siteId,
        designation: designation,
      );

      if (serverMaterials.isEmpty) {
        return SyncResult(
          success: true,
          message: 'No $designation materials to sync',
          syncedCount: 0,
        );
      }

      await _localDao.syncMaterialSetup(
        siteId: siteId,
        materialSetups: serverMaterials,
      );

      return SyncResult(
        success: true,
        message: 'Synced ${serverMaterials.length} $designation materials',
        syncedCount: serverMaterials.length,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        syncedCount: 0,
        error: e.toString(),
      );
    }
  }

  /// Get materials from local database (offline-first)
  /// Falls back to server if local is empty
  Future<List<MaterialSetup>> getMaterials({
    required String siteId,
    String? designation,
    bool preferLocal = true,
  }) async {
    if (preferLocal) {
      // Try local first
      final localMaterials = await _localDao.getMaterialSetups(
        siteId: siteId,
        designation: designation,
      );

      if (localMaterials.isNotEmpty) {
        return localMaterials;
      }
    }

    // Fallback to server
    try {
      final serverMaterials = await _apiService.fetchMaterialSetup(
        siteId: siteId,
        designation: designation,
      );

      // Cache in local database
      if (serverMaterials.isNotEmpty) {
        await _localDao.syncMaterialSetup(
          siteId: siteId,
          materialSetups: serverMaterials,
        );
      }

      return serverMaterials;
    } catch (e) {
      print('Failed to fetch from server: $e');
      // Return empty list if both local and server fail
      return [];
    }
  }

  /// Update field configuration and sync to server
  Future<SyncResult> updateFieldConfig({
    required String materialId,
    required List<Map<String, dynamic>> fieldUpdates,
  }) async {
    try {
      // Update on server
      final updatedMaterial = await _apiService.updateFieldConfig(
        materialId: materialId,
        fieldUpdates: fieldUpdates,
      );

      // Update in local database
      await _localDao.syncMaterialSetup(
        siteId: updatedMaterial.siteId,
        materialSetups: [updatedMaterial],
      );

      return SyncResult(
        success: true,
        message: 'Field configuration updated',
        syncedCount: 1,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Update failed: $e',
        syncedCount: 0,
        error: e.toString(),
      );
    }
  }

  /// Add custom field and sync to server
  Future<SyncResult> addCustomField({
    required String materialId,
    required Map<String, dynamic> fieldDef,
  }) async {
    try {
      // Add on server
      final updatedMaterial = await _apiService.addCustomField(
        materialId: materialId,
        fieldDef: fieldDef,
      );

      // Update in local database
      await _localDao.syncMaterialSetup(
        siteId: updatedMaterial.siteId,
        materialSetups: [updatedMaterial],
      );

      return SyncResult(
        success: true,
        message: 'Custom field added',
        syncedCount: 1,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Add custom field failed: $e',
        syncedCount: 0,
        error: e.toString(),
      );
    }
  }

  /// Remove custom field and sync to server
  Future<SyncResult> removeCustomField({
    required String materialId,
    required String fieldKey,
  }) async {
    try {
      // Remove on server
      final updatedMaterial = await _apiService.removeCustomField(
        materialId: materialId,
        fieldKey: fieldKey,
      );

      // Update in local database
      await _localDao.syncMaterialSetup(
        siteId: updatedMaterial.siteId,
        materialSetups: [updatedMaterial],
      );

      return SyncResult(
        success: true,
        message: 'Custom field removed',
        syncedCount: 1,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Remove custom field failed: $e',
        syncedCount: 0,
        error: e.toString(),
      );
    }
  }

  /// Check if sync is needed (compares local and server counts)
  Future<bool> needsSync(String siteId) async {
    try {
      final localMaterials = await _localDao.getMaterialSetups(siteId: siteId);
      final serverMaterials = await _apiService.fetchMaterialSetup(siteId: siteId);
      
      return localMaterials.length != serverMaterials.length;
    } catch (e) {
      // If we can't check, assume sync is needed
      return true;
    }
  }

  /// Get last sync time for a site
  Future<DateTime?> getLastSyncTime(String siteId) async {
    final materials = await _localDao.getAll(
      siteId: siteId,
      domain: 'insulation',
      designation: '',
    );

    if (materials.isEmpty) return null;

    // Return the most recent update time
    materials.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return materials.first.updatedAt;
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final String? error;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    this.error,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, message: $message, count: $syncedCount)';
  }
}
