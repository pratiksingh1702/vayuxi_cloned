// screens/inventory/bulk_upload_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import '../models/inventory_Model.dart';
import '../provider/inventory_provider.dart';

class BulkUploadScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;

  const BulkUploadScreen({
    Key? key,
    required this.siteId,
    required this.siteName,
  }) : super(key: key);

  @override
  ConsumerState<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends ConsumerState<BulkUploadScreen> {
  File? _selectedFile;
  bool _isUploading = false;
  String _uploadStatus = '';
  List<String> _errors = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Upload Inventory'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [

        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Site Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Site: ${widget.siteName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ID: ${widget.siteId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        
              const SizedBox(height: 24),
        
              // Upload Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload CSV File',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
        
                      // File Selection
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              size: 48,
                              color: Colors.blue.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedFile?.path.split('/').last ??
                                  'No file selected',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedFile != null
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.attach_file),
                                  label: const Text('Select CSV File'),
                                  onPressed: _selectCSVFile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                if (_selectedFile != null)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Remove'),
                                    onPressed: _removeFile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
        
                      const SizedBox(height: 20),
        
                      // Upload Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: _isUploading
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Icon(Icons.upload),
                          label: Text(
                            _isUploading ? 'Uploading...' : 'Upload Inventory',
                          ),
                          onPressed: _isUploading || _selectedFile == null
                              ? null
                              : _uploadInventory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        
        
              // Status & Errors
              if (_uploadStatus.isNotEmpty) _buildStatus(),
              if (_errors.isNotEmpty) _buildErrors(),
        
        
        
              // Quick Actions
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CSV Format Instructions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 12),
            Text('• Required Fields: itemName, quantity, minimumStockLevel'),
            Text('• Optional Fields: categoryName, subcategoryName, remarks'),
            Text('• File must be in CSV format'),
            Text('• Maximum file size: 10MB'),
            SizedBox(height: 8),
            Text(
              'Download the sample CSV template to get started.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus() {
    return Card(
      color: _uploadStatus.contains('successful')
          ? Colors.green.shade50
          : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              _uploadStatus.contains('successful')
                  ? Icons.check_circle
                  : Icons.info,
              color: _uploadStatus.contains('successful')
                  ? Colors.green
                  : Colors.blue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _uploadStatus,
                style: TextStyle(
                  color: _uploadStatus.contains('successful')
                      ? Colors.green.shade800
                      : Colors.blue.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrors() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Upload Errors',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._errors.map((error) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text('• $error'),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [

                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.list),
                    label: const Text('View Inventory'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCSVFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _uploadStatus = '';
          _errors = [];
        });
      }
    } catch (e) {
      _showError('Error selecting file: $e');
    }
  }

// Create sample CSV directly in the app
  Future<void> _createSampleCSV() async {
    try {
      // Create sample CSV data
      final List<List<dynamic>> csvData = [
        ['itemName', 'quantity', 'minimumStockLevel', 'categoryName', 'subcategoryName', 'uom', 'remarks'],

        ['Cement Bags 50kg', '100', '20', 'Construction Materials', 'Cement', 'Bags', 'OPC Grade 43'],
      ];


      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(csvData);

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final sampleFile = File('${tempDir.path}/inventory_sample_${DateTime.now().millisecondsSinceEpoch}.csv');

      // Write CSV to file
      await sampleFile.writeAsString(csvString);

      // Set this as selected file
      setState(() {
        _selectedFile = sampleFile;
        _uploadStatus = 'Sample CSV created! Ready to upload.';
        _errors = [];
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample CSV created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      _showError('Error creating sample CSV: $e');
    }
  }
  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _uploadStatus = '';
      _errors = [];
    });
  }

  Future<void> _uploadInventory() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadStatus = '';
      _errors = [];
    });

    try {
      final siteId=ref.watch(selectedSiteIdProvider);
      print(siteId);
      final result = await ref.read(bulkUploadProvider({
        'siteId': siteId,
        'file': _selectedFile!,
      }));

      setState(() {
        _uploadStatus = 'Upload successful! ${result?.success} items imported. '
            '${result?.failed} items failed.';
        _errors = result.errors;
      });

      if (result.failed == 0) {
        // Show success dialog
        _showSuccessDialog(result as BulkUploadResult);
      }
    } catch (e) {
      print("uploading failes 😢😢${e}");
      setState(() {
        _uploadStatus = 'Upload failed!';
        _errors = ['Error: $e'];
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSuccessDialog(BulkUploadResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Upload Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ ${result.success} items imported successfully'),
            if (result.failed > 0) ...[
              const SizedBox(height: 8),
              Text('❌ ${result.failed} items failed to import'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to inventory list
            },
            child: const Text('View Inventory'),
          ),
        ],
      ),
    );
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}