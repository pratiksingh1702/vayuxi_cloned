import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower Details/model/field_mapping_model.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower Details/service/field_api_service.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../../domain/models/automated_entry_models.dart';
import '../orchestration/automated_entry_orchestrator.dart';

final automatedEntryControllerProvider =
    NotifierProvider<AutomatedEntryController, AutomatedEntryState>(
  AutomatedEntryController.new,
);

final automatedEntryCanSubmitProvider = Provider<bool>((ref) {
  return ref.watch(automatedEntryControllerProvider).canSubmit;
});

class AutomatedEntryController extends Notifier<AutomatedEntryState> {
  @override
  AutomatedEntryState build() => AutomatedEntryState.initial();

  Future<void> setFile({
    required AutomatedEntryModule module,
    required String filePath,
    required String fileName,
  }) async {
    _mutateDraft(
      module,
      (draft) => draft.copyWith(
        filePath: filePath,
        fileName: fileName,
        runState: ModuleRunState.ready,
        clearError: true,
        clearManpowerMappingError: true,
      ),
    );

    if (module == AutomatedEntryModule.manpower) {
      await _prepareManpowerMapping(filePath: filePath);
    }
  }

  void clearFile(AutomatedEntryModule module) {
    _mutateDraft(
      module,
      (draft) => draft.copyWith(
        clearFile: true,
        runState: ModuleRunState.idle,
        clearError: true,
        manpowerMappings: const {},
        manpowerModelFields: const [],
        manpowerCsvColumns: const [],
        manpowerSavedConfigs: const [],
        clearManpowerConfigSelection: true,
        clearManpowerMappingError: true,
      ),
    );
  }

  void setModuleEnabled(AutomatedEntryModule module, bool enabled) {
    _mutateDraft(
      module,
      (draft) => draft.copyWith(
        enabled: enabled,
        clearError: true,
        clearManpowerMappingError: true,
      ),
    );
  }

  void setSiteBinding(
    AutomatedEntryModule module,
    SiteBindingMode mode,
  ) {
    _mutateDraft(
      module,
      (draft) => draft.copyWith(
        siteBindingMode: mode,
        selectedExistingSiteId: mode == SiteBindingMode.existingSite
            ? draft.selectedExistingSiteId
            : null,
        clearError: true,
      ),
    );
  }

  void setExistingSiteId(
    AutomatedEntryModule module,
    String? siteId,
  ) {
    _mutateDraft(
      module,
      (draft) => draft.copyWith(
        selectedExistingSiteId: siteId,
        clearError: true,
      ),
    );
  }

  void updateManpowerMapping({
    required String csvColumn,
    required String? modelField,
  }) {
    _mutateDraft(AutomatedEntryModule.manpower, (draft) {
      final updated = Map<String, String?>.from(draft.manpowerMappings);

      if (modelField != null && modelField.isNotEmpty) {
        for (final entry in updated.entries.toList(growable: false)) {
          if (entry.key != csvColumn && entry.value == modelField) {
            updated[entry.key] = null;
          }
        }
      }

      updated[csvColumn] = modelField;

      return draft.copyWith(
        manpowerMappings: updated,
        clearManpowerConfigSelection: true,
        clearManpowerMappingError: true,
      );
    });
  }

  void applyManpowerSavedConfig(String? configId) {
    if (configId == null || configId.isEmpty) return;

    _mutateDraft(AutomatedEntryModule.manpower, (draft) {
      final selected =
          draft.manpowerSavedConfigs.where((c) => c.id == configId).firstOrNull;
      if (selected == null) return draft;

      final updated = <String, String?>{
        for (final col in draft.manpowerCsvColumns) col: null,
      };

      for (final mapping in selected.mappings) {
        if (updated.containsKey(mapping.csvColumn)) {
          updated[mapping.csvColumn] = mapping.modelField;
        }
      }

      return draft.copyWith(
        manpowerMappings: updated,
        selectedManpowerConfigId: selected.id,
        clearManpowerMappingError: true,
      );
    });
  }

  Future<void> submit() async {
    if (!state.canSubmit) {
      state =
          state.copyWith(message: 'Complete all required fields to continue.');
      return;
    }

    state = state.copyWith(
      phase: AutomatedEntryPhase.uploading,
      clearMessage: true,
    );

    final orchestrator = ref.read(automatedEntryOrchestratorProvider);
    final result = await orchestrator.execute(state);

    final updatedDrafts =
        Map<AutomatedEntryModule, ModuleDraft>.from(state.drafts);
    for (final module in AutomatedEntryModule.values) {
      final success = result.moduleSuccess[module] ?? false;
      final message = result.errors[module];
      updatedDrafts[module] = updatedDrafts[module]!.copyWith(
        runState: success
            ? ModuleRunState.success
            : (message != null
                ? ModuleRunState.failed
                : ModuleRunState.blocked),
        errorMessage: message,
      );
    }

    final nextPhase = result.isAllSuccess
        ? AutomatedEntryPhase.completed
        : (result.hasPartialSuccess
            ? AutomatedEntryPhase.partialFailure
            : AutomatedEntryPhase.failed);

    state = state.copyWith(
      drafts: updatedDrafts,
      phase: nextPhase,
      createdSiteId: result.createdSiteId,
      message: _buildCompletionMessage(nextPhase),
    );
  }

  void resetDraft() {
    state = AutomatedEntryState.initial();
  }

  Future<void> _prepareManpowerMapping({required String filePath}) async {
    _mutateDraft(AutomatedEntryModule.manpower, (draft) {
      return draft.copyWith(
        manpowerPreviewLoading: true,
        manpowerMappingError: null,
        manpowerMappings: const {},
        manpowerModelFields: const [],
        manpowerCsvColumns: const [],
        clearManpowerConfigSelection: true,
      );
    });

    try {
      final res = await FieldMappingAPI.previewFile(file: File(filePath));

      if (res['success'] != true) {
        final message =
            res['message']?.toString() ?? 'Failed to preview manpower file';
        _mutateDraft(AutomatedEntryModule.manpower, (draft) {
          return draft.copyWith(
            manpowerPreviewLoading: false,
            manpowerMappingError: message,
          );
        });
        return;
      }

      final raw = res['data'];
      final dataMap = raw is Map<String, dynamic>
          ? (raw['data'] is Map<String, dynamic>
              ? raw['data'] as Map<String, dynamic>
              : raw)
          : <String, dynamic>{};

      final preview = FieldMappingPreview.fromJson(dataMap);
      final initialMappings = <String, String?>{
        for (final col in preview.csvColumns) col: null,
      };
      for (final suggestion in preview.suggestedMappings) {
        if (suggestion.modelField != null &&
            suggestion.modelField!.isNotEmpty) {
          initialMappings[suggestion.csvColumn] = suggestion.modelField;
        }
      }

      final type = ref.read(typeProvider);
      final configs = await _loadManpowerConfigurations(type: type);

      final defaultConfig = configs.where((c) => c.isDefault).firstOrNull;
      if (defaultConfig != null) {
        for (final mapping in defaultConfig.mappings) {
          if (initialMappings.containsKey(mapping.csvColumn)) {
            initialMappings[mapping.csvColumn] = mapping.modelField;
          }
        }
      }

      final hasFullName =
          initialMappings.values.any((field) => field == 'fullName');

      _mutateDraft(AutomatedEntryModule.manpower, (draft) {
        return draft.copyWith(
          manpowerPreviewLoading: false,
          manpowerMappings: initialMappings,
          manpowerModelFields: preview.modelFields,
          manpowerCsvColumns: preview.csvColumns,
          manpowerSavedConfigs: configs,
          selectedManpowerConfigId: defaultConfig?.id,
          manpowerMappingError: hasFullName
              ? null
              : 'Full Name mapping is required. Please configure mappings.',
        );
      });
    } catch (e) {
      debugPrint('[AutomatedEntry][manpower] mapping preview failed: $e');
      _mutateDraft(AutomatedEntryModule.manpower, (draft) {
        return draft.copyWith(
          manpowerPreviewLoading: false,
          manpowerMappingError: 'Error while analyzing manpower file: $e',
        );
      });
    }
  }

  Future<List<MappingConfiguration>> _loadManpowerConfigurations({
    required String? type,
  }) async {
    if (type == null || type.isEmpty) return const [];

    try {
      final res = await FieldMappingAPI.getConfigurations(type: type);
      if (res['success'] != true) return const [];

      final raw = res['data'];
      final list = raw is Map<String, dynamic>
          ? (raw['data'] as List<dynamic>? ?? const [])
          : (raw as List<dynamic>? ?? const []);

      return list
          .whereType<Map<String, dynamic>>()
          .map(MappingConfiguration.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  void _mutateDraft(
    AutomatedEntryModule module,
    ModuleDraft Function(ModuleDraft) updater,
  ) {
    final map = Map<AutomatedEntryModule, ModuleDraft>.from(state.drafts);
    map[module] = updater(map[module]!);
    state = state.copyWith(drafts: map, phase: AutomatedEntryPhase.drafting);
  }

  String _buildCompletionMessage(AutomatedEntryPhase phase) {
    switch (phase) {
      case AutomatedEntryPhase.completed:
        return 'All modules uploaded successfully.';
      case AutomatedEntryPhase.partialFailure:
        return 'Some modules failed. Review module cards and retry selectively.';
      case AutomatedEntryPhase.failed:
        return 'Upload failed for all modules. Check network and file validation.';
      case AutomatedEntryPhase.drafting:
      case AutomatedEntryPhase.uploading:
        return '';
    }
  }
}
