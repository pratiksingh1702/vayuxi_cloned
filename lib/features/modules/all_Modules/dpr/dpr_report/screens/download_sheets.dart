import 'dart:io';
import 'dart:typed_data';
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

  /// Converts ANY response type into Uint8List (binary file bytes)
  Uint8List _extractBytes(dynamic response) {
    if (response is Uint8List) return response;

    if (response is List<int>) return Uint8List.fromList(response);

    if (response is String) return base64.decode(response.trim());

    if (response is Map<String, dynamic>) {
      final data = response["data"];
      if (data is Uint8List) return data;
      if (data is List<int>) return Uint8List.fromList(data);
      if (data is String) return base64.decode(data.trim());
    }

    throw Exception("Unsupported response format: ${response.runtimeType}");
  }

  Future<void> handleDownload({
    required Future<dynamic> Function() apiCall,
    required String fileName,
    required String extension,
  }) async {
    try {
      setState(() => isLoading = true);

      final response = await apiCall();
      final fileBytes = _extractBytes(response);

      if (fileBytes.isEmpty) throw Exception("Empty file received");

      final fullName = "$fileName.$extension";

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: "Save File",
        fileName: fullName,
        lockParentWindow: true,
        bytes: fileBytes,
      );

      if (savePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Download cancelled")),
        );
        return;
      }

      await File(savePath).writeAsBytes(fileBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved: $savePath")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Download failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
      print("Download error: $e");
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
        label: label, onTap:
    onTap);
  }

  @override
  Widget build(BuildContext context) {
    const fromDate = "2025-01-01";
    const toDate = "2025-12-31";
    final siteId = ref.watch(selectedSiteIdProvider);

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
                    siteId: siteId!,
                    fromDate: fromDate,
                    toDate: toDate,
                  ),
                  fileName: "measurement_sheet",
                  extension: "xlsx",
                ),
              ),
              sheetButton(
                label: "Calculation Sheet",
                icon: Icons.calculate,
                onTap: () => handleDownload(
                  apiCall: () => DprApi.fetchMeasurementCalculationSheet(
                    siteId: siteId!,
                    fromDate: fromDate,
                    toDate: toDate,
                  ),
                  fileName: "calculation_sheet",
                  extension: "xlsx",
                ),
              ),
              sheetButton(
                label: "Summary Sheet",
                icon: Icons.summarize,
                onTap: () => handleDownload(
                  apiCall: () => DprApi.fetchSummarySheet(
                    siteId: siteId!,
                    fromDate: fromDate,
                    toDate: toDate,
                  ),
                  fileName: "summary_sheet",
                  extension: "xlsx",
                ),
              ),
              sheetButton(
                label: "Invoice Sheet",
                icon: Icons.receipt_long,
                onTap: () => handleDownload(
                  apiCall: () => DprApi.fetchInvoiceSheet(
                    siteId: siteId!,
                    fromDate: fromDate,
                    toDate: toDate,
                  ),
                  fileName: "invoice_sheet",
                  extension: "xlsx",
                ),
              ),
            ],
          ),

          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
