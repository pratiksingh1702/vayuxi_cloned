// ============================================================
// man_field_mapping_screen.dart
// Drop-in replacement for ManImportCsvScreen.
// 3-step vertical stepper: Upload → Map Fields → Review & Import
// ============================================================

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/model/field_mapping_model.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/screens/manpowerList.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/service/field_mapping_provider.dart';

import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../site_Details/providers/site_current_provider.dart';

import '../../../../../../typeProvider/type_provider.dart';
import '../../../../../../core/router/routes.dart';

// ─────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────

// ============================================================
// man_field_mapping_screen.dart
// Drop-in replacement for ManImportCsvScreen.
// 3-step vertical stepper: Upload → Map Fields → Review & Import
// ============================================================

import 'dart:convert';

import '../../../../../core/upload/manager/upload_manager.dart';
import '../../../../../core/upload/models/upload_job.dart';

import '../service/manpowerService.dart';

// ─────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────

class ManFieldMappingScreen extends ConsumerWidget {
  const ManFieldMappingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _ManFieldMappingView();
  }
}

class _ManFieldMappingView extends ConsumerStatefulWidget {
  const _ManFieldMappingView();

  @override
  ConsumerState<_ManFieldMappingView> createState() =>
      _ManFieldMappingViewState();
}

class _ManFieldMappingViewState extends ConsumerState<_ManFieldMappingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stepAnim;

  @override
  void initState() {
    super.initState();
    _stepAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
  }

  @override
  void dispose() {
    _stepAnim.dispose();
    super.dispose();
  }

  void _animateStep() {
    _stepAnim.reset();
    _stepAnim.forward();
  }

  // ── File picker ──────────────────────────────────────────

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final pf = result.files.first;
      if (pf.path == null || pf.path!.isEmpty) {
        _showSnack('Invalid file path. Pick from local storage.',
            isError: true);
        return;
      }
      final file = File(pf.path!);
      if (!file.existsSync()) {
        _showSnack('File not found on device.', isError: true);
        return;
      }

      final type = ref.read(typeProvider);
      if (type == null) {
        _showSnack('Manpower type not set.', isError: true);
        return;
      }

      await ref.read(fieldMappingProvider.notifier).onFileSelected(
            file: file,
            type: type,
          );
    } catch (e) {
      _showSnack('File pick error: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? colorScheme.error : colorScheme.primary,
    ));
  }

  // ── Step transitions ──────────────────────────────────────

  void _nextStep() {
    final notifier = ref.read(fieldMappingProvider.notifier);
    final state = ref.read(fieldMappingProvider);
    switch (state.currentStep) {
      case FieldMappingStep.upload:
        if (state.preview != null) {
          notifier.goToStep(FieldMappingStep.mapping);
          _animateStep();
        }
        break;
      case FieldMappingStep.mapping:
        if (state.isFullNameMapped) {
          notifier.goToStep(FieldMappingStep.review);
          _animateStep();
        } else {
          _showSnack('Please map the Full Name field first.', isError: true);
        }
        break;
      case FieldMappingStep.review:
        break;
    }
  }

  void _prevStep() {
    final state = ref.read(fieldMappingProvider);
    switch (state.currentStep) {
      case FieldMappingStep.upload:
        break;
      case FieldMappingStep.mapping:
        ref
            .read(fieldMappingProvider.notifier)
            .goToStep(FieldMappingStep.upload);
        _animateStep();
        break;
      case FieldMappingStep.review:
        ref
            .read(fieldMappingProvider.notifier)
            .goToStep(FieldMappingStep.mapping);
        _animateStep();
        break;
    }
  }

  /// Import flow — mirrors ManImportCsvScreen._onUploadPressed exactly:
  ///   1. analyzeExcel  (flexibleUploadExcel?analyze=true)
  ///   2. If errors → show analysis dialog, hard-stop
  ///   3. If clean   → optionally save config, then enqueue job via uploadManagerProvider
  Future<void> _doImport() async {
    final fmState = ref.read(fieldMappingProvider);
    final type = ref.read(typeProvider);
    final siteId = ref.read(selectedSiteIdProvider);

    if (type == null) {
      _showSnack('Manpower type not set.', isError: true);
      return;
    }
    if (fmState.selectedFile == null) {
      _showSnack('No file selected.', isError: true);
      return;
    }
    if (!fmState.isFullNameMapped) {
      _showSnack('Full Name must be mapped.', isError: true);
      return;
    }

    final notifier = ref.read(fieldMappingProvider.notifier);
    notifier.setImporting(true);

    try {
      // ── STEP 1: Analyze (same call as original: flexibleUploadExcel?analyze=true) ──
      final analyzeRes = await ManpowerAPI.analyzeExcel(
        file: fmState.selectedFile!,
        type: type,
      );

      if (analyzeRes['success'] != true) {
        notifier.setImporting(false);
        _showImportErrorDialog(analyzeRes['message'] ?? 'Analysis failed');
        return;
      }

      final dynamic rawPayload = analyzeRes['data'] ?? analyzeRes;
      final resData =
          rawPayload is Map<String, dynamic> ? rawPayload : <String, dynamic>{};

      final int errorCount = resData['errorCount'] is int
          ? resData['errorCount'] as int
          : int.tryParse('${resData['errorCount']}') ?? 0;
      final int successCount = resData['successCount'] is int
          ? resData['successCount'] as int
          : int.tryParse('${resData['successCount']}') ?? 0;
      final int totalRows = resData['totalRows'] is int
          ? resData['totalRows'] as int
          : int.tryParse('${resData['totalRows']}') ?? 0;

      final List<ExcelUploadIssue> errors = _extractIssues(resData);
      final List<String> suggestions = _extractSuggestions(resData);

      // ── STEP 2: Hard-stop on errors (same guard as original) ──
      if (errorCount > 0 || errors.isNotEmpty) {
        notifier.setImporting(false);
        _showAnalysisDialog(
          suggestions: suggestions,
          errors: errors,
          totalRows: totalRows,
          errorCount: errorCount,
          successCount: successCount,
        );
        return;
      }

      // Show suggestions dialog (non-blocking) if any
      if (suggestions.isNotEmpty) {
        _showAnalysisDialog(
          suggestions: suggestions,
          errors: const [],
          totalRows: totalRows,
          errorCount: 0,
          successCount: successCount,
        );
      }

      // ── STEP 3: Optionally save mapping config ──
      if (fmState.saveConfigOnImport && fmState.saveConfigName.isNotEmpty) {
        await notifier.saveCurrentConfiguration(
          name: fmState.saveConfigName,
          type: type,
          isDefault: fmState.saveConfigAsDefault,
        );
      }

      // ── STEP 4: Enqueue job (same as original _onUploadPressed) ──
      // Encode confirmed mappings into metadata so the upload worker
      // can forward them to /manpower/field-mapping/import.
      final mappingsJson = jsonEncode(
        fmState.confirmedMappings.map((m) => m.toJson()).toList(),
      );

      ref.read(uploadManagerProvider.notifier).enqueue(
            UploadJob.create(
              moduleId: 'manpower',
              filePath: fmState.selectedFile!.path,
              metadata: {
                'type': type,
                if (siteId != null && siteId.isNotEmpty) 'siteId': siteId,
                // JSON-encoded List<{csvColumn, modelField}> — read by ManpowerUploadHandler
                'mappings': mappingsJson,
              },
              targetRoute: Routes.manpowerList,
              maxRetries: 2,
            ),
          );

      notifier.setImporting(false);

      if (!mounted) return;
      _showSnack('Upload queued ✅ — you\'ll be notified when done.');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ManpowerListScreen()),
      );
    } catch (e) {
      notifier.setImporting(false);
      _showImportErrorDialog('Error: $e');
    }
  }

  // ── Helpers matching original ManImportCsvScreen ─────────────

  List<ExcelUploadIssue> _extractIssues(Map<String, dynamic> resData) {
    dynamic errors = resData['errors'];
    if (errors == null && resData['analysis'] is Map<String, dynamic>) {
      errors = (resData['analysis'] as Map<String, dynamic>)['errors'];
    }
    if (errors is! List) return [];
    return errors.map<ExcelUploadIssue>((e) {
      if (e is Map<String, dynamic>) {
        return ExcelUploadIssue(
          row: e['row'] is int ? e['row'] as int : int.tryParse('${e['row']}'),
          message: e['error']?.toString() ?? 'Unknown error',
        );
      }
      return ExcelUploadIssue(message: e.toString());
    }).toList();
  }

  List<String> _extractSuggestions(Map<String, dynamic> resData) {
    final out = <String>[];
    final analysis = resData['analysis'];
    if (analysis is Map<String, dynamic>) {
      final s = analysis['suggestions'];
      if (s is List) out.addAll(s.map((e) => e.toString()));
      final u = analysis['unmappedColumns'];
      if (u is List && u.isNotEmpty)
        out.add('Unmapped Columns: ${u.join(', ')}');
    }
    final root = resData['suggestions'];
    if (root is List) out.addAll(root.map((e) => e.toString()));
    return out;
  }

  void _showAnalysisDialog({
    required List<String> suggestions,
    required List<ExcelUploadIssue> errors,
    int? totalRows,
    int? errorCount,
    int? successCount,
  }) {
    final hasErrors = errors.isNotEmpty || (errorCount ?? 0) > 0;
    showDialog(
      context: context,
      builder: (_) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(children: [
            Icon(hasErrors ? Icons.error_outline : Icons.check_circle_outline,
                color: hasErrors ? colorScheme.error : colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
                child: Text('File Review',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface))),
          ]),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hasErrors
                        ? 'Issues found — fix the file and re-upload.'
                        : 'File looks good. A few improvements are suggested.'),
                    if (totalRows != null) ...[
                      const SizedBox(height: 12),
                      _infoRow('Total rows', '$totalRows'),
                      _infoRow('Ready to import', '${successCount ?? '-'}'),
                      _infoRow('Need attention', '${errorCount ?? 0}'),
                    ],
                    if (suggestions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Suggestions',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface)),
                      const SizedBox(height: 6),
                      ...suggestions.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(child: Text(s))
                                ]),
                          )),
                    ],
                    if (errors.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('Errors to Fix',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.error)),
                      const SizedBox(height: 6),
                      ...errors.take(20).map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(child: Text(e.toString()))
                                ]),
                          )),
                      if (errors.length > 20)
                        Text('...and ${errors.length - 20} more',
                            style:
                                TextStyle(color: colorScheme.onSurfaceVariant)),
                    ],
                  ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              child: Text(hasErrors ? 'Fix & Re-upload' : 'Continue'),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      );

  // ── Dialogs ───────────────────────────────────────────────

  void _showImportErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (_) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            const SizedBox(width: 8),
            Text('Import Failed',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          ]),
          content: Text(error),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                style:
                    TextButton.styleFrom(foregroundColor: colorScheme.primary),
                child: const Text('Try Again')),
          ],
        );
      },
    );
  }

  Future<void> _showSaveConfigDialog() async {
    final notifier = ref.read(fieldMappingProvider.notifier);
    final type = ref.read(typeProvider);
    if (type == null) return;

    final nameCtrl = TextEditingController();
    bool isDefault = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final colorScheme = Theme.of(ctx).colorScheme;
          return AlertDialog(
            backgroundColor: colorScheme.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text('Save Mapping Configuration',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Configuration Name',
                    hintText: 'e.g. Standard Employee Import',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Set as default'),
                  subtitle: const Text('Auto-apply for future imports'),
                  value: isDefault,
                  onChanged: (v) => setDialogState(() => isDefault = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0),
                onPressed: () async {
                  final err = await notifier.saveCurrentConfiguration(
                    name: nameCtrl.text,
                    type: type,
                    isDefault: isDefault,
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  if (err != null) {
                    _showSnack(err, isError: true);
                  } else {
                    _showSnack('Configuration saved ✅');
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fieldMappingProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: state.currentStep == FieldMappingStep.upload,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && state.currentStep != FieldMappingStep.upload) {
          _prevStep();
        }
      },
      child: Scaffold(
        drawer: const CustomDrawer(),
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: CustomAppBar(title: 'Import Manpower'),
        body: Column(
          children: [
            const _UploadFlowIntro(
              title: 'Guided Manpower Upload',
              description:
                  'Select the Excel file, review detected columns, map required fields, then validate before importing.',
            ),
            // ── Progress header ──────────────────────────────
            _StepProgressBar(currentStep: state.currentStep),

            // ── Step content (animated) ──────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _stepAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: _stepAnim, curve: Curves.easeOutCubic)),
                  child: _buildCurrentStep(state, isDark),
                ),
              ),
            ),

            // ── Bottom navigation bar ────────────────────────
            _BottomBar(
              state: state,
              onBack: state.currentStep == FieldMappingStep.upload
                  ? null
                  : _prevStep,
              onNext: _buildNextAction(state),
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _buildNextAction(FieldMappingState state) {
    if (state.isLoading) return null;
    switch (state.currentStep) {
      case FieldMappingStep.upload:
        return state.preview != null ? _nextStep : null;
      case FieldMappingStep.mapping:
        return state.isFullNameMapped ? _nextStep : null;
      case FieldMappingStep.review:
        return _doImport;
    }
  }

  Widget _buildCurrentStep(FieldMappingState state, bool isDark) {
    switch (state.currentStep) {
      case FieldMappingStep.upload:
        return _Step1Upload(
          state: state,
          onPickFile: _pickFile,
          isDark: isDark,
        );
      case FieldMappingStep.mapping:
        return _Step2Mapping(
          state: state,
          onSaveConfig: _showSaveConfigDialog,
          isDark: isDark,
        );
      case FieldMappingStep.review:
        return _Step3Review(
          state: state,
          isDark: isDark,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// STEP PROGRESS BAR
// ─────────────────────────────────────────────────────────────

class _UploadFlowIntro extends StatelessWidget {
  final String title;
  final String description;

  const _UploadFlowIntro({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.rule_folder_rounded,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  final FieldMappingStep currentStep;
  const _StepProgressBar({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final steps = [
      (
        label: 'Select File',
        step: FieldMappingStep.upload,
        icon: Icons.upload_file
      ),
      (
        label: 'Map Columns',
        step: FieldMappingStep.mapping,
        icon: Icons.account_tree_outlined
      ),
      (
        label: 'Validate',
        step: FieldMappingStep.review,
        icon: Icons.fact_check_outlined
      ),
    ];

    final idx = steps.indexWhere((s) => s.step == currentStep);

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final lineIdx = i ~/ 2;
            final filled = lineIdx < idx;
            return Expanded(
              child: Container(
                height: 2,
                color:
                    filled ? colorScheme.primary : colorScheme.outlineVariant,
              ),
            );
          }
          final si = i ~/ 2;
          final s = steps[si];
          final isActive = si == idx;
          final isDone = si < idx;
          return _StepDot(
            icon: isDone ? Icons.check : s.icon,
            label: s.label,
            isActive: isActive,
            isDone: isDone,
          );
        }),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepDot({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color =
        isActive || isDone ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive || isDone
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.24),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          child: Icon(icon, color: colorScheme.onPrimary, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: color),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 1 — UPLOAD & PREVIEW
// ─────────────────────────────────────────────────────────────

class _Step1Upload extends StatelessWidget {
  final FieldMappingState state;
  final VoidCallback onPickFile;
  final bool isDark;

  const _Step1Upload({
    required this.state,
    required this.onPickFile,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── File drop zone ──────────────────────────────
          _Card(
            isDark: isDark,
            child: InkWell(
              onTap: onPickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.selectedFile != null
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.selectedFile != null
                          ? Icons.insert_drive_file
                          : Icons.cloud_upload_outlined,
                      size: 48,
                      color: state.selectedFile != null
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.selectedFile != null
                          ? state.selectedFile!.path.split('/').last
                          : 'Tap to choose file',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: state.selectedFile != null
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supported: .xlsx, .xls, .csv',
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: Text(state.selectedFile != null
                          ? 'Change File'
                          : 'Browse Files'),
                      onPressed: onPickFile,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Loading skeleton or preview ──────────────────
          if (state.loadingPhase == LoadingPhase.preview)
            _SkeletonCard(isDark: isDark)
          else if (state.error != null)
            _ErrorBanner(message: state.error!, onRetry: onPickFile)
          else if (state.preview != null)
            _PreviewCard(preview: state.preview!, isDark: isDark),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final FieldMappingPreview preview;
  final bool isDark;

  const _PreviewCard({required this.preview, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with stats
          Row(children: [
            Icon(Icons.table_chart, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('File Preview',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface)),
            const Spacer(),
            if (preview.isStandardTemplate)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary)),
                child: Text('Standard Template ✅',
                    style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
          ]),
          const SizedBox(height: 12),

          // Stats chips
          Wrap(spacing: 8, runSpacing: 6, children: [
            _Chip(
                label:
                    '${preview.totalRows ?? preview.preview.length + 1}+ rows',
                icon: Icons.table_rows,
                color: colorScheme.primary),
            _Chip(
                label: '${preview.csvColumns.length} columns',
                icon: Icons.view_column,
                color: colorScheme.tertiary),
            _Chip(
                label:
                    '${preview.suggestedMappings.where((s) => s.confidence > 0.7).length} auto-mapped',
                icon: Icons.auto_fix_high,
                color: colorScheme.primary),
          ]),

          const SizedBox(height: 16),
          Text('Detected Columns',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 8),

          // Column badges
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: preview.csvColumns
                .map((col) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: colorScheme.primary.withOpacity(0.35))),
                      child: Text(col,
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onPrimaryContainer)),
                    ))
                .toList(),
          ),

          const SizedBox(height: 16),
          Text('Data Preview (first rows)',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 8),

          // Scrollable preview table
          if (preview.preview.isNotEmpty)
            SizedBox(
              height: 180,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowHeight: 36,
                    dataRowMinHeight: 32,
                    dataRowMaxHeight: 40,
                    headingRowColor: WidgetStateProperty.all(
                        colorScheme.surfaceContainerHighest),
                    border: TableBorder.all(
                        color: colorScheme.outlineVariant, width: 0.5),
                    columns: preview.csvColumns
                        .map((col) => DataColumn(
                              label: Text(col,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ))
                        .toList(),
                    rows: preview.preview
                        .take(5)
                        .map((row) => DataRow(
                              cells: preview.csvColumns
                                  .map((col) => DataCell(Text(
                                        row[col]?.toString() ?? '-',
                                        style: const TextStyle(fontSize: 12),
                                      )))
                                  .toList(),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 2 — FIELD MAPPING
// ─────────────────────────────────────────────────────────────

class _Step2Mapping extends ConsumerWidget {
  final FieldMappingState state;
  final VoidCallback onSaveConfig;
  final bool isDark;

  const _Step2Mapping({
    required this.state,
    required this.onSaveConfig,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(fieldMappingProvider.notifier);
    final preview = state.preview;
    if (preview == null) return const SizedBox.shrink();

    final unmapped = state.unmappedCsvColumns;
    final hasUnmapped = unmapped.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Saved configurations loader ──────────────────
          if (state.savedConfigurations.isNotEmpty)
            _Card(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Load Saved Configuration',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MappingConfiguration>(
                    value: state.selectedConfiguration,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      hintText: 'Choose a saved configuration',
                    ),
                    items: state.savedConfigurations.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Row(children: [
                          if (c.isDefault)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                  color: colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text('Default',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onTertiaryContainer)),
                            ),
                          Expanded(
                              child: Text(c.configurationName,
                                  overflow: TextOverflow.ellipsis)),
                        ]),
                      );
                    }).toList(),
                    onChanged: (config) {
                      if (config != null) notifier.applyConfiguration(config);
                    },
                  ),
                ],
              ),
            ),

          if (state.savedConfigurations.isNotEmpty) const SizedBox(height: 12),

          // ── Unmapped warning banner ──────────────────────
          if (hasUnmapped)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: colorScheme.tertiary.withOpacity(0.45)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: colorScheme.tertiary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${unmapped.length} column(s) not mapped and will be ignored:\n${unmapped.join(', ')}',
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onTertiaryContainer),
                    ),
                  ),
                ],
              ),
            ),

          // ── Required field warning ───────────────────────
          if (!state.isFullNameMapped)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.error.withOpacity(0.45)),
              ),
              child: Row(children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Text('Full Name (required) must be mapped to continue.',
                    style: TextStyle(
                        color: colorScheme.onErrorContainer, fontSize: 13)),
              ]),
            ),

          // ── Mapping cards ────────────────────────────────
          Text('Map Your Columns',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text(
            'Match each column in your file to the corresponding field.',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),

          ...preview.csvColumns.map((csvCol) {
            final currentMapping = state.activeMappings[csvCol];
            final suggestion = preview.suggestedMappings
                .where((s) => s.csvColumn == csvCol)
                .firstOrNull;

            return _MappingCard(
              csvColumn: csvCol,
              modelFields: preview.modelFields,
              selectedField: currentMapping,
              confidence: suggestion?.confidence,
              sampleValue: preview.preview.isNotEmpty
                  ? preview.preview.first[csvCol]?.toString()
                  : null,
              onChanged: (field) => notifier.updateMapping(csvCol, field),
              isDark: isDark,
            );
          }),

          const SizedBox(height: 16),

          // ── Save config button ───────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Mapping Configuration'),
              onPressed: state.isFullNameMapped ? onSaveConfig : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MappingCard extends StatelessWidget {
  final String csvColumn;
  final List<ModelField> modelFields;
  final String? selectedField;
  final double? confidence;
  final String? sampleValue;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _MappingCard({
    required this.csvColumn,
    required this.modelFields,
    required this.selectedField,
    required this.confidence,
    required this.sampleValue,
    required this.onChanged,
    required this.isDark,
  });

  Color _confidenceColor(ColorScheme colorScheme) {
    if (confidence == null) return colorScheme.outlineVariant;
    if (confidence! >= 0.8) return colorScheme.primary;
    if (confidence! >= 0.5) return colorScheme.tertiary;
    return colorScheme.outline;
  }

  String get _confidenceLabel {
    if (confidence == null) return '';
    if (confidence! >= 0.8) return 'High match';
    if (confidence! >= 0.5) return 'Partial match';
    return 'Low match';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMapped = selectedField != null && selectedField!.isNotEmpty;
    final isRequired = modelFields
        .where((f) => f.field == selectedField)
        .any((f) => f.required);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isMapped && isRequired
              ? colorScheme.primary.withOpacity(0.35)
              : isMapped
                  ? colorScheme.primary.withOpacity(0.2)
                  : colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CSV column header
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.table_chart_outlined,
                        size: 12, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(csvColumn,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: colorScheme.onPrimaryContainer)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (confidence != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: _confidenceColor(colorScheme).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _confidenceColor(colorScheme))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_fix_high,
                        size: 10, color: _confidenceColor(colorScheme)),
                    const SizedBox(width: 3),
                    Text(_confidenceLabel,
                        style: TextStyle(
                            fontSize: 10,
                            color: _confidenceColor(colorScheme))),
                  ]),
                ),
              const Spacer(),
              if (isMapped)
                Icon(Icons.check_circle, color: colorScheme.primary, size: 18),
            ]),

            if (sampleValue != null && sampleValue!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'e.g. "$sampleValue"',
                style: TextStyle(
                    fontSize: 11, color: colorScheme.onSurfaceVariant),
              ),
            ],

            const SizedBox(height: 8),

            // Dropdown arrow
            DropdownButtonFormField<String>(
              value: selectedField?.isEmpty ?? true ? null : selectedField,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                hintText: 'Select model field',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('— Ignore this column —',
                      style: TextStyle(fontSize: 13)),
                ),
                ...modelFields.map((f) => DropdownMenuItem<String>(
                      value: f.field,
                      child: Row(children: [
                        if (f.required)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text('*',
                                style: TextStyle(
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.bold)),
                          ),
                        Expanded(
                            child: Text(f.label,
                                style: const TextStyle(fontSize: 13))),
                        Text(' (${f.type})',
                            style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant)),
                      ]),
                    )),
              ],
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 3 — REVIEW & IMPORT
// ─────────────────────────────────────────────────────────────

class _Step3Review extends ConsumerWidget {
  final FieldMappingState state;
  final bool isDark;

  const _Step3Review({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(fieldMappingProvider.notifier);
    final preview = state.preview;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary card ─────────────────────────────────
          _Card(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.summarize_outlined, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Import Summary',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorScheme.onSurface)),
                ]),
                const SizedBox(height: 12),
                _ResultTile(
                  'Total rows',
                  '${preview?.totalRows ?? '?'}',
                ),
                _ResultTile(
                  'Mapped fields',
                  '${state.confirmedMappings.length}',
                  valueColor: colorScheme.primary,
                ),
                _ResultTile(
                  'Ignored columns',
                  '${state.unmappedCsvColumns.length}',
                  valueColor: state.unmappedCsvColumns.isEmpty
                      ? colorScheme.primary
                      : colorScheme.tertiary,
                ),
                if (state.unmappedCsvColumns.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ignored: ${state.unmappedCsvColumns.join(", ")}',
                    style: TextStyle(fontSize: 11, color: colorScheme.tertiary),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Mapping review cards ──────────────────────────
          _Card(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Field Mappings',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.onSurface)),
                const SizedBox(height: 10),
                ...state.confirmedMappings.map((m) {
                  final modelField = state.preview?.modelFields
                      .where((f) => f.field == m.modelField)
                      .firstOrNull;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(
                          child: Text(m.csvColumn,
                              style: TextStyle(
                                  fontSize: 13, color: colorScheme.onSurface))),
                      Icon(Icons.arrow_forward,
                          size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: modelField?.required == true
                                ? colorScheme.primaryContainer
                                : colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          modelField?.label ?? m.modelField,
                          style: TextStyle(
                              fontSize: 12,
                              color: modelField?.required == true
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ]),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Save config on import ─────────────────────────
          _Card(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Save this mapping for future imports',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  value: state.saveConfigOnImport,
                  onChanged: (v) => notifier.setSaveConfigOnImport(v),
                ),
                if (state.saveConfigOnImport) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: state.saveConfigName,
                    decoration: InputDecoration(
                      labelText: 'Configuration Name',
                      hintText: 'e.g. Standard Employee Import',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onChanged: notifier.setSaveConfigName,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Set as default',
                        style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Auto-apply on future imports',
                        style: TextStyle(fontSize: 11)),
                    value: state.saveConfigAsDefault,
                    onChanged: (v) => notifier.setSaveConfigAsDefault(v),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Loading indicator ─────────────────────────────
          if (state.loadingPhase == LoadingPhase.importing)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Column(children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  'Analyzing file… queuing upload job.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTTOM NAV BAR
// ─────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final FieldMappingState state;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const _BottomBar({
    required this.state,
    required this.onBack,
    required this.onNext,
  });

  String get _nextLabel {
    switch (state.currentStep) {
      case FieldMappingStep.upload:
        return 'Continue to Column Mapping';
      case FieldMappingStep.mapping:
        return 'Review Validation';
      case FieldMappingStep.review:
        return state.loadingPhase == LoadingPhase.importing
            ? 'Validating...'
            : 'Validate & Import';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Row(children: [
        if (onBack != null)
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back_ios, size: 14),
              label: const Text('Back'),
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        if (onBack != null) const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            icon: state.loadingPhase == LoadingPhase.importing
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary)))
                : Icon(state.currentStep == FieldMappingStep.review
                    ? Icons.cloud_upload
                    : Icons.arrow_forward_ios),
            label: Text(_nextLabel),
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              disabledBackgroundColor: colorScheme.primary.withOpacity(0.4),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Chip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ResultTile(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? colorScheme.onSurface)),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerHigh;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: colorScheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 14, width: 120, color: base),
          const SizedBox(height: 12),
          Wrap(
              spacing: 8,
              children: List.generate(
                  5,
                  (_) => Container(
                      height: 28,
                      width: 80,
                      decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(14))))),
          const SizedBox(height: 12),
          Container(height: 100, color: base),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.error.withOpacity(0.35))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            const SizedBox(width: 8),
            Text('Analysis Failed',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: colorScheme.error)),
          ]),
          const SizedBox(height: 8),
          Text(message,
              style:
                  TextStyle(fontSize: 13, color: colorScheme.onErrorContainer)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try Another File'),
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
          ),
        ],
      ),
    );
  }
}
