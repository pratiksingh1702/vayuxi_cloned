import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/select_card.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import '../../providers/dprService.dart';
import 'dart:convert';

class SheetDownloadPage extends ConsumerStatefulWidget {
  const SheetDownloadPage({super.key});

  @override
  ConsumerState<SheetDownloadPage> createState() => _SheetDownloadPageState();
}

class _SheetDownloadPageState extends ConsumerState<SheetDownloadPage> {
  bool isLoading = false;

  /// Extracts bytes from API response
  Uint8List _extractBytesFromResponse(dynamic response) {
    print('Response type: ${response.runtimeType}');

    // If response is Dio Response object
    if (response is Response) {
      return _extractBytesFromResponse(response.data);
    }

    // If response is a Map (JSON)
    if (response is Map<String, dynamic>) {
      print('Response keys: ${response.keys.toList()}');

      // Check if it has a "data" field
      if (response.containsKey('data')) {
        final data = response['data'];

        // If data is a base64 string
        if (data is String) {
          print('Found base64 data string, length: ${data.length}');
          print('Data starts with: ${data.substring(0, min(50, data.length))}...');

          try {
            // Decode the base64 string
            final bytes = base64.decode(data.trim());
            print('Successfully decoded base64 to ${bytes.length} bytes');
            return bytes;
          } catch (e) {
            print('Failed to decode base64: $e');
            throw Exception('Failed to decode base64 data: $e');
          }
        }

        // If data is already bytes
        if (data is Uint8List) return data;
        if (data is List<int>) return Uint8List.fromList(data);
      }

      // Check all string values for base64
      for (final value in response.values) {
        if (value is String && value.contains('UEsDB')) {
          try {
            return base64.decode(value.trim());
          } catch (_) {
            continue;
          }
        }
      }

      throw Exception('No valid file data found in response. Keys: ${response.keys}');
    }

    // If response is already bytes
    if (response is Uint8List) return response;
    if (response is List<int>) return Uint8List.fromList(response);

    // If response is a base64 string
    if (response is String) {
      if (response.contains('UEsDB')) {
        return base64.decode(response.trim());
      }
      throw Exception('Response is string but not base64');
    }

    throw Exception("Unsupported response format: ${response.runtimeType}");
  }

  Future<void> handleDownload({
    required Future<dynamic> Function() apiCall,
    required String defaultFileName,
    required String extension,
  }) async {
    try {
      setState(() => isLoading = true);

      // Call the API
      final rawResponse = await apiCall();
      print('Raw response received');
      print(rawResponse);



      // Extract bytes from response
      final fileBytes = _extractBytesFromResponse(rawResponse);

      if (fileBytes.isEmpty) {
        throw Exception("Empty file received (0 bytes)");
      }

      // Try to get filename from response if available
      String? fileNameFromResponse;
      if (rawResponse is Map<String, dynamic> && rawResponse.containsKey('fileName')) {
        fileNameFromResponse = rawResponse['fileName'];
        print('Filename from response: $fileNameFromResponse');
      }

      // Use filename from response or default
      final fileName = fileNameFromResponse ?? "$defaultFileName.$extension";

      // Save the file
      String? savePath;

      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile, use FilePicker with bytes
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: "Save Excel File",
          fileName: fileName,
          lockParentWindow: true,
          bytes: rawResponse,
        );
        final file = File(savePath!);
        await file.writeAsBytes(rawResponse, flush: true);
      } else {
        // For web/desktop
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: "Save Excel File",
          fileName: fileName,
          lockParentWindow: true,
        );

        if (savePath != null) {
          final file = File(savePath);
          await file.writeAsBytes(rawResponse, flush: true);
        }
      }

      if (savePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Download cancelled")),
        );
        return;
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("File saved: ${fileNameFromResponse ?? fileName}"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      print('File saved successfully: $savePath');

    } catch (e, stackTrace) {
      print("Download error: $e");
      print("Stack trace: $stackTrace");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Download failed: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget sheetButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SelectCard(
      icon: Icon(icon),
      label: label,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    const fromDate = "2025-01-01";
    const toDate = "2025-12-31";
    final siteId = ref.watch(selectedSiteIdProvider);

    if (siteId == null) {
      return Scaffold(
        backgroundColor: AppColors.lightBlue,
        appBar: CustomAppBar(title: "DPR Sheet"),
        body: const Center(
          child: Text(
            "Please select a site first",
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "DPR Sheet"),
      body: Stack(
        children: [
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1,
            padding: const EdgeInsets.all(16),
            children: [
              sheetButton(
                label: "Measurement Sheet",
                icon: Icons.straighten,
                onTap: () => handleDownload(
                  apiCall: () => DprApi.fetchMeasurementSheet(
                    siteId: siteId,
                    fromDate: fromDate,
                    toDate: toDate,
                  ),
                  defaultFileName: "measurement_sheet",
                  extension: "xlsx",
                ),
              ),
              sheetButton(
                label: "Calculation Sheet",
                icon: Icons.calculate,
                onTap: () => handleDownload(
                  apiCall: () => DprApi.fetchMeasurementCalculationSheet(
                    siteId: siteId,
                    fromDate: fromDate,
                    toDate: toDate,
                  ),
                  defaultFileName: "calculation_sheet",
                  extension: "xlsx",
                ),
              ),
              sheetButton(
                label: "Summary Sheet",
                icon: Icons.summarize,
                onTap: () => handleDownload(
                  apiCall: () => DprApi.fetchSummarySheet(
                    siteId: siteId,
                    fromDate: fromDate,
                    toDate: toDate,
                  ),
                  defaultFileName: "summary_sheet",
                  extension: "xlsx",
                ),
              ),
              sheetButton(
                label: "Invoice Sheet",
                icon: Icons.receipt_long,
                onTap: () => handleDownload(
                  apiCall: () => DprApi.fetchInvoiceSheet(
                    siteId: siteId,
                    fromDate: fromDate,
                    toDate: toDate,
                  ),
                  defaultFileName: "invoice_sheet",
                  extension: "xlsx",
                ),
              ),
            ],
          ),

          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}