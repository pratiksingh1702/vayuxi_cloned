import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower Details/model/field_mapping_model.dart';

import '../../../../core/upload/manager/upload_manager.dart';
import '../../../../core/upload/models/upload_job.dart';
import '../../../../core/utlis/colors/colors.dart';
import '../../../../core/utlis/widgets/sidebar.dart';
import '../../../../typeProvider/type_provider.dart';
import '../../../modules/all_Modules/dpr/screens/work_type.dart';
import '../../../modules/all_Modules/site_Details/providers/siteProvider.dart';
import '../../../modules/all_Modules/site_Details/repository/siteModel.dart';
import '../../application/providers/automated_entry_controller.dart';
import '../../domain/models/automated_entry_models.dart';

class AutomatedEntryScreen extends ConsumerStatefulWidget {
  const AutomatedEntryScreen({super.key});

  @override
  ConsumerState<AutomatedEntryScreen> createState() =>
      _AutomatedEntryScreenState();
}

class _AutomatedEntryScreenState extends ConsumerState<AutomatedEntryScreen> {
  bool _siteHydrated = false;
  int _currentStep = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_siteHydrated) return;
    _siteHydrated = true;
    Future.microtask(() => ref.read(siteProvider.notifier).fetchSites());
  }

  Future<void> _pickFile(AutomatedEntryModule module) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: module.allowedExtensions,
      allowMultiple: false,
      withData: false,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null || file.path!.isEmpty) return;

    await ref.read(automatedEntryControllerProvider.notifier).setFile(
          module: module,
          filePath: file.path!,
          fileName: file.name,
        );
  }

  bool _isStepValid(AutomatedEntryState state, int stepIndex) {
    final selectedType = ref.read(typeProvider);

    switch (stepIndex) {
      case 0:
        return WorkType.isValid(selectedType);
      case 1:
        return true;
      case 2:
        return true;
      case 3:
        return true;
      case 4:
        return WorkType.isValid(selectedType);
      default:
        return false;
    }
  }

  double _jobProgress(List<UploadJob> jobs, String? jobId) {
    if (jobId == null || jobId.isEmpty) return 0;
    for (final job in jobs) {
      if (job.jobId == jobId) return (job.progress as double?) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(automatedEntryControllerProvider);
    final flowController = ref.read(automatedEntryControllerProvider.notifier);
    final selectedType = ref.watch(typeProvider);
    final canSubmit = ref.watch(automatedEntryCanSubmitProvider) &&
        WorkType.isValid(selectedType);

    final siteState = ref.watch(siteProvider);
    final uploadJobs = ref.watch(uploadManagerProvider);
    final isUploading = flowState.phase == AutomatedEntryPhase.uploading;

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.lightBlue,
      appBar: _PremiumWizardAppBar(
        currentStep: _currentStep,
        totalSteps: 5,
        canClearDraft: !isUploading,
        onClearDraft: () {
          flowController.resetDraft();
          setState(() => _currentStep = 0);
        },
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F1FF), Color(0xFFF8FCFF), Color(0xFFE9F7EF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _WizardStepper(
                currentStep: _currentStep,
                onStepTap: (idx) {
                  if (idx <= _currentStep) {
                    setState(() => _currentStep = idx);
                  }
                },
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _StepBody(
                    key: ValueKey<int>(_currentStep),
                    step: _currentStep,
                    state: flowState,
                    selectedType: selectedType,
                    siteOptions: siteState.sites,
                    uploadJobs: uploadJobs,
                    onPickSiteFile: () => _pickFile(AutomatedEntryModule.site),
                    onPickRateFile: () => _pickFile(AutomatedEntryModule.rate),
                    onPickManpowerFile: () =>
                        _pickFile(AutomatedEntryModule.manpower),
                    onClearFile: flowController.clearFile,
                    onSetBinding: flowController.setSiteBinding,
                    onSetExistingSite: flowController.setExistingSiteId,
                    onUpdateManpowerMapping:
                        flowController.updateManpowerMapping,
                    onApplyManpowerConfig:
                        flowController.applyManpowerSavedConfig,
                    onToggleModuleEnabled: flowController.setModuleEnabled,
                    onSelectType: (type) =>
                        ref.read(typeProvider.notifier).setType(type),
                    progressFor: (jobId) => _jobProgress(uploadJobs, jobId),
                  ),
                ),
              ),
              _WizardBottomBar(
                currentStep: _currentStep,
                isUploading: isUploading,
                canProceed: _isStepValid(flowState, _currentStep),
                canSubmit: canSubmit,
                onBack: _currentStep == 0
                    ? null
                    : () => setState(() => _currentStep -= 1),
                onNext: () async {
                  if (_currentStep == 0) {
                    setState(() => _currentStep = 1);
                    return;
                  }

                  if (_currentStep < 4) {
                    if (_isStepValid(flowState, _currentStep)) {
                      setState(() => _currentStep += 1);
                    }
                    return;
                  }

                  if (!canSubmit) return;
                  await flowController.submit();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumWizardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _PremiumWizardAppBar({
    required this.currentStep,
    required this.totalSteps,
    required this.canClearDraft,
    required this.onClearDraft,
  });

  final int currentStep;
  final int totalSteps;
  final bool canClearDraft;
  final VoidCallback onClearDraft;

  @override
  Size get preferredSize => const Size.fromHeight(82);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      toolbarHeight: 82,
      backgroundColor: Colors.transparent,
      leadingWidth: 64,
      leading: Builder(
        builder: (ctx) {
          return IconButton(
            onPressed: () => Scaffold.maybeOf(ctx)?.openDrawer(),
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD5E5FF)),
              ),
              child: const Icon(Icons.menu_rounded, color: Color(0xFF1D4B8F)),
            ),
          );
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Automated Entry Wizard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0C2C58),
            ),
          ),
          Text(
            'Step ${currentStep + 1} of $totalSteps',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF436B9B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            onPressed: canClearDraft ? onClearDraft : null,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0C2C58),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFD5E5FF)),
              ),
            ),
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text(
              'Clear Draft',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9FCFF), Color(0xFFEAF3FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}

class _WizardStepper extends StatelessWidget {
  const _WizardStepper({required this.currentStep, required this.onStepTap});

  final int currentStep;
  final ValueChanged<int> onStepTap;

  static const _labels = [
    'Intro',
    'Site',
    'Rate',
    'Manpower',
    'Review & Upload',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < _labels.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onStepTap(i),
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: i == currentStep
                          ? const Color(0xFF0F4EA8)
                          : (i < currentStep
                              ? const Color(0xFF0D7A46)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: i == currentStep
                            ? const Color(0xFF0F4EA8)
                            : const Color(0xFFD6E5FF),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          i < currentStep
                              ? Icons.check_circle
                              : Icons.radio_button_checked,
                          size: 14,
                          color: i <= currentStep
                              ? Colors.white
                              : const Color(0xFF88A6D1),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _labels[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: i <= currentStep
                                ? Colors.white
                                : const Color(0xFF53749F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    super.key,
    required this.step,
    required this.state,
    required this.selectedType,
    required this.siteOptions,
    required this.uploadJobs,
    required this.onPickSiteFile,
    required this.onPickRateFile,
    required this.onPickManpowerFile,
    required this.onClearFile,
    required this.onSetBinding,
    required this.onSetExistingSite,
    required this.onUpdateManpowerMapping,
    required this.onApplyManpowerConfig,
    required this.onToggleModuleEnabled,
    required this.onSelectType,
    required this.progressFor,
  });

  final int step;
  final AutomatedEntryState state;
  final String? selectedType;
  final List<SiteModel> siteOptions;
  final List<UploadJob> uploadJobs;
  final VoidCallback onPickSiteFile;
  final VoidCallback onPickRateFile;
  final VoidCallback onPickManpowerFile;
  final ValueChanged<AutomatedEntryModule> onClearFile;
  final void Function(AutomatedEntryModule, SiteBindingMode) onSetBinding;
  final void Function(AutomatedEntryModule, String?) onSetExistingSite;
  final void Function({required String csvColumn, required String? modelField})
      onUpdateManpowerMapping;
  final ValueChanged<String?> onApplyManpowerConfig;
  final void Function(AutomatedEntryModule, bool) onToggleModuleEnabled;
  final ValueChanged<String> onSelectType;
  final double Function(String? jobId) progressFor;

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 0:
        return _IntroStep(
          state: state,
          selectedType: selectedType,
          onSelectType: onSelectType,
        );
      case 1:
        return _ModuleStepCard(
          title: 'Step 2: Site File Import',
          subtitle:
              'Upload your Site file first. This can create a new site used by downstream modules.',
          module: state.draftOf(AutomatedEntryModule.site),
          siteOptions: siteOptions,
          onPickFile: onPickSiteFile,
          onClear: () => onClearFile(AutomatedEntryModule.site),
          onSetBinding: null,
          onSetSite: null,
          onToggleEnabled: (enabled) =>
              onToggleModuleEnabled(AutomatedEntryModule.site, enabled),
          progress: progressFor(state.draftOf(AutomatedEntryModule.site).jobId),
        );
      case 2:
        return _ModuleStepCard(
          title: 'Step 3: Rate File Import',
          subtitle:
              'Choose file and target site. Rate can use existing site or the site created in this flow.',
          module: state.draftOf(AutomatedEntryModule.rate),
          siteOptions: siteOptions,
          onPickFile: onPickRateFile,
          onClear: () => onClearFile(AutomatedEntryModule.rate),
          onSetBinding: (mode) => onSetBinding(AutomatedEntryModule.rate, mode),
          onSetSite: (id) => onSetExistingSite(AutomatedEntryModule.rate, id),
          onToggleEnabled: (enabled) =>
              onToggleModuleEnabled(AutomatedEntryModule.rate, enabled),
          progress: progressFor(state.draftOf(AutomatedEntryModule.rate).jobId),
        );
      case 3:
        return _ManpowerStep(
          module: state.draftOf(AutomatedEntryModule.manpower),
          siteOptions: siteOptions,
          onPickFile: onPickManpowerFile,
          onClear: () => onClearFile(AutomatedEntryModule.manpower),
          onSetBinding: (mode) =>
              onSetBinding(AutomatedEntryModule.manpower, mode),
          onSetSite: (id) =>
              onSetExistingSite(AutomatedEntryModule.manpower, id),
          onUpdateMapping: onUpdateManpowerMapping,
          onApplyConfig: onApplyManpowerConfig,
          onToggleEnabled: (enabled) =>
              onToggleModuleEnabled(AutomatedEntryModule.manpower, enabled),
          progress:
              progressFor(state.draftOf(AutomatedEntryModule.manpower).jobId),
        );
      case 4:
      default:
        return _FinalReviewStep(
          state: state,
          progressFor: progressFor,
        );
    }
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({
    required this.state,
    required this.selectedType,
    required this.onSelectType,
  });

  final AutomatedEntryState state;
  final String? selectedType;
  final ValueChanged<String> onSelectType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFCFE0FF)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B2E65).withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fast Entry Experience',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0C2F62),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This guided 5-step flow helps you upload Site, Rate, and Manpower with smart dependency handling and integrated manpower mapping.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF3A5E8E),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Work Type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF214D84),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              selected: {
                if (selectedType != null) selectedType!,
              },
              segments: const [
                ButtonSegment(
                  value: WorkType.mechanical,
                  label: Text('Mechanical'),
                ),
                ButtonSegment(
                  value: WorkType.insulation,
                  label: Text('Insulation'),
                ),
              ],
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  onSelectType(selection.first);
                }
              },
            ),
            const SizedBox(height: 16),
            const _GuidePoint(
              label: 'Step 1: Understand flow and start fresh',
            ),
            const _GuidePoint(
              label: 'Step 2: Upload Site file',
            ),
            const _GuidePoint(
              label: 'Step 3: Upload Rate file + choose site binding',
            ),
            const _GuidePoint(
              label: 'Step 4: Upload Manpower + map columns',
            ),
            const _GuidePoint(
              label: 'Step 5: Review all files and run upload',
            ),
            const SizedBox(height: 16),
            if (state.message != null && state.message!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.message!,
                  style: const TextStyle(
                    color: Color(0xFF1C4A89),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuidePoint extends StatelessWidget {
  const _GuidePoint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 18, color: Color(0xFF0E6E3E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B4F7E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleStepCard extends StatelessWidget {
  const _ModuleStepCard({
    required this.title,
    required this.subtitle,
    required this.module,
    required this.siteOptions,
    required this.onPickFile,
    required this.onClear,
    required this.onSetBinding,
    required this.onSetSite,
    required this.onToggleEnabled,
    required this.progress,
  });

  final String title;
  final String subtitle;
  final ModuleDraft module;
  final List<SiteModel> siteOptions;
  final VoidCallback onPickFile;
  final VoidCallback onClear;
  final ValueChanged<SiteBindingMode>? onSetBinding;
  final ValueChanged<String?>? onSetSite;
  final ValueChanged<bool> onToggleEnabled;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD6E5FF)),
        ),
        child: ListView(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF11396F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF486A97),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: module.enabled,
              title: const Text('Include This Module'),
              subtitle:
                  const Text('Disabled modules are skipped during upload.'),
              onChanged: onToggleEnabled,
            ),
            if (!module.enabled)
              const Padding(
                padding: EdgeInsets.only(top: 2, bottom: 8),
                child: Text(
                  'This module is optional and no API will be called for it.',
                  style: TextStyle(
                    color: Color(0xFF5C7392),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (!module.enabled) ...[
              if (module.errorMessage != null &&
                  module.errorMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    module.errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFC23A2C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (progress > 0) ...[
                const SizedBox(height: 14),
                LinearProgressIndicator(value: progress),
              ],
            ],
            if (module.enabled) ...[
              const SizedBox(height: 14),
              _FileTile(
                  module: module, onPickFile: onPickFile, onClear: onClear),
              if (module.module.canUseUploadedSite) ...[
                const SizedBox(height: 14),
                SegmentedButton<SiteBindingMode>(
                  selected: {module.siteBindingMode},
                  segments: const [
                    ButtonSegment(
                      value: SiteBindingMode.uploadedInThisFlow,
                      label: Text('Use New Site'),
                    ),
                    ButtonSegment(
                      value: SiteBindingMode.existingSite,
                      label: Text('Use Existing Site'),
                    ),
                  ],
                  onSelectionChanged: (selection) {
                    onSetBinding?.call(selection.first);
                  },
                ),
                if (module.siteBindingMode == SiteBindingMode.existingSite)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: DropdownButtonFormField<String>(
                      value: module.selectedExistingSiteId,
                      decoration: const InputDecoration(
                        labelText: 'Select Existing Site',
                        border: OutlineInputBorder(),
                      ),
                      items: siteOptions
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(s.siteName),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: onSetSite,
                    ),
                  ),
              ],
              if (module.errorMessage != null &&
                  module.errorMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    module.errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFC23A2C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (progress > 0) ...[
                const SizedBox(height: 14),
                LinearProgressIndicator(value: progress),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ManpowerStep extends StatelessWidget {
  const _ManpowerStep({
    required this.module,
    required this.siteOptions,
    required this.onPickFile,
    required this.onClear,
    required this.onSetBinding,
    required this.onSetSite,
    required this.onUpdateMapping,
    required this.onApplyConfig,
    required this.onToggleEnabled,
    required this.progress,
  });

  final ModuleDraft module;
  final List<SiteModel> siteOptions;
  final VoidCallback onPickFile;
  final VoidCallback onClear;
  final ValueChanged<SiteBindingMode> onSetBinding;
  final ValueChanged<String?> onSetSite;
  final void Function({required String csvColumn, required String? modelField})
      onUpdateMapping;
  final ValueChanged<String?> onApplyConfig;
  final ValueChanged<bool> onToggleEnabled;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD6E5FF)),
        ),
        child: ListView(
          children: [
            const Text(
              'Step 4: Manpower with Mapping',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF11396F),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload manpower file, choose site binding, and map columns before final upload.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF486A97),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: module.enabled,
              title: const Text('Include This Module'),
              subtitle:
                  const Text('Disabled modules are skipped during upload.'),
              onChanged: onToggleEnabled,
            ),
            if (!module.enabled)
              const Padding(
                padding: EdgeInsets.only(top: 2, bottom: 8),
                child: Text(
                  'This module is optional and no API will be called for it.',
                  style: TextStyle(
                    color: Color(0xFF5C7392),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (module.enabled) ...[
              const SizedBox(height: 12),
              _FileTile(
                  module: module, onPickFile: onPickFile, onClear: onClear),
              const SizedBox(height: 12),
              SegmentedButton<SiteBindingMode>(
                selected: {module.siteBindingMode},
                segments: const [
                  ButtonSegment(
                    value: SiteBindingMode.uploadedInThisFlow,
                    label: Text('Use New Site'),
                  ),
                  ButtonSegment(
                    value: SiteBindingMode.existingSite,
                    label: Text('Use Existing Site'),
                  ),
                ],
                onSelectionChanged: (selection) =>
                    onSetBinding(selection.first),
              ),
              if (module.siteBindingMode == SiteBindingMode.existingSite)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: DropdownButtonFormField<String>(
                    value: module.selectedExistingSiteId,
                    decoration: const InputDecoration(
                      labelText: 'Select Existing Site',
                      border: OutlineInputBorder(),
                    ),
                    items: siteOptions
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s.id,
                            child: Text(s.siteName),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: onSetSite,
                  ),
                ),
              const SizedBox(height: 14),
              if (module.manpowerSavedConfigs.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: module.selectedManpowerConfigId,
                  decoration: const InputDecoration(
                    labelText: 'Apply Saved Mapping',
                    border: OutlineInputBorder(),
                  ),
                  items: module.manpowerSavedConfigs
                      .map(
                        (config) => DropdownMenuItem<String>(
                          value: config.id,
                          child: Text(config.configurationName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: onApplyConfig,
                ),
              const SizedBox(height: 14),
              if (module.manpowerPreviewLoading)
                const Center(child: CircularProgressIndicator()),
              if (module.manpowerMappingError != null &&
                  module.manpowerMappingError!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFC4B3)),
                  ),
                  child: Text(
                    module.manpowerMappingError!,
                    style: const TextStyle(
                      color: Color(0xFFB7412A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (!module.manpowerPreviewLoading)
                ...module.manpowerCsvColumns.map(
                  (csv) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MappingRowCard(
                      csvColumn: csv,
                      modelFields: module.manpowerModelFields,
                      selectedField: module.manpowerMappings[csv],
                      onChanged: (field) => onUpdateMapping(
                        csvColumn: csv,
                        modelField: field,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TinyMetric(
                    label: '${module.manpowerCsvColumns.length} columns',
                    color: const Color(0xFF1456C6),
                  ),
                  _TinyMetric(
                    label: '${module.autoMappingCoverageCount} mapped',
                    color: const Color(0xFF097657),
                  ),
                  _TinyMetric(
                    label: module.isFullNameMapped
                        ? 'Full Name mapped'
                        : 'Full Name required',
                    color: module.isFullNameMapped
                        ? const Color(0xFF0B7A3C)
                        : const Color(0xFFC9342A),
                  ),
                ],
              ),
              if (progress > 0) ...[
                const SizedBox(height: 14),
                LinearProgressIndicator(value: progress),
              ],
            ],
            if (!module.enabled && progress > 0) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(value: progress),
            ],
          ],
        ),
      ),
    );
  }
}

class _FinalReviewStep extends StatelessWidget {
  const _FinalReviewStep({
    required this.state,
    required this.progressFor,
  });

  final AutomatedEntryState state;
  final double Function(String? jobId) progressFor;

  @override
  Widget build(BuildContext context) {
    final site = state.draftOf(AutomatedEntryModule.site);
    final rate = state.draftOf(AutomatedEntryModule.rate);
    final manpower = state.draftOf(AutomatedEntryModule.manpower);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD6E5FF)),
        ),
        child: ListView(
          children: [
            const Text(
              'Step 5: Review and Upload',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF11396F),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Verify selected files, site bindings, and manpower mapping readiness before final submission.',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF486A97), height: 1.4),
            ),
            const SizedBox(height: 14),
            _ReviewTile(
              title: 'Site',
              fileName: site.fileName,
              details: 'Creates/updates site context for dependent modules.',
              progress: progressFor(site.jobId),
            ),
            _ReviewTile(
              title: 'Rate',
              fileName: rate.fileName,
              details: rate.siteBindingMode == SiteBindingMode.existingSite
                  ? 'Uses selected existing site.'
                  : 'Uses site created in this flow.',
              progress: progressFor(rate.jobId),
            ),
            _ReviewTile(
              title: 'Manpower',
              fileName: manpower.fileName,
              details:
                  '${manpower.confirmedManpowerMappings.length} mapped fields | ${manpower.isFullNameMapped ? 'Full Name mapped' : 'Full Name missing'}',
              progress: progressFor(manpower.jobId),
            ),
            if (state.createdSiteId != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Created Site ID: ${state.createdSiteId}',
                  style: const TextStyle(
                    color: Color(0xFF1D4C8F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (state.message != null && state.message!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF7FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    state.message!,
                    style: const TextStyle(
                      color: Color(0xFF1E4D8A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.title,
    required this.fileName,
    required this.details,
    required this.progress,
  });

  final String title;
  final String? fileName;
  final String details;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5E4FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF123F7D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fileName ?? 'No file selected',
            style: TextStyle(
              color: fileName == null
                  ? const Color(0xFF9CAEC8)
                  : const Color(0xFF1A4E96),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(details,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4C6E99))),
          if (progress > 0) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
          ],
        ],
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.module,
    required this.onPickFile,
    required this.onClear,
  });

  final ModuleDraft module;
  final VoidCallback onPickFile;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD5E4FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.file_present_rounded, color: Color(0xFF2257A0)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              module.fileName ?? 'No file selected',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: module.fileName == null
                    ? const Color(0xFF7B95BA)
                    : const Color(0xFF1A4D94),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onPickFile,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(module.fileName == null ? 'Choose' : 'Change'),
          ),
          if (module.fileName != null)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

class _MappingRowCard extends StatelessWidget {
  const _MappingRowCard({
    required this.csvColumn,
    required this.modelFields,
    required this.selectedField,
    required this.onChanged,
  });

  final String csvColumn;
  final List<ModelField> modelFields;
  final String? selectedField;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            csvColumn,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF174886),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedField?.isEmpty ?? true ? null : selectedField,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select model field',
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Ignore this column'),
              ),
              ...modelFields.map(
                (field) => DropdownMenuItem<String>(
                  value: field.field,
                  child: Text(field.label),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TinyMetric extends StatelessWidget {
  const _TinyMetric({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _WizardBottomBar extends StatelessWidget {
  const _WizardBottomBar({
    required this.currentStep,
    required this.isUploading,
    required this.canProceed,
    required this.canSubmit,
    required this.onBack,
    required this.onNext,
  });

  final int currentStep;
  final bool isUploading;
  final bool canProceed;
  final bool canSubmit;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  String get _nextLabel {
    switch (currentStep) {
      case 0:
        return 'Start Wizard';
      case 1:
        return 'Continue to Rate';
      case 2:
        return 'Continue to Manpower';
      case 3:
        return 'Continue to Review';
      case 4:
      default:
        return isUploading ? 'Uploading...' : 'Upload All';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryEnabled =
        currentStep == 4 ? canSubmit && !isUploading : canProceed;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onBack != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isUploading ? null : onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
              ),
            ),
          if (onBack != null) const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: primaryEnabled ? onNext : null,
              icon: isUploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(currentStep == 4
                      ? Icons.rocket_launch_rounded
                      : Icons.arrow_forward_rounded),
              label: Text(_nextLabel),
            ),
          ),
        ],
      ),
    );
  }
}
