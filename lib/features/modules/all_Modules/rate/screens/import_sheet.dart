import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/modules/all_Modules/rate/data/rateApi.dart';
import 'package:untitled2/features/modules/all_Modules/rate/screens/rate.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../../../../../core/upload/manager/upload_manager.dart';
import '../../../../../core/upload/models/upload_job.dart';
import '../../../../../core/utlis/app_toasts.dart';
import '../../../../../core/utlis/sample_file/providers.dart';
import '../../../../../core/utlis/sample_file/sample_file_model.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../../core/utlis/widgets/sample_preview.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../tour/domain/tour_controller.dart';
import '../../../../tour/core/tour_models.dart';
import '../../../../tour/core/tour_package_adapter.dart';
import '../../../../tour/definitions/site_rate_module_tours.dart';
import '../../../../tour/providers/tour_providers.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../data/rate_upload_provider.dart';

class ImportCsvScreen extends ConsumerStatefulWidget {
  const ImportCsvScreen({
    super.key,
  });

  @override
  ConsumerState<ImportCsvScreen> createState() => _ImportCsvScreenState();
}

class _ImportCsvScreenState extends ConsumerState<ImportCsvScreen> {
  bool _isLoading = false;
  String? _selectedFileName;
  PlatformFile? _selectedFile;
  String _uploadStatus = '';
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  String? _lastShowcasedTourStepId;
  final GlobalKey _downloadTourKey =
      GlobalKey(debugLabel: 'rate_import_download');
  final GlobalKey _fileTourKey = GlobalKey(debugLabel: 'rate_import_file');
  final GlobalKey _uploadTourKey = GlobalKey(debugLabel: 'rate_import_upload');

  Future<void> _pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _selectedFileName = _selectedFile!.name;
          _uploadStatus = '';
        });
      }
    } catch (e) {
      _showError('Error picking file: $e');
    }
  }

  Future<void> _uploadCsv() async {
    if (_selectedFile == null) {
      _showError('Please select a CSV file first');
      return;
    }
    final type = ref.read(typeProvider);
    final siteId = ref.read(selectedSiteIdProvider);

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Uploading...';
    });

    try {
      // Create FormData with the file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          _selectedFile!.path!,
          filename: _selectedFile!.name,
        ),
      });

      // final result = await RateApiClient().uploadCsv(
      //   formData,
      //   type!,
      //   siteId!,
      // );
      ref.read(uploadManagerProvider.notifier).enqueue(
            UploadJob.create(
              moduleId: 'rate',
              filePath: _selectedFile!.path!,
              metadata: {'siteId': siteId, 'type': type},
              targetRoute: '/site-list/rate',
              maxRetries: 2,
            ),
          );
      await ref.read(tourPersistenceProvider).markRateDone();

      setState(() {
        _isLoading = false;
      });

      AppToast.success("✅ File added to upload queue");
      if (!mounted) return;

      // if (result['success'] == true) {
      //   setState(() {
      //     _uploadStatus = 'CSV imported successfully!';
      //   });
      //
      //   // Show success message
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('CSV imported successfully'),
      //       backgroundColor: Colors.green,
      //     ),
      //   );
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(builder: (context) =>RateScreen() ),
      //   );
      //
      //   // Optionally navigate back after successful
      // } else {
      //   _showError('Upload failed: ${result['error']}');
      // }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Upload error: $e');
    }
  }

  void _showError(String message) {
    setState(() {
      _uploadStatus = message;
    });
    AppToast.error(message);
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _uploadStatus = '';
    });
  }

  void _syncRateImportTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${SiteRateModuleTours.rateId}_import',
      title: 'Import Rate File',
      description: 'Learn how to import rates from a file.',
      icon: Icons.upload_file_rounded,
      steps: [
        const AppTourStep(
          id: 'rate_import_intro',
          title: 'Import Rate File',
          body: 'Use this screen to upload many rates from an Excel, CSV, or PDF file.',
          progressLabel: 'Import intro',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'rate_import_download',
          title: 'Download Template',
          body: 'Download the sample template if you need the correct rate format.',
          targetKey: _downloadTourKey,
          progressLabel: 'Template',
        ),
        AppTourStep(
          id: 'rate_import_file',
          title: 'Choose Rate File',
          body: 'Tap here to choose your filled rate file from your device.',
          targetKey: _fileTourKey,
          progressLabel: 'Choose file',
        ),
        AppTourStep(
          id: 'rate_import_upload',
          title: 'Upload Rate',
          body: 'Tap Upload Rate to add this file to the upload queue.',
          targetKey: _uploadTourKey,
          progressLabel: 'Upload',
          tooltipBottomOffset: 96,
        ),
      ],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _isLoading) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);
      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: SiteRateModuleTours.rateId,
        );
      }
      final step = tourController.currentStep;
      final activeTour = tourController.activeTour;
      if (activeTour == null ||
          !activeTour.id.startsWith(SiteRateModuleTours.rateId)) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      _tourPackageAdapter.showStep(showcaseContext, step);
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return Showcase.withWidget(
      key: key,
      container: const SizedBox.shrink(),
      overlayOpacity: 0.72,
      targetPadding: const EdgeInsets.all(8),
      targetBorderRadius: BorderRadius.circular(14),
      disableDefaultTargetGestures: false,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(templateDownloadControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    ref.watch(appTourControllerProvider);
    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncRateImportTour(showcaseContext);
        return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: 'Import Rate File',
      ),
      body: CornerClippedScreenSimple(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tourTarget(
                _downloadTourKey,
                RoundedButton(
                width: double.infinity,
                text: downloadState.isLoading
                    ? "Downloading..."
                    : "Download Sample Template",
                color: colorScheme.surface,
                textColor: colorScheme.onSurface,
                onPressed: downloadState.isLoading
                    ? () {}
                    : () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TemplatePreviewScreen(
                              title: "Sample Template Preview",
                              imageAsset: "assets/images/rate-temp.webp",
                              onDownload: () async {
                                final file = await ref
                                    .read(templateDownloadControllerProvider
                                        .notifier)
                                    .downloadAndSaveTemplate(
                                        TemplateModel.rate);

                                if (!context.mounted) return;
                                AppToast.success("✅ Saved: ${file}");
                              },
                            ),
                          ),
                        );
                      },
                ),
              ),

              const SizedBox(height: 8),
              Text(
                "* Use this format to ensure accurate and smooth import.",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // File Selection Section
              _tourTarget(
                _fileTourKey,
                UploadBox(
                title: 'Upload your Rate file',
                subtitle: _selectedFileName ?? 'No file selected',
                buttonText: _selectedFileName == null
                    ? 'Choose Rate File'
                    : 'Change File',
                onPressed: _pickCsvFile,
                ),
              ),

              const SizedBox(height: 24),

              // Upload Button
              _tourTarget(
                _uploadTourKey,
                SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _uploadCsv,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor:
                          colorScheme.primary.withOpacity(0.5),
                      elevation: 0),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Uploading...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload),
                            SizedBox(width: 8),
                            Text('Upload Rate'),
                          ],
                        ),
                ),
                ),
              ),
            ],
          ),
        ),
      ),
        );
      },
    );
  }
}
