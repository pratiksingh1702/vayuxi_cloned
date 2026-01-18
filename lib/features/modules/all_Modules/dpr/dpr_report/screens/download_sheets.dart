import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/select_card.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../../core/utlis/widgets/date_picker.dart';
import '../../providers/dpr.dart';
import '../../providers/dprService.dart';
import '../../screens/dprTeamDetails.dart';
import '../../screens/workTeamList.dart';

class SheetDownloadPage extends ConsumerStatefulWidget {
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  const SheetDownloadPage({super.key,this.selectedEndDate,this.selectedStartDate});

  @override
  ConsumerState<SheetDownloadPage> createState() => _SheetDownloadPageState();
}

class _SheetDownloadPageState extends ConsumerState<SheetDownloadPage> {
  bool isLoading = false;
  bool isDownloading = false;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String _selectedFormat = 'excel';

  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.selectedStartDate;
    _selectedEndDate = widget.selectedEndDate;
  }

  // Show format selection dialog
  void _showFormatSelectionDialog({
    required String label,
    required IconData icon,
    required String sheetName,
    required Future<Uint8List> Function(String, String, String) apiCall,
    required String defaultFileName,
  }) {
    // First check if dates are selected
    if (_selectedStartDate == null || _selectedEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select both start and end dates first"),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                "$sheetName Report",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Period: ${DateFormat('dd/MM/yyyy').format(_selectedStartDate!)} to ${DateFormat('dd/MM/yyyy').format(_selectedEndDate!)}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 6),
              const Text(
                "Select format:",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _FormatTile(
                icon: Icons.table_chart,
                color: Colors.green,
                title: "Excel (.xlsx)",
                subtitle: "Spreadsheet format",
                isSelected: _selectedFormat == 'excel',
                onTap: () {
                  setState(() => _selectedFormat = 'excel');
                  Navigator.pop(context);
                  _showShareOrDownloadDialog(
                    sheetName: sheetName,
                    apiCall: apiCall,
                    defaultFileName: defaultFileName,
                  );
                },
              ),
              const SizedBox(height: 12),
              _FormatTile(
                icon: Icons.picture_as_pdf,
                color: Colors.red,
                title: "PDF (.pdf)",
                subtitle: "Document format",
                isSelected: _selectedFormat == 'pdf',
                onTap: () {
                  setState(() => _selectedFormat = 'pdf');
                  Navigator.pop(context);
                  _showShareOrDownloadDialog(
                    sheetName: sheetName,
                    apiCall: apiCall,
                    defaultFileName: defaultFileName,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show option dialog to choose between share and download
  void _showShareOrDownloadDialog({
    required String sheetName,
    required Future<Uint8List> Function(String, String, String) apiCall,
    required String defaultFileName,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                sheetName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Period: ${DateFormat('dd/MM/yyyy').format(_selectedStartDate!)} to ${DateFormat('dd/MM/yyyy').format(_selectedEndDate!)}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                "Format: ${_selectedFormat.toUpperCase()}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 6),
              const Text(
                "What would you like to do?",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _ActionTile(
                icon: Icons.share_rounded,
                color: Colors.blue,
                title: "Share",
                subtitle: "Send file via apps",
                onTap: () {
                  Navigator.pop(context);
                  _downloadAndShare(sheetName, apiCall, defaultFileName);
                },
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.download_rounded,
                color: Colors.green,
                title: "Download",
                subtitle: "Save to your device",
                onTap: () {
                  Navigator.pop(context);
                  handleDownload(
                    sheetName: sheetName,
                    apiCall: apiCall,
                    defaultFileName: defaultFileName,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> handleDownload({
    required String sheetName,
    required Future<Uint8List> Function(String, String, String) apiCall,
    required String defaultFileName,
  }) async {
    try {
      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      // Double-check dates are selected
      if (_selectedStartDate == null || _selectedEndDate == null) {
        throw Exception('Date range not selected');
      }

      final fromDateStr = "${_selectedStartDate!.year}-${_selectedStartDate!.month.toString().padLeft(2, '0')}-${_selectedStartDate!.day.toString().padLeft(2, '0')}";
      final toDateStr = "${_selectedEndDate!.year}-${_selectedEndDate!.month.toString().padLeft(2, '0')}-${_selectedEndDate!.day.toString().padLeft(2, '0')}";

      final bytes = await apiCall(fromDateStr, toDateStr, _selectedFormat);
      debugPrint('📦 Bytes received: ${bytes.length} bytes');

      if (bytes.isEmpty) {
        throw Exception('Empty file received (0 bytes)');
      }

      final fileExtension = _selectedFormat == 'pdf' ? '.pdf' : '.xlsx';
      final fileName = '${defaultFileName}_${DateFormat('yyyyMMdd').format(_selectedStartDate!)}_${DateFormat('yyyyMMdd').format(_selectedEndDate!)}$fileExtension';

      if (Platform.isAndroid || Platform.isIOS) {
        await _saveMobile(bytes, fileName);
      } else {
        await _saveDesktop(bytes, fileName);
      }
    } catch (e, st) {
      debugPrint('❌ Download failed: $e');
      debugPrintStack(stackTrace: st);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: Data not available for selected period !!!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
        isDownloading = false;
      });
    }
  }

  Future<void> _downloadAndShare(
      String sheetName,
      Future<Uint8List> Function(String, String, String) apiCall,
      String defaultFileName,
      ) async {
    try {
      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      // Double-check dates are selected
      if (_selectedStartDate == null || _selectedEndDate == null) {
        throw Exception('Date range not selected');
      }

      final fromDateStr = "${_selectedStartDate!.year}-${_selectedStartDate!.month.toString().padLeft(2, '0')}-${_selectedStartDate!.day.toString().padLeft(2, '0')}";
      final toDateStr = "${_selectedEndDate!.year}-${_selectedEndDate!.month.toString().padLeft(2, '0')}-${_selectedEndDate!.day.toString().padLeft(2, '0')}";

      final bytes = await apiCall(fromDateStr, toDateStr, _selectedFormat);
      debugPrint('📦 Bytes received for sharing: ${bytes.length} bytes');

      if (bytes.isEmpty) {
        throw Exception('Empty file received (0 bytes)');
      }

      final tempDir = await getTemporaryDirectory();
      final fileExtension = _selectedFormat == 'pdf' ? '.pdf' : '.xlsx';
      final fileName = '${defaultFileName}_${DateFormat('yyyyMMdd').format(_selectedStartDate!)}_${DateFormat('yyyyMMdd').format(_selectedEndDate!)}$fileExtension';
      final tempPath = '${tempDir.path}/$fileName';
      final tempFile = File(tempPath);

      await tempFile.writeAsBytes(bytes, flush: true);
      debugPrint('💾 Temporary file saved for sharing: $tempPath');
      debugPrint(
        String.fromCharCodes(bytes.take(10)),
      );


      final mimeType = _selectedFormat == 'pdf'
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      await Share.shareXFiles(
        [XFile(tempPath, mimeType: mimeType)],
        text: 'Here is your $sheetName for period ${DateFormat('dd/MM/yyyy').format(_selectedStartDate!)} to ${DateFormat('dd/MM/yyyy').format(_selectedEndDate!)}',
        subject: '$sheetName - ${DateFormat('dd/MM/yyyy').format(_selectedStartDate!)} to ${DateFormat('dd/MM/yyyy').format(_selectedEndDate!)}',
      );

      Future.delayed(const Duration(seconds: 30), () {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
          debugPrint('🗑️ Temporary file deleted: $tempPath');
        }
      });

    } catch (e, st) {
      debugPrint('❌ Share failed: $e');
      debugPrintStack(stackTrace: st);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
        isDownloading = false;
      });
    }
  }

  Future<void> _saveMobile(Uint8List bytes, String fileName) async {
    try {
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save File',
        fileName: fileName,
        bytes: bytes,
      );

      if (outputPath != null) {
        debugPrint('💾 File saved to: $outputPath');

        final result = await OpenFile.open(outputPath);
        debugPrint('📂 Open file result: ${result.type} - ${result.message}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✅ File saved successfully!'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => OpenFile.open(outputPath),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Open'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final mimeType = fileName.endsWith('.pdf')
                              ? 'application/pdf'
                              : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

                          await Share.shareXFiles(
                            [XFile(outputPath, mimeType: mimeType)],
                            text: 'Check out this file',
                          );
                        },
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 8),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save operation canceled.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ File save error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save file: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _saveDesktop(Uint8List bytes, String fileName) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save File',
      fileName: fileName,
    );

    if (path == null) return;

    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✅ File saved: $path'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => OpenFile.open(path),
              child: const Text('Open File'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 8),
      ),
    );
  }

  Widget sheetButton({
    required String label,
    required IconData icon,
    required String sheetName,
    required Future<Uint8List> Function(String, String, String) apiCall,
    required String defaultFileName,
  }) {
    return SelectCard(
      icon: Icon(icon),
      label: label,
      onTap: () {
        _showFormatSelectionDialog(
          label: label,
          icon: icon,
          sheetName: sheetName,
          apiCall: apiCall,
          defaultFileName: defaultFileName,
        );
      },
    );
  }

  Future<void> _showDatePicker(BuildContext context, {required bool isStartDate}) async {
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => BeautifulDatePicker(
        initialDate: isStartDate ? _selectedStartDate : _selectedEndDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        title: isStartDate ? "Select Start Date" : "Select End Date",
        primaryColor: AppColors.primaryColor,
        accentColor: AppColors.accentColor,
        backgroundColor: AppColors.lightBlue,
      ),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = selectedDate;
          // If end date is before start date, reset end date
          if (_selectedEndDate != null && _selectedEndDate!.isBefore(selectedDate)) {
            _selectedEndDate = null;
          }
        } else {
          _selectedEndDate = selectedDate;
        }
      });
    }
  }

  // Clear date filter
  void _clearDateFilter() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(selectedSiteIdProvider);
    final type=ref.read(typeProvider)!;

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
          Column(
            children: [
              Container(
                margin: EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Start Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Start Date",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedStartDate != null
                                    ? AppColors.primaryColor
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: GestureDetector(
                              onTap: () => _showDatePicker(context, isStartDate: true),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: _selectedStartDate != null
                                        ? AppColors.primaryColor
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedStartDate != null
                                          ? "${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year}"
                                          : "Select Start Date",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: _selectedStartDate != null
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                        color: _selectedStartDate != null
                                            ? Colors.black
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // End Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "End Date",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedEndDate != null
                                    ? AppColors.primaryColor
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: GestureDetector(
                              onTap: () => _showDatePicker(context, isStartDate: false),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: _selectedEndDate != null
                                        ? AppColors.primaryColor
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedEndDate != null
                                          ? "${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}"
                                          : "Select End Date",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: _selectedEndDate != null
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                        color: _selectedEndDate != null
                                            ? Colors.black
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Grid of report cards
              Expanded(
                child: GridView.count(
                  physics: const BouncingScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    sheetButton(
                      label: "Measurement Sheet",
                      icon: Icons.straighten,
                      sheetName: "Measurement Sheet",
                      apiCall: (fromDate, toDate, format) =>
                          DprApi.fetchMeasurementSheet(
                            siteId: siteId,
                            fromDate: fromDate,
                            toDate: toDate,
                            format: format, workType: type,
                          ),
                      defaultFileName: "measurement_sheet",
                    ),
                    sheetButton(
                      label: "Abstract Sheet",
                      icon: Icons.calculate,
                      sheetName: "Calculation Sheet",
                      apiCall: (fromDate, toDate, format) =>
                          DprApi.fetchMeasurementCalculationSheet(
                            siteId: siteId,
                            fromDate: fromDate,
                            toDate: toDate,
                            format: format, workType: type,
                          ),
                      defaultFileName: "Abstract sheet",
                    ),
                    sheetButton(
                      label: "Summary Sheet",
                      icon: Icons.summarize,
                      sheetName: "Summary Sheet",
                      apiCall: (fromDate, toDate, format) =>
                          DprApi.fetchSummarySheet(
                            siteId: siteId,
                            fromDate: fromDate,
                            toDate: toDate,
                            format: format, workType:type,
                          ),
                      defaultFileName: "summary_sheet",
                    ),
                    sheetButton(
                      label: "Invoice Sheet",
                      icon: Icons.receipt_long,
                      sheetName: "Invoice Sheet",
                      apiCall: (fromDate, toDate, format) =>
                          DprApi.fetchInvoiceSheet(
                            siteId: siteId,
                            fromDate: fromDate,
                            toDate: toDate,
                            format: format, workType:type,
                          ),
                      defaultFileName: "invoice_sheet",
                    ),
                    SelectCard(
                      icon: const Icon(Icons.description),
                      label: "Description Sheet",
                      onTap: () async {
                        final sid = ref.read(selectedSiteIdProvider);
                        final tid = ref.read(selectedTeamIdProvider);

                        if (sid == null ) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Please select a site home screen drop-downs",
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return; // ← THIS IS THE IMPORTANT LINE
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>WorkTeamListPage(selectedStartDate: widget.selectedStartDate,selectedEndDate: widget.selectedEndDate,),
                          ),
                        );


                      },

                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      isDownloading ? 'Downloading file...' : 'Preparing to share...',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.grey,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _FormatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isSelected ? color : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.grey,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: color)
          : const SizedBox.shrink(),
      onTap: onTap,
    );
  }
}