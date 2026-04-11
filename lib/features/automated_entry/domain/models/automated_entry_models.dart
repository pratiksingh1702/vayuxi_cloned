import '../../../modules/all_Modules/Manpower Details/model/field_mapping_model.dart';

enum AutomatedEntryModule { site, rate, manpower }

extension AutomatedEntryModuleX on AutomatedEntryModule {
  String get moduleId {
    switch (this) {
      case AutomatedEntryModule.site:
        return 'site';
      case AutomatedEntryModule.rate:
        return 'rate';
      case AutomatedEntryModule.manpower:
        return 'manpower';
    }
  }

  String get title {
    switch (this) {
      case AutomatedEntryModule.site:
        return 'Site';
      case AutomatedEntryModule.rate:
        return 'Rate';
      case AutomatedEntryModule.manpower:
        return 'Manpower';
    }
  }

  List<String> get allowedExtensions {
    switch (this) {
      case AutomatedEntryModule.site:
        return const ['csv', 'xlsx', 'pdf'];
      case AutomatedEntryModule.rate:
        return const ['csv', 'xlsx', 'pdf'];
      case AutomatedEntryModule.manpower:
        return const ['xlsx'];
    }
  }

  bool get canUseUploadedSite => this != AutomatedEntryModule.site;
}

enum SiteBindingMode {
  existingSite,
  uploadedInThisFlow,
}

enum ModuleRunState {
  idle,
  ready,
  waiting,
  queued,
  running,
  success,
  failed,
  blocked,
}

enum AutomatedEntryPhase {
  drafting,
  uploading,
  completed,
  partialFailure,
  failed,
}

class ModuleDraft {
  final AutomatedEntryModule module;
  final bool enabled;
  final String? filePath;
  final String? fileName;
  final SiteBindingMode siteBindingMode;
  final String? selectedExistingSiteId;
  final Map<String, String?> manpowerMappings;
  final List<ModelField> manpowerModelFields;
  final List<String> manpowerCsvColumns;
  final List<MappingConfiguration> manpowerSavedConfigs;
  final String? selectedManpowerConfigId;
  final bool manpowerPreviewLoading;
  final String? manpowerMappingError;
  final ModuleRunState runState;
  final String? errorMessage;
  final String? jobId;

  const ModuleDraft({
    required this.module,
    this.enabled = true,
    this.filePath,
    this.fileName,
    this.siteBindingMode = SiteBindingMode.uploadedInThisFlow,
    this.selectedExistingSiteId,
    this.manpowerMappings = const {},
    this.manpowerModelFields = const [],
    this.manpowerCsvColumns = const [],
    this.manpowerSavedConfigs = const [],
    this.selectedManpowerConfigId,
    this.manpowerPreviewLoading = false,
    this.manpowerMappingError,
    this.runState = ModuleRunState.idle,
    this.errorMessage,
    this.jobId,
  });

  bool get hasFile => filePath != null && filePath!.isNotEmpty;

  bool get needsExistingSiteSelection {
    if (!module.canUseUploadedSite) return false;
    return siteBindingMode == SiteBindingMode.existingSite;
  }

  bool get hasRequiredSiteSelection {
    if (!needsExistingSiteSelection) return true;
    return selectedExistingSiteId != null && selectedExistingSiteId!.isNotEmpty;
  }

  bool get isConfigValid => hasFile && hasRequiredSiteSelection;

  bool get isManpowerMappingRequired => module == AutomatedEntryModule.manpower;

  bool get isFullNameMapped =>
      manpowerMappings.values.any((field) => field == 'fullName');

  List<FieldMapping> get confirmedManpowerMappings {
    return manpowerMappings.entries
        .where((entry) => entry.value != null && entry.value!.isNotEmpty)
        .map(
          (entry) =>
              FieldMapping(csvColumn: entry.key, modelField: entry.value!),
        )
        .toList(growable: false);
  }

  int get autoMappingCoverageCount => confirmedManpowerMappings.length;

  bool get hasReadyManpowerMapping {
    if (!isManpowerMappingRequired) return true;
    return manpowerMappings.isNotEmpty &&
        confirmedManpowerMappings.isNotEmpty &&
        isFullNameMapped;
  }

  ModuleDraft copyWith({
    bool? enabled,
    String? filePath,
    String? fileName,
    SiteBindingMode? siteBindingMode,
    String? selectedExistingSiteId,
    Map<String, String?>? manpowerMappings,
    List<ModelField>? manpowerModelFields,
    List<String>? manpowerCsvColumns,
    List<MappingConfiguration>? manpowerSavedConfigs,
    String? selectedManpowerConfigId,
    bool? manpowerPreviewLoading,
    String? manpowerMappingError,
    ModuleRunState? runState,
    String? errorMessage,
    String? jobId,
    bool clearFile = false,
    bool clearError = false,
    bool clearJobId = false,
    bool clearManpowerMappingError = false,
    bool clearManpowerConfigSelection = false,
  }) {
    return ModuleDraft(
      module: module,
      enabled: enabled ?? this.enabled,
      filePath: clearFile ? null : (filePath ?? this.filePath),
      fileName: clearFile ? null : (fileName ?? this.fileName),
      siteBindingMode: siteBindingMode ?? this.siteBindingMode,
      selectedExistingSiteId:
          selectedExistingSiteId ?? this.selectedExistingSiteId,
      manpowerMappings: manpowerMappings ?? this.manpowerMappings,
      manpowerModelFields: manpowerModelFields ?? this.manpowerModelFields,
      manpowerCsvColumns: manpowerCsvColumns ?? this.manpowerCsvColumns,
      manpowerSavedConfigs: manpowerSavedConfigs ?? this.manpowerSavedConfigs,
      selectedManpowerConfigId: clearManpowerConfigSelection
          ? null
          : (selectedManpowerConfigId ?? this.selectedManpowerConfigId),
      manpowerPreviewLoading:
          manpowerPreviewLoading ?? this.manpowerPreviewLoading,
      manpowerMappingError: clearManpowerMappingError
          ? null
          : (manpowerMappingError ?? this.manpowerMappingError),
      runState: runState ?? this.runState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      jobId: clearJobId ? null : (jobId ?? this.jobId),
    );
  }
}

class AutomatedEntryState {
  final Map<AutomatedEntryModule, ModuleDraft> drafts;
  final AutomatedEntryPhase phase;
  final String? createdSiteId;
  final String? message;

  const AutomatedEntryState({
    required this.drafts,
    this.phase = AutomatedEntryPhase.drafting,
    this.createdSiteId,
    this.message,
  });

  factory AutomatedEntryState.initial() {
    return AutomatedEntryState(
      drafts: {
        for (final module in AutomatedEntryModule.values)
          module: ModuleDraft(module: module),
      },
    );
  }

  ModuleDraft draftOf(AutomatedEntryModule module) => drafts[module]!;

  bool get canSubmit {
    return phase != AutomatedEntryPhase.uploading;
  }

  AutomatedEntryState copyWith({
    Map<AutomatedEntryModule, ModuleDraft>? drafts,
    AutomatedEntryPhase? phase,
    String? createdSiteId,
    String? message,
    bool clearCreatedSiteId = false,
    bool clearMessage = false,
  }) {
    return AutomatedEntryState(
      drafts: drafts ?? this.drafts,
      phase: phase ?? this.phase,
      createdSiteId:
          clearCreatedSiteId ? null : (createdSiteId ?? this.createdSiteId),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}
