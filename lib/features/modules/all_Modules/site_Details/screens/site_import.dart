import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/modules/all_Modules/rate/data/rateApi.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_service.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/file_upload.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../providers/siteProvider.dart';

class SiteImportCsvScreen extends ConsumerStatefulWidget {


  const SiteImportCsvScreen({
    super.key,

  });

  @override
  ConsumerState<SiteImportCsvScreen> createState() => _SiteImportCsvScreenState();
}

class _SiteImportCsvScreenState extends ConsumerState<SiteImportCsvScreen> {
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
      final response = await SiteAPI.uploadFile(
        File(_selectedFile!.path!),
        type!,
        siteId: siteId,
      );

      ref.read(siteProvider.notifier).fetchSites();

      if (!mounted) return;




      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message'] ?? 'Upload successful',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.push("/site-list/site");



    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final site=ref.read(currentSiteProvider);

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