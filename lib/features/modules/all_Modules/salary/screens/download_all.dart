// lib/features/salary/screens/select_range_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';

import 'package:untitled2/features/modules/all_Modules/salary/screens/widget/file_handler.dart';
import 'package:untitled2/features/modules/all_Modules/salary/screens/widget/pdf_generator.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../service-provider/salaryClient.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectRangeScreen extends ConsumerStatefulWidget {
  const SelectRangeScreen({super.key});

  @override
  ConsumerState<SelectRangeScreen> createState() =>
      _SelectRangeScreenState();
}

class _SelectRangeScreenState
    extends ConsumerState<SelectRangeScreen>  {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isGenerating = false;
  double _progress = 0.0;
  String _currentStatus = '';
  bool _askForDirectory = true; // Toggle for asking directory vs auto-save

  // Helper function to format DateTime to string
  String _formatDate(DateTime? date) {
    if (date == null) return "Input Text";
    return "${date.day}/${date.month}/${date.year}";
  }

  // Download all salary slips
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

      // Generate list of months in the range
      final months = _getMonthsInRange(_rangeStart!, _rangeEnd!);

      for (int i = 0; i < months.length; i++) {
        final date = months[i];
        final monthName = _getMonthName(date.month);

        setState(() {
          _currentStatus = 'Fetching data for $monthName ${date.year}...';
          _progress = i / months.length * 0.2;
        });

        try {
          final type=ref.read(typeProvider)!;
          final salaryDataList = await SalaryAPI.fetchSalaryByEmployee(
            type: type,
            month: date.month.toString(),
            year: date.year.toString(),
          );

          print('Fetched ${salaryDataList.length} records for ${date.month}/${date.year}');

          if (salaryDataList.isEmpty) {
            setState(() {
              _currentStatus = 'No data found for $monthName ${date.year}';
            });
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }

          for (int j = 0; j < salaryDataList.length; j++) {
            final salaryData = salaryDataList[j];
            final totalItems = salaryDataList.length * months.length;
            final currentItem = i * salaryDataList.length + j;
            final employeeName = salaryData['manpowerDetails']?['fullName'] ?? 'Unknown';

            setState(() {
              _currentStatus = 'Generating PDF for $employeeName ($monthName ${date.year})...';
              _progress = 0.2 + (currentItem / totalItems * 0.6);
            });

            try {
              // Get company name from data
              final companyName = salaryData['companyDetails']?['name']?.toString() ?? 'Company';

              final pdfFile = await PDFGenerator.generateSalarySlipPDF(
                jsonData: salaryData,
                companyName: companyName,
                logoBytes: logoBytes,
              );

              // Read file bytes
              final fileBytes = await pdfFile.readAsBytes();
              final fileName = pdfFile.path.split('/').last;

              pdfFiles.add(PdfFile(
                fileName: fileName,
                fileBytes: fileBytes,
              ));

              successfulCount++;
              print('Generated PDF for $employeeName');

            } catch (e, stack) {
              print('Error generating PDF for $employeeName: $e');
              print('Stack trace: $stack');
              failedCount++;
            }

            // Small delay to prevent overwhelming the system
            await Future.delayed(const Duration(milliseconds: 50));
          }
        } catch (e) {
          print('Error fetching data for ${date.month}/${date.year}: $e');
          failedCount++;
        }
      }

      // Save files
      if (pdfFiles.isNotEmpty) {
        setState(() {
          _currentStatus = 'Saving ${pdfFiles.length} PDF file(s)...';
          _progress = 0.9;
        });

        final folderName = 'SalarySlips_${_formatDate(_rangeStart).replaceAll('/', '_')}_to_${_formatDate(_rangeEnd).replaceAll('/', '_')}';

        final saveResult = await FileHandler.saveMultipleFiles(
          context: context,
          files: pdfFiles,
          folderName: folderName,
          askForDirectory: _askForDirectory,
        );

        if (saveResult.success && saveResult.savedCount > 0) {
          _showSuccessDialog(
            '✅ Successfully saved ${saveResult.savedCount} PDF file(s)',


          );
        } else {
          _showSnackBar(saveResult.message);
        }

      } else {
        _showSnackBar('No PDFs were generated. Please check if salary data exists.');
      }

    } catch (e, stack) {
      print('Error downloading salary slips: $e');
      print('Stack trace: $stack');
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isGenerating = false;
        _progress = 0.0;
        _currentStatus = '';
      });
    }
  }


  // Get list of months in date range
  List<DateTime> _getMonthsInRange(DateTime start, DateTime end) {
    final months = <DateTime>[];
    DateTime current = DateTime(start.year, start.month, 1);
    final endMonth = DateTime(end.year, end.month, 1);

    while (current.isBefore(endMonth) || current.isAtSameMomentAs(endMonth)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1, 1);
    }

    return months;
  }

  // Get month name
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentStatus,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],

                // TO / FROM INPUTS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("From", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 5),
                      textField(_formatDate(_rangeStart)),

                      const SizedBox(height: 15),

                      const Text("To", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 5),
                      textField(_formatDate(_rangeEnd)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // CALENDAR
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
                          rangeStartDecoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          rangeEndDecoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // BOTTOM BUTTONS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Back Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isGenerating ? null : () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.blue.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Back",
                              style: TextStyle(fontSize: 16, color: Colors.black)),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Download button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isGenerating ? null : () async {
                            await _downloadAllSalarySlips();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isGenerating
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Text(
                            "Download All",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      )
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

  // Helper TextField
  Widget textField(String text) {
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
          Icon(Icons.calendar_today, size: 18, color: Colors.black54),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}