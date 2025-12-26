import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/service/manpowerService.dart';
import 'package:untitled2/features/modules/all_Modules/rate/data/rateApi.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../../../../../core/utlis/colors/colors.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/file_upload.dart';


class ManImportCsvScreen extends ConsumerStatefulWidget {


  const ManImportCsvScreen({
    super.key,

  });

  @override
  ConsumerState<ManImportCsvScreen> createState() => _ManImportCsvScreenState();
}

class _ManImportCsvScreenState extends ConsumerState<ManImportCsvScreen> {
  bool _isLoading = false;
  String? _selectedFileName;
  PlatformFile? _selectedFile;
  String _uploadStatus = '';

  Future<void> _pickCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
        withData: false, // ✅ REQUIRED so path is real
      );


      if (result == null || result.files.isEmpty) {
        _showError("No file selected");
        return;
      }

      final file = result.files.first;
      print(file.path);

      if (file.path == null || file.path!.isEmpty) {
        _showError("Invalid file path. Pick from local storage, not cloud.");
        return;
      }

      final realFile = File(file.path!);

      if (!realFile.existsSync()) {
        _showError("Selected file does not exist on device.");
        return;
      }

      setState(() {
        _selectedFile = file;
        _selectedFileName = file.name;
        _uploadStatus = '';
      });

      debugPrint("✅ Picked File Path: ${file.path}");
    } catch (e) {
      _showError("File pick error: $e");
    }
  }

  Future<void> _uploadCsv() async {
    if (_selectedFile == null) {
      _showError('Please select a file first');
      return;
    }

    final path = _selectedFile!.path;

    if (path == null || path.isEmpty) {
      _showError("Invalid file path. Re-pick the file.");
      return;
    }

    final file = File(path);
    print(file.path);
    print(path);


    if (!file.existsSync()) {
      _showError("File not found on device.");
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Uploading...';
    });

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: _selectedFile!.name,
        ),
      });

      final result = await ManpowerAPI.uploadManpowerBulk(formData);

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _uploadStatus = "Upload successful";

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('XLSX imported successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        _showError(result['message'] ?? "Upload failed");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Upload error: $e");
    }
  }

  void _showError(String message) {
    setState(() {
      _uploadStatus = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
    final type=ref.read(typeProvider);
    // final site=ref.read(currentSiteProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(
        title: 'Import Manpower',

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            const SizedBox(height: 24),

            // File Selection Section
            UploadBox(
              title: 'Select XLSX File',
              subtitle: _selectedFileName ?? 'No file selected',
              buttonText: _selectedFileName == null ? 'Choose XLSX File' : 'Change File',
              onPressed: _pickCsvFile,
            ),

            const SizedBox(height: 24),

            // Upload Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadCsv,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.blue.withOpacity(0.5),
                    elevation: 0
                ),
                child: _isLoading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Uploading...'),
                  ],
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload),
                    SizedBox(width: 8),
                    Text('Upload XLSX'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

          ],
        ),
      ),
    );
  }
}