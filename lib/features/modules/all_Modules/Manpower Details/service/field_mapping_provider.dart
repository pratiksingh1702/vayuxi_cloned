// ============================================================
// field_mapping_provider.dart
// Riverpod state management for the 3-step field mapping flow.
// ============================================================

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/service/field_api_service.dart';

import '../model/field_mapping_model.dart';

// ─────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────

enum FieldMappingStep { upload, mapping, review }

/// Loading phase tags so the UI can show specific skeleton states
enum LoadingPhase { none, preview, configurations, importing, savingConfig }

class FieldMappingState {
  // ── Step navigation ──────────────────────────────────────
  final FieldMappingStep currentStep;

  // ── Step 1: Upload ───────────────────────────────────────
  final File? selectedFile;
  final FieldMappingPreview? preview; // result from API
  final LoadingPhase loadingPhase;
  final String? error;

  // ── Step 2: Mapping ──────────────────────────────────────
  /// Key: csvColumn → Value: modelField (or null = unmapped)
  final Map<String, String?> activeMappings;
  final List<MappingConfiguration> savedConfigurations;
  final MappingConfiguration? selectedConfiguration;

  // ── Step 3: Review & Import ───────────────────────────────
  final bool saveConfigOnImport;
  final String saveConfigName;
  final bool saveConfigAsDefault;
  final ImportResult? importResult;

  const FieldMappingState({
    this.currentStep = FieldMappingStep.upload,
    this.selectedFile,
    this.preview,
    this.loadingPhase = LoadingPhase.none,
    this.error,
    this.activeMappings = const {},
    this.savedConfigurations = const [],
    this.selectedConfiguration,
    this.saveConfigOnImport = false,
    this.saveConfigName = '',
    this.saveConfigAsDefault = false,
    this.importResult,
  });

  FieldMappingState copyWith({
    FieldMappingStep? currentStep,
    File? selectedFile,
    FieldMappingPreview? preview,
    LoadingPhase? loadingPhase,
    String? error,
    Map<String, String?>? activeMappings,
    List<MappingConfiguration>? savedConfigurations,
    MappingConfiguration? selectedConfiguration,
    bool clearSelectedConfiguration = false,
    bool? saveConfigOnImport,
    String? saveConfigName,
    bool? saveConfigAsDefault,
    ImportResult? importResult,
    bool clearImportResult = false,
    bool clearError = false,
    bool clearPreview = false,
  }) {
    return FieldMappingState(
      currentStep: currentStep ?? this.currentStep,
      selectedFile: selectedFile ?? this.selectedFile,
      preview: clearPreview ? null : (preview ?? this.preview),
      loadingPhase: loadingPhase ?? this.loadingPhase,
      error: clearError ? null : (error ?? this.error),
      activeMappings: activeMappings ?? this.activeMappings,
      savedConfigurations: savedConfigurations ?? this.savedConfigurations,
      selectedConfiguration: clearSelectedConfiguration
          ? null
          : (selectedConfiguration ?? this.selectedConfiguration),
      saveConfigOnImport: saveConfigOnImport ?? this.saveConfigOnImport,
      saveConfigName: saveConfigName ?? this.saveConfigName,
      saveConfigAsDefault: saveConfigAsDefault ?? this.saveConfigAsDefault,
      importResult:
          clearImportResult ? null : (importResult ?? this.importResult),
    );
  }

  // ── Derived helpers ──────────────────────────────────────

  /// True when fullName is mapped (the only required field)
  bool get isFullNameMapped =>
      activeMappings.values.any((v) => v == 'fullName');

  /// All confirmed (non-null) mappings as a list
  List<FieldMapping> get confirmedMappings => activeMappings.entries
      .where((e) => e.value != null && e.value!.isNotEmpty)
      .map((e) => FieldMapping(csvColumn: e.key, modelField: e.value!))
      .toList();

  /// CSV columns not mapped to any model field
  List<String> get unmappedCsvColumns => activeMappings.entries
      .where((e) => e.value == null || e.value!.isEmpty)
      .map((e) => e.key)
      .toList();

  bool get isLoading => loadingPhase != LoadingPhase.none;
}

// ─────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────

class FieldMappingNotifier extends StateNotifier<FieldMappingState> {
  FieldMappingNotifier() : super(const FieldMappingState());

  // ── Navigation ────────────────────────────────────────────

  void goToStep(FieldMappingStep step) {
    state = state.copyWith(currentStep: step, clearError: true);
  }

  void reset() {
    state = const FieldMappingState();
  }

  // ── Step 1: File Selection & Preview ──────────────────────

  /// Called when the user picks a file. Immediately triggers preview API.
  Future<void> onFileSelected({
    required File file,
    required String type,
  }) async {
    state = state.copyWith(
      selectedFile: file,
      loadingPhase: LoadingPhase.preview,
      clearPreview: true,
      clearError: true,
    );

    try {
      final res = await FieldMappingAPI.previewFile(file: file);

      if (res['success'] != true) {
        state = state.copyWith(
          loadingPhase: LoadingPhase.none,
          error: res['message'] ?? 'Failed to analyze file',
        );
        return;
      }

      // Unwrap backend wrapper (supports both { data: {...} } and flat)
      final raw = res['data'];
      final dataMap = raw is Map<String, dynamic>
          ? (raw['data'] is Map<String, dynamic>
              ? raw['data'] as Map<String, dynamic>
              : raw)
          : <String, dynamic>{};

      final preview = FieldMappingPreview.fromJson(dataMap);

      // Build initial mappings from suggestions
      final initialMappings = <String, String?>{};
      for (final col in preview.csvColumns) {
        initialMappings[col] = null;
      }
      for (final s in preview.suggestedMappings) {
        if (s.modelField != null && s.modelField!.isNotEmpty) {
          initialMappings[s.csvColumn] = s.modelField;
        }
      }

      state = state.copyWith(
        preview: preview,
        activeMappings: initialMappings,
        loadingPhase: LoadingPhase.none,
        clearError: true,
      );

      // Also load saved configurations in parallel
      unawaited(_loadConfigurations(type));
    } catch (e) {
      debugPrint('❌ onFileSelected error: $e');
      state = state.copyWith(
        loadingPhase: LoadingPhase.none,
        error: 'Error analyzing file: $e',
      );
    }
  }

  // ── Step 2: Mapping Management ────────────────────────────

  void updateMapping(String csvColumn, String? modelField) {
    final updated = Map<String, String?>.from(state.activeMappings);
    // Prevent duplicate model field assignments (except unmapping)
    if (modelField != null && modelField.isNotEmpty) {
      updated.forEach((col, field) {
        if (field == modelField && col != csvColumn) {
          updated[col] = null; // unmap the old column that had this field
        }
      });
    }
    updated[csvColumn] = modelField;
    state = state.copyWith(activeMappings: updated);
  }

  Future<void> _loadConfigurations(String type) async {
    try {
      final res = await FieldMappingAPI.getConfigurations(type: type);
      if (res['success'] == true) {
        final raw = res['data'];
        final list = raw is Map<String, dynamic>
            ? (raw['data'] as List<dynamic>? ?? [])
            : (raw as List<dynamic>? ?? []);

        final configs = list
            .map(
                (e) => MappingConfiguration.fromJson(e as Map<String, dynamic>))
            .toList();

        // Auto-apply default if available
        final defaultConfig = configs.where((c) => c.isDefault).firstOrNull;

        if (defaultConfig != null && state.preview != null) {
          _applyConfiguration(defaultConfig);
        }

        state = state.copyWith(savedConfigurations: configs);
      }
    } catch (e) {
      debugPrint('⚠️ Could not load configurations: $e');
    }
  }

  void applyConfiguration(MappingConfiguration config) {
    _applyConfiguration(config);
    state = state.copyWith(selectedConfiguration: config);
  }

  void _applyConfiguration(MappingConfiguration config) {
    final updated = Map<String, String?>.from(state.activeMappings);
    // Reset existing
    for (final key in updated.keys) {
      updated[key] = null;
    }
    // Apply saved mappings (only if CSV column exists in current file)
    for (final m in config.mappings) {
      if (updated.containsKey(m.csvColumn)) {
        updated[m.csvColumn] = m.modelField;
      }
    }
    state = state.copyWith(activeMappings: updated);
  }

  Future<String?> saveCurrentConfiguration({
    required String name,
    required String type,
    bool isDefault = false,
  }) async {
    if (name.trim().isEmpty) return 'Configuration name is required';
    if (!state.isFullNameMapped) return 'Map the Full Name field first';

    state = state.copyWith(loadingPhase: LoadingPhase.savingConfig);

    try {
      final res = await FieldMappingAPI.saveConfiguration(
        configurationName: name.trim(),
        type: type,
        mappings: state.confirmedMappings,
        isDefault: isDefault,
      );

      if (res['success'] == true) {
        await _loadConfigurations(type);
        state = state.copyWith(loadingPhase: LoadingPhase.none);
        return null; // success
      }

      state = state.copyWith(loadingPhase: LoadingPhase.none);
      return res['message'] ?? 'Failed to save configuration';
    } catch (e) {
      state = state.copyWith(loadingPhase: LoadingPhase.none);
      return 'Error: $e';
    }
  }

  // ── Step 3: Review toggles ────────────────────────────────

  void setSaveConfigOnImport(bool value) {
    state = state.copyWith(saveConfigOnImport: value);
  }

  void setSaveConfigName(String value) {
    state = state.copyWith(saveConfigName: value);
  }

  void setSaveConfigAsDefault(bool value) {
    state = state.copyWith(saveConfigAsDefault: value);
  }

  void setImporting(bool value) {
    state = state.copyWith(
      loadingPhase: value ? LoadingPhase.importing : LoadingPhase.none,
      clearError: value,
    );
  }

  // ── Import ────────────────────────────────────────────────

  /// Main import action. Returns null on success, error string on failure.
  Future<String?> importData({
    required String type,
    String? siteId,
  }) async {
    if (state.selectedFile == null) return 'No file selected';
    if (!state.isFullNameMapped) return 'Full Name must be mapped';

    state = state.copyWith(
      loadingPhase: LoadingPhase.importing,
      clearError: true,
    );

    try {
      // Optionally save config before import
      if (state.saveConfigOnImport && state.saveConfigName.isNotEmpty) {
        await FieldMappingAPI.saveConfiguration(
          configurationName: state.saveConfigName,
          type: type,
          mappings: state.confirmedMappings,
          isDefault: state.saveConfigAsDefault,
        );
      }

      final res = await FieldMappingAPI.importWithMapping(
        file: state.selectedFile!,
        type: type,
        mappings: state.confirmedMappings,
        siteId: siteId,
      );

      state = state.copyWith(loadingPhase: LoadingPhase.none);

      if (res['success'] == true) {
        final raw = res['data'];
        final dataMap = raw is Map<String, dynamic>
            ? (raw['data'] is Map<String, dynamic>
                ? raw['data'] as Map<String, dynamic>
                : raw)
            : <String, dynamic>{};
        final result = ImportResult.fromJson(dataMap);
        state = state.copyWith(importResult: result);
        return null; // success
      }

      return res['message'] ?? 'Import failed';
    } catch (e) {
      state = state.copyWith(loadingPhase: LoadingPhase.none);
      return 'Error: $e';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────

final fieldMappingProvider =
    StateNotifierProvider.autoDispose<FieldMappingNotifier, FieldMappingState>(
  (ref) => FieldMappingNotifier(),
);

// ignore: nothing_to_inline
void unawaited(Future<void> future) {
  // fire-and-forget intentionally
}
