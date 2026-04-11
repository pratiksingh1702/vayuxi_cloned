import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/common_functions.dart';
import 'package:untitled2/core/utlis/sample_file/sample_file_model.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/modules/all_Modules/rate/data/rateApi.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_service.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/screens/siteDetailScreen.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../../../../../core/utlis/sample_file/providers.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../../core/utlis/widgets/sample_preview.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../tour/domain/tour_controller.dart';
import '../../../../tour/domain/tour_events.dart';
import '../../../../tour/domain/tour_aware_mixin.dart';
import '../../../../tour/registry/site_registry.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../providers/siteProvider.dart';

class SiteImportCsvScreen extends ConsumerStatefulWidget {
  const SiteImportCsvScreen({
    super.key,
  });

  @override
  ConsumerState<SiteImportCsvScreen> createState() =>
      _SiteImportCsvScreenState();
}

class _SiteImportCsvScreenState extends ConsumerState<SiteImportCsvScreen>
    with TourAwareMixin<SiteImportCsvScreen> {
  bool _isLoading = false;
  String? _selectedFileName;
  PlatformFile? _selectedFile;
  String _uploadStatus = '';

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
        await ref
            .read(tourControllerProvider.notifier)
            .onEvent(TourEvents.siteFileSelected);
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
      final response = await SiteAPI.uploadFile(
        File(_selectedFile!.path!),
        type!,
        siteId: siteId,
      );

      ref.read(siteProvider.notifier).fetchSites();

      if (!mounted) return;
      try {
        ref.read(siteProvider.notifier).fetchSites();

        if (!mounted) return;

        final siteJson = response['site'];

        if (siteJson == null || siteJson is! Map<String, dynamic>) {
          throw Exception("Invalid response: 'site' is missing or not a map");
        }

        final siteModel = SiteModel.fromJson(siteJson);

        // Upload succeeded: conclude tour/buddy immediately.
        await ref.read(tourPersistenceProvider).markSiteDone();
        await ref.read(tourControllerProvider.notifier).skip();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SiteDetailScreen(site: siteModel),
          ),
        );
      } catch (e, st) {
        debugPrint("❌ Error while parsing site / navigation: $e");
        debugPrint("STACKTRACE: $st");

        if (!context.mounted) return;
        final error = extractBackendError(e);
        AppToast.error(error);
      }

      setState(() {
        _isLoading = false;
      });
      AppToast.success(response['message'] ?? 'Upload successful');
      // context.push("/site-list/site");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;

      final error = extractBackendError(e);
      print("exceptionnnnnnnnnnnnnn $error");
      AppToast.error(error);
    }
  }

  void _showError(String message) {
    setState(() {
      _uploadStatus = message;
    });
    final error = extractBackendError(message);
    AppToast.error(error);
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _uploadStatus = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final downloadState = ref.watch(templateDownloadControllerProvider);

    return ShowCaseWidget(
      builder: (showcaseContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          runTourForRoute(Routes.siteImport, showcaseContext);
        });

        return Scaffold(
          drawer: const CustomDrawer(),
          backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
          appBar: CustomAppBar(
            title: 'Import Site File',
          ),
          body: CornerClippedScreenSimple(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Showcase(
                    key: SiteRegistry.downloadSampleKey,
                    description: 'Download the sample template first.',
                    child: RoundedButton(
                      width: double.infinity,
                      text: downloadState.isLoading
                          ? "Downloading..."
                          : "Download Sample Template",
                      color: isDark ? cs.surfaceContainerHigh : cs.surface,
                      textColor: cs.onSurface,
                      isOutlined: true,
                      onPressed: downloadState.isLoading
                          ? () {}
                          : () async {
                              // Mark download step completed first, then open preview.
                              await ref
                                  .read(tourControllerProvider.notifier)
                                  .onEvent(TourEvents.sampleDownloaded);

                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TemplatePreviewScreen(
                                    title: "Sample Template Preview",
                                    imageAsset: "assets/images/site-temp.png",
                                    onDownload: () async {
                                      final file = await ref
                                          .read(
                                              templateDownloadControllerProvider
                                                  .notifier)
                                          .downloadAndSaveTemplate(
                                              TemplateModel.site);

                                      if (!context.mounted) return;
                                      AppToast.success("✅ Saved: ${file}");
                                    },
                                  ),
                                ),
                              );

                              if (!context.mounted) return;
                              // On returning from preview, continue guidance on site import.
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                runTourForRoute(
                                    Routes.siteImport, showcaseContext);
                              });
                            },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "* Use this format to ensure accurate and smooth import.",
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (downloadState.hasError)
                    Text(
                      "Error: ${downloadState.error}",
                      style: TextStyle(color: cs.error),
                    ),

                  const SizedBox(height: 24),

                  // File Selection Section
                  Showcase(
                    key: SiteRegistry.uploadBoxKey,
                    description: 'Pick your filled file and upload it.',
                    child: UploadBox(
                      title: 'Upload your Site file',
                      subtitle: _selectedFileName ?? 'No file selected',
                      buttonText: _selectedFileName == null
                          ? 'Choose SiteFile'
                          : 'Change File',
                      onPressed: _pickCsvFile,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Upload Button
                  SizedBox(
                    width: double.infinity,
                    child: Showcase(
                      key: SiteRegistry.uploadFileButtonKey,
                      description:
                          'Now upload the selected file to finish setup.',
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _uploadCsv,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            disabledBackgroundColor:
                                cs.primary.withOpacity(0.5),
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
                                          cs.onPrimary),
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
                                  Text('Upload Site File'),
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
