// lib/features/modules/all_Modules/salary/screens/select_range_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';

import 'package:untitled2/features/modules/all_Modules/salary/screens/salary_Detail.dart';

import 'package:untitled2/features/modules/all_Modules/salary/screens/widget/file_handler.dart';
import 'package:untitled2/features/modules/all_Modules/salary/screens/widget/pdf_generator.dart';
import 'package:untitled2/features/modules/all_Modules/salary/service-provider/salaryModel/salary_model.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../profile_page/provider/userProvider.dart';
import '../service-provider/salaryClient.dart';

class SelectRangeScreen extends ConsumerStatefulWidget {
  const SelectRangeScreen({super.key});

  @override
  ConsumerState<SelectRangeScreen> createState() => _SelectRangeScreenState();
}

class _SelectRangeScreenState extends ConsumerState<SelectRangeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isGenerating = false;
  double _progress = 0.0;
  String _currentStatus = '';

  // Fetched salary models — used for "View Details"
  List<SalaryModel> _fetchedModels = [];

  String _formatDate(DateTime? date) {
    if (date == null) return "Input Text";
    return "${date.day}/${date.month}/${date.year}";
  }

  // ── FETCH + BUILD MODELS (shared by both actions) ──────────────────────────

  Future<List<SalaryModel>> _fetchAllModels() async {
    final months = _getMonthsInRange(_rangeStart!, _rangeEnd!);
    final allModels = <SalaryModel>[];

    for (int i = 0; i < months.length; i++) {
      final date = months[i];
      final monthName = _getMonthName(date.month);

      setState(() {
        _currentStatus = 'Fetching data for $monthName ${date.year}...';
        _progress = i / months.length * 0.5;
      });

      try {
        final type = ref.read(typeProvider)!;
        final salaryDataList = await SalaryAPI.fetchSalaryByEmployee(
          type: type,
          month: date.month.toString(),
          year: date.year.toString(),
        );

        if (salaryDataList.isNotEmpty) {
          allModels.addAll(SalaryModel.fromJsonList(salaryDataList));
        }
      } catch (e) {
        debugPrint('Error fetching data for ${date.month}/${date.year}: $e');
      }
    }

    return allModels;
  }

  // ── VIEW DETAILS ───────────────────────────────────────────────────────────

  Future<void> _viewDetails() async {
    if (_rangeStart == null || _rangeEnd == null) {
      _showSnackBar('Please select a date range');
      return;
    }

    setState(() {
      _isGenerating = true;
      _progress = 0.0;
      _currentStatus = 'Fetching salary data...';
      _fetchedModels = [];
    });

    try {
      final models = await _fetchAllModels();

      if (models.isEmpty) {
        _showSnackBar('No salary data found for the selected range.');
        return;
      }

      setState(() => _fetchedModels = models);

      if (!mounted) return;

      // Single employee → single detail; multiple → list view
      if (models.length == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SalaryDetailScreen.single(model: models.first),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SalaryDetailScreen.list(models: models),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _progress = 0.0;
          _currentStatus = '';
        });
      }
    }
  }

  // ── DOWNLOAD ALL ───────────────────────────────────────────────────────────

  Future<void> _downloadAllSalarySlips() async {
    if (_rangeStart == null || _rangeEnd == null) {
      _showSnackBar('Please select a date range');
      return;
    }

    setState(() {
      _isGenerating = true;
      _progress = 0.0;
      _currentStatus = 'Initializing...';
    });

    int successfulCount = 0;
    int failedCount = 0;
    final pdfFiles = <PdfFile>[];

    try {
      final logoBytes = await FileHandler.loadLogo();
      final months = _getMonthsInRange(_rangeStart!, _rangeEnd!);

      for (int i = 0; i < months.length; i++) {
        final date = months[i];
        final monthName = _getMonthName(date.month);

        setState(() {
          _currentStatus = 'Fetching data for $monthName ${date.year}...';
          _progress = i / months.length * 0.2;
        });

        try {
          final type = ref.read(typeProvider)!;
          final salaryDataList = await SalaryAPI.fetchSalaryByEmployee(
            type: type,
            month: date.month.toString(),
            year: date.year.toString(),
          );

          if (salaryDataList.isEmpty) {
            setState(() => _currentStatus = 'No data found for $monthName ${date.year}');
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }

          for (int j = 0; j < salaryDataList.length; j++) {
            final salaryData = salaryDataList[j];
            final totalItems = salaryDataList.length * months.length;
            final currentItem = i * salaryDataList.length + j;
            final employeeName =
                salaryData['manpowerDetails']?['fullName'] ?? 'Unknown';

            setState(() {
              _currentStatus =
                  'Generating PDF for $employeeName ($monthName ${date.year})...';
              _progress = 0.2 + (currentItem / totalItems * 0.6);
            });

            try {
              final companyName =
                  salaryData['companyDetails']?['name']?.toString() ?? 'Company';
              final user = ref.read(currentUserProvider);

              final pdfFile = await PDFGenerator.generateSalarySlipPDF(
                jsonData: salaryData,
                companyName: companyName,
                logoBytes: logoBytes,
                companyAddress: user?.address ?? '',
              );

              final fileBytes = await pdfFile.readAsBytes();
              final fileName = pdfFile.path.split('/').last;
              pdfFiles.add(PdfFile(fileName: fileName, fileBytes: fileBytes));
              successfulCount++;
            } catch (e) {
              debugPrint('Error generating PDF for $employeeName: $e');
              failedCount++;
            }

            await Future.delayed(const Duration(milliseconds: 50));
          }
        } catch (e) {
          debugPrint('Error fetching data for ${date.month}/${date.year}: $e');
          failedCount++;
        }
      }

      if (pdfFiles.isNotEmpty) {
        setState(() {
          _currentStatus = 'Saving ${pdfFiles.length} PDF file(s)...';
          _progress = 0.9;
        });

        final folderName =
            'SalarySlips_${_formatDate(_rangeStart).replaceAll('/', '_')}_to_${_formatDate(_rangeEnd).replaceAll('/', '_')}';

        final saveResult = await FileHandler.saveMultipleFiles(
          context: context,
          files: pdfFiles,
          folderName: folderName,
        );

        if (saveResult.success && saveResult.savedCount > 0) {
          _showSuccessDialog(
              '✅ Successfully saved ${saveResult.savedCount} PDF file(s)');
        } else {
          _showSnackBar(saveResult.message);
        }
      } else {
        _showSnackBar(
            'No PDFs were generated. Please check if salary data exists.');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _progress = 0.0;
          _currentStatus = '';
        });
      }
    }
  }

  List<DateTime> _getMonthsInRange(DateTime start, DateTime end) {
    final months = <DateTime>[];
    DateTime current = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(end.year, end.month, 1);
    while (
        current.isBefore(endMonth) || current.isAtSameMomentAs(endMonth)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }
    return months;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasRange = _rangeStart != null && _rangeEnd != null;

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: "Download All"),
      body: Stack(
        children: [
          CornerClippedScreenSimple(
            child: Column(
              children: [
                // Progress indicator
                if (_isGenerating) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        Text(_currentStatus,
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],

                // FROM / TO fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("From", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 5),
                      _textField(_formatDate(_rangeStart)),
                      const SizedBox(height: 15),
                      const Text("To", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 5),
                      _textField(_formatDate(_rangeEnd)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Calendar
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        rangeStartDay: _rangeStart,
                        rangeEndDay: _rangeEnd,
                        rangeSelectionMode: RangeSelectionMode.toggledOn,
                        calendarFormat: CalendarFormat.month,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        selectedDayPredicate: (day) => false,
                        onRangeSelected: (start, end, focusedDay) {
                          setState(() {
                            _rangeStart = start;
                            _rangeEnd = end;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          rangeHighlightColor: Colors.blue.shade100,
                          rangeStartDecoration: const BoxDecoration(
                              color: Colors.blue, shape: BoxShape.circle),
                          rangeEndDecoration: const BoxDecoration(
                              color: Colors.blue, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom buttons
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      // View Details + Download All row
                      Row(
                        children: [
                          // View Details
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isGenerating || !hasRange ? null : _viewDetails,
                              icon: const Icon(Icons.visibility_rounded,
                                  size: 16, color: Colors.white),
                              label: const Text('View Details',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: const Color(0xFF6366F1),
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Download All
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isGenerating || !hasRange
                                  ? null
                                  : _downloadAllSalarySlips,
                              icon: _isGenerating
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white)),
                                    )
                                  : const Icon(Icons.download_rounded,
                                      size: 16, color: Colors.white),
                              label: Text(
                                _isGenerating ? 'Working...' : 'Download All',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.blue,
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Back button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed:
                              _isGenerating ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            side:
                                BorderSide(color: Colors.blue.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Back',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField(String text) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: text == "Input Text" ? Colors.black54 : Colors.black,
                fontSize: 14,
              ),
            ),
          ),
          const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}