import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/modules/all_Modules/rate/data/rateApi.dart';
import 'package:untitled2/features/modules/all_Modules/rate/screens/rate.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/file_upload.dart';
import '../../site_Details/providers/site_current_provider.dart';

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

  Future<void> _pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv','xlsx','pdf'],
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
    final type=ref.read(typeProvider);
    final siteId=ref.read(selectedSiteIdProvider);


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

      final result = await RateApiClient().uploadCsv(
        formData,
        type!,
        siteId!,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        setState(() {
          _uploadStatus = 'CSV imported successfully!';
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV imported successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>RateScreen() ),
        );

        // Optionally navigate back after successful upload
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true); // Return true to indicate refresh needed
          }
        });
      } else {
        _showError('Upload failed: ${result['error']}');
      }
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

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(
        title: 'Import CSV',

      ),
      body: CornerClippedScreenSimple(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        
        
              const SizedBox(height: 24),
        
              // File Selection Section
              UploadBox(
                title: 'Select CSV File',
                subtitle: _selectedFileName ?? 'No file selected',
                buttonText: _selectedFileName == null ? 'Choose CSV File' : 'Change File',
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
                      Text('Upload CSV'),
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