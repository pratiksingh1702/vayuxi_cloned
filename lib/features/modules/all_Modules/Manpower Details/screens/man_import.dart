import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/service/manpowerService.dart';
import 'package:untitled2/features/modules/all_Modules/rate/data/rateApi.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../../../../../core/utlis/app_toasts.dart';
import '../../../../../core/utlis/colors/colors.dart';
import '../../../../../core/utlis/sample_file/providers.dart';
import '../../../../../core/utlis/sample_file/sample_file_model.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../../core/utlis/widgets/sample_preview.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../tour/domain/tour_controller.dart';
import 'manpowerList.dart';


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
      final type =ref.read(typeProvider);

      final result = await ManpowerAPI.uploadManpowerBulk(formData,type!);

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _uploadStatus = "Upload successful";
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted)   Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>ManpowerListScreen() ),
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('XLSX imported successfully'),
            backgroundColor: Colors.green,
          ),
        );


      } else {
        _showError(result['message'] ?? "Upload failed");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Upload error: $e");
    }
  }
  Future<void> _onUploadPressed() async {
    // 1) If no file selected -> pick file
    if (_selectedFile == null) {
      await _pickCsvFile();
      if (_selectedFile == null) return; // user cancelled
    }

    final path = _selectedFile!.path;
    if (path == null || path.isEmpty) {
      _showError("Invalid file path. Re-pick the file.");
      return;
    }

    final file = File(path);
    if (!file.existsSync()) {
      _showError("File not found on device.");
      return;
    }

    final type = ref.read(typeProvider);
    if (type == null) {
      _showError("Type not selected");
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadStatus = "Analyzing file...";
    });

    try {
      _dbg("══════════════════════════════════════════════");
      _dbg("📌 START ANALYSIS");
      _dbg("📁 FILE = ${file.path}");
      _dbg("📌 TYPE = $type");
      _dbg("══════════════════════════════════════════════");

      // 2) Analyze First
      final analyzeRes = await ManpowerAPI.analyzeExcel(
        file: file,
        type: type,
      );

      _dbg("✅ analyzeRes runtimeType = ${analyzeRes.runtimeType}");
      _dbg("✅ analyzeRes = ${_short(analyzeRes, max: 2500)}");

      // ✅ backend wrapper safety
      final analyzeSuccess = analyzeRes["success"] == true;
      if (!analyzeSuccess) {
        setState(() => _isLoading = false);
        _showError(analyzeRes["message"] ?? "Analysis failed");
        return;
      }

      /// ✅ Handle both response formats:
      /// Format A: { success: true, data: {...backendPayload...} }
      /// Format B: { ...backendPayload... }
      final dynamic rawPayload = analyzeRes["data"] ?? analyzeRes;

      if (rawPayload is! Map<String, dynamic>) {
        setState(() => _isLoading = false);
        _showError("Invalid backend payload format (not a Map)");
        _dbg("❌ rawPayload = ${_short(rawPayload, max: 2000)}");
        return;
      }

      final resData = rawPayload;

      _dbg("🟦 resData keys = ${resData.keys.toList()}");
      _dbg("🟦 resData = ${_short(resData, max: 2500)}");

      // ✅ Extract
      final suggestions = _extractSuggestionsFromResponse(resData);
      final errors = _extractErrorsFromResponse(resData);

      // ✅ Trust backend counts (fallback to extraction)
      final int totalRows = (resData["totalRows"] is int)
          ? resData["totalRows"]
          : int.tryParse("${resData["totalRows"]}") ?? 0;

      final int successCount = (resData["successCount"] is int)
          ? resData["successCount"]
          : int.tryParse("${resData["successCount"]}") ?? 0;

      final int errorCount = (resData["errorCount"] is int)
          ? resData["errorCount"]
          : int.tryParse("${resData["errorCount"]}") ?? errors.length;

      _dbg("📊 totalRows=$totalRows | successCount=$successCount | errorCount=$errorCount");
      _dbg("🟩 suggestions count = ${suggestions.length}");
      _dbg("🟥 extracted errors count = ${errors.length}");

      // ✅ IMPORTANT DECISION:
      // show dialog if backend says there are errors OR extracted errors are there
      final bool hasErrors =
          errorCount > 0 || errors.isNotEmpty;

      final bool hasSuggestions =
          suggestions.isNotEmpty;

      if (hasErrors) {
        setState(() {
          _isLoading = false;
          _uploadStatus =
          "Errors found: $successCount success, $errorCount errors. Fix and re-upload.";
        });

        _showAnalysisDialog(
          suggestions: suggestions,
          errors: errors,
          totalRows: totalRows,
          errorCount: errorCount,
          successCount: successCount,
        );

        return; // ❌ HARD STOP
      }
      if (hasSuggestions) {
        _dbg("⚠️ Suggestions found, but no errors. Showing dialog & continuing upload.");

        _showAnalysisDialog(
          suggestions: suggestions,
          errors: const [], // explicitly empty
          totalRows: totalRows,
          errorCount: 0,
          successCount: successCount,
        );

        // ⚠️ DO NOT return
      }


      // 4) If clean -> Upload automatically
      setState(() {
        _uploadStatus = "No issues found ✅ Uploading...";
      });

      _dbg("✅ No issues found. Proceeding to Upload...");

      final uploadRes = await ManpowerAPI.uploadExcel(
        file: file,
        type: type,
      );

      _dbg("✅ uploadRes runtimeType = ${uploadRes.runtimeType}");
      _dbg("✅ uploadRes = ${_short(uploadRes, max: 2000)}");

      setState(() => _isLoading = false);

      if (uploadRes["success"] == true) {
        _uploadStatus = "Upload successful ✅";

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('XLSX imported successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await ref.read(tourPersistenceProvider).markManpowerDone();



        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ManpowerListScreen()),
            );
          }
        });
      } else {
        _showError(uploadRes["message"] ?? "Upload failed");
      }
    } catch (e, st) {
      setState(() => _isLoading = false);
      _dbg("❌ Exception: $e");
      _dbg("❌ StackTrace: $st");
      _showError("Error: $e");
    }
  }

  List<String> _extractSuggestionsFromResponse(dynamic resData) {
    _dbg("---- _extractSuggestionsFromResponse START ----");
    _dbg("resData runtimeType = ${resData.runtimeType}");
    _dbg("resData = ${_short(resData)}");

    if (resData == null || resData is! Map<String, dynamic>) {
      _dbg("Invalid resData -> return []");
      return [];
    }

    _dbg("resData keys => ${resData.keys.toList()}");

    final suggestions = <String>[];

    // ✅ analysis based
    final analysis = resData["analysis"];
    if (analysis is Map<String, dynamic>) {
      final s = analysis["suggestions"];
      _dbg("analysis['suggestions'] runtimeType = ${s.runtimeType}");
      _dbg("analysis['suggestions'] = ${_short(s)}");

      if (s is List && s.isNotEmpty) {
        suggestions.addAll(s.map((e) => e.toString()));
      }

      final unmapped = analysis["unmappedColumns"];
      _dbg("analysis['unmappedColumns'] runtimeType = ${unmapped.runtimeType}");
      _dbg("analysis['unmappedColumns'] = ${_short(unmapped)}");

      if (unmapped is List && unmapped.isNotEmpty) {
        suggestions.add("Unmapped Columns: ${unmapped.join(", ")}");
      }
    }

    // ✅ root suggestions fallback
    final rootSuggestions = resData["suggestions"];
    if (rootSuggestions is List && rootSuggestions.isNotEmpty) {
      suggestions.addAll(rootSuggestions.map((e) => e.toString()));
    }

    _dbg("✅ extracted suggestions count = ${suggestions.length}");
    _dbg("suggestions = $suggestions");
    _dbg("---- _extractSuggestionsFromResponse END ----");

    return suggestions;
  }

  List<ExcelUploadIssue> _extractErrorsFromResponse(dynamic resData) {
    _dbg("---- _extractErrorsFromResponse START ----");
    _dbg("resData runtimeType = ${resData.runtimeType}");
    _dbg("resData = ${_short(resData)}");

    if (resData == null) {
      _dbg("resData is null -> return []");
      return [];
    }

    if (resData is! Map<String, dynamic>) {
      _dbg("resData is NOT Map<String,dynamic> -> return []");
      return [];
    }

    _dbg("resData keys => ${resData.keys.toList()}");

    dynamic errors = resData["errors"];

    // fallback if backend places errors inside analysis
    if (errors == null && resData["analysis"] is Map<String, dynamic>) {
      errors = (resData["analysis"] as Map<String, dynamic>)["errors"];
      _dbg("Fallback: using analysis['errors']");
    }

    _dbg("errors runtimeType = ${errors.runtimeType}");
    _dbg("errors = ${_short(errors)}");

    final issues = <ExcelUploadIssue>[];

    if (errors is List) {
      _dbg("errors list length = ${errors.length}");

      for (int i = 0; i < errors.length; i++) {
        final e = errors[i];
        _dbg("➡️ error[$i] runtimeType = ${e.runtimeType}");
        _dbg("➡️ error[$i] = ${_short(e)}");

        if (e is Map<String, dynamic>) {
          final rowRaw = e["row"];
          final errMsg = e["error"]?.toString();

          _dbg("rowRaw = $rowRaw (${rowRaw.runtimeType})");
          _dbg("errMsg = $errMsg");

          issues.add(
            ExcelUploadIssue(
              row: rowRaw is int ? rowRaw : int.tryParse("$rowRaw"),
              message: errMsg ?? "Unknown error",
            ),
          );
        } else {
          issues.add(
            ExcelUploadIssue(message: e.toString()),
          );
        }
      }
    } else {
      _dbg("errors is NOT List -> return []");
    }

    _dbg("✅ extracted errors count = ${issues.length}");
    if (issues.isNotEmpty) _dbg("First error => ${issues.first}");
    _dbg("---- _extractErrorsFromResponse END ----");

    return issues;
  }



  void _showAnalysisDialog({
    required List<String> suggestions,
    required List<ExcelUploadIssue> errors,
    int? totalRows,
    int? errorCount,
    int? successCount,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        final hasErrors = errors.isNotEmpty || (errorCount ?? 0) > 0;

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // ← makes it rectangle
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Icon(
                hasErrors ? Icons.error_outline : Icons.check_circle_outline,
                color: hasErrors ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "File Review",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// STATUS
                  Text(
                    hasErrors
                        ? "We found some issues that must be fixed before import."
                        : "Your file looks good. A few improvements are recommended for better accuracy.",
                    style: const TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 16),

                  /// COUNTS
                  if (totalRows != null) ...[
                    _infoRow("Total rows", "$totalRows"),
                    _infoRow("Ready to import", "${successCount ?? '-'}"),
                    _infoRow("Need attention", "${errorCount ?? '0'}"),
                    const SizedBox(height: 16),
                  ],

                  /// SUGGESTIONS
                  if (suggestions.isNotEmpty) ...[
                    const Text(
                      "Recommended Improvements",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...suggestions.map(
                          (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• "),
                            Expanded(child: Text(s)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  /// ERRORS
                  if (errors.isNotEmpty) ...[
                    const Text(
                      "Errors to Fix",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...errors.take(20).map(
                          (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• "),
                            Expanded(child: Text(e.toString())),
                          ],
                        ),
                      ),
                    ),
                    if (errors.length > 20)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "...and ${errors.length - 20} more",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  /// WHAT NEXT
                  Text(
                    hasErrors
                        ? "Please correct the file and upload again."
                        : "You can continue. Missing details can be updated later from the manpower list.",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(hasErrors ? "Fix & Re-upload" : "Continue"),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }


  void _dbg(String msg) {
    debugPrint("🟦 [IMPORT_DEBUG] $msg");
  }

  String _short(dynamic v, {int max = 300}) {
    final s = v?.toString() ?? "null";
    if (s.length <= max) return s;
    return "${s.substring(0, max)} ...(${s.length} chars)";
  }

  void _showSuggestionsDialog(List<String> suggestions) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // ← makes it rectangle
          ),
          title: const Text("File Suggestions / Issues"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text("• ${suggestions[index]}"),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
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
    final downloadState = ref.watch(templateDownloadControllerProvider);

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(
        title: 'Import Manpower',

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoundedButton(
              width: double.infinity,
              text: downloadState.isLoading ? "Downloading..." : "Download Sample Template",
              color: Colors.white,
              textColor: Colors.black45,
              onPressed: downloadState.isLoading
                  ? () {}
                  : () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TemplatePreviewScreen(
                      title: "Sample Template Preview",
                      imageAsset: "assets/images/man-temp.webp",
                      onDownload: () async {
                        final file = await ref
                            .read(templateDownloadControllerProvider.notifier)
                            .downloadAndSaveTemplate(TemplateModel.manpower);

                        if (!context.mounted) return;
                        AppToast.success("✅ Saved: ${file?.path}");
                      },
                    ),
                  ),
                );

              },
            ),


            const SizedBox(height: 8),
            Text(
              "* Use this format to ensure accurate and smooth import.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),


            // File Selection Section
            UploadBox(
              title: 'Upload your Manpower file',
              subtitle: _selectedFileName ?? 'No file selected',
              buttonText: _selectedFileName == null ? 'Choose Manpower File' : 'Change File',
              onPressed: _pickCsvFile,
            ),

            const SizedBox(height: 24),

            // Upload Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onUploadPressed,
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
                    Text('Upload Manpower'),
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