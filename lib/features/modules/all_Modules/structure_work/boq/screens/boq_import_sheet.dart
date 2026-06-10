import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/file_upload.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/modules/all_Modules/structure_work/boq/providers/boq_structure_provider.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

class BoqImportSheetScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;

  const BoqImportSheetScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  ConsumerState<BoqImportSheetScreen> createState() =>
      _BoqImportSheetScreenState();
}

class _BoqImportSheetScreenState extends ConsumerState<BoqImportSheetScreen> {
  bool _isLoading = false;
  String? _selectedFileName;
  PlatformFile? _selectedFile;

  Future<void> _pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
        withData: true, // Need data for the current API implementation
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _selectedFileName = _selectedFile!.name;
        });
      }
    } catch (e) {
      AppToast.error('Error picking file: $e');
    }
  }

  Future<void> _uploadExcel() async {
    if (_selectedFile == null) {
      AppToast.error('Please select an Excel file first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final workType = ref.read(typeProvider) ?? 'fabrication';
      final success = await ref
          .read(boqStructureProvider.notifier)
          .uploadBOQ(widget.siteId, _selectedFile!, workType: workType);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        AppToast.success("✅ BOQ uploaded successfully!");
        Navigator.pop(context, true);
      } else {
        final error = ref.read(boqStructureProvider).error;
        AppToast.error('Upload failed: ${error ?? "Unknown error"}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppToast.error('Upload error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: 'Import BOQ Sheet',
      ),
      body: CornerClippedScreenSimple(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Please ensure your Excel file contains columns like:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "• Assembly Mark / Mark (Required)\n"
                "• Quantity / Qty (Required)\n"
                "• Length, Width, Height (Optional)\n"
                "• Net Weight Per Unit (Optional)",
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // File Selection Section
              UploadBox(
                title: 'Upload your BOQ Excel file',
                subtitle: _selectedFileName ?? 'No file selected',
                buttonText:
                    _selectedFileName == null ? 'Choose File' : 'Change File',
                onPressed: _pickExcelFile,
              ),

              const SizedBox(height: 24),

              // Upload Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _uploadExcel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor:
                        colorScheme.primary.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Uploading...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload),
                            SizedBox(width: 8),
                            Text(
                              'Upload BOQ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
