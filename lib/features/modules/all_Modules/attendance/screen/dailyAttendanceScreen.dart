import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../provider/AttendanceService.dart';
import 'attendanceScreen.dart';

class DailyAttendanceScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;

  const DailyAttendanceScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  ConsumerState<DailyAttendanceScreen> createState() => _DailyAttendanceScreenState();
}

class _DailyAttendanceScreenState extends ConsumerState<DailyAttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF7FF),
      appBar: CustomAppBar(title: "Daily Attendance"),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildOptionCard(
                    title: "Select Date",
                    subtitle: "Mark attendance for a specific day",
                    icon: Icons.calendar_month_rounded,
                    color: Colors.blue.shade600,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendanceScreen(
                              siteId: widget.siteId,
                              siteName: widget.siteName,
                              selectedDate: picked,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildOptionCard(
                    title: "Generate Attendance Sheet",
                    subtitle: "Download attendance for a date range",
                    icon: Icons.description_rounded,
                    color: Colors.green.shade600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GenerateAttendanceSheetScreen(
                            siteId: widget.siteId,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Back Button at bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: RoundedButton(
              text: "Back",
              color: Colors.white,
              textColor: Colors.black,
              onPressed: () {
                Navigator.pop(context);
              },
              width:double.infinity,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),

        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class GenerateAttendanceSheetScreen extends ConsumerStatefulWidget {
  final String siteId;

  const GenerateAttendanceSheetScreen({
    super.key,
    required this.siteId,
  });

  @override
  ConsumerState<GenerateAttendanceSheetScreen> createState() =>
      _GenerateAttendanceSheetScreenState();
}

class _GenerateAttendanceSheetScreenState
    extends ConsumerState<GenerateAttendanceSheetScreen> {
  DateTime? startDate;
  DateTime? endDate;

  void _showDateRangePicker() {
    showDialog(
      context: context,
      builder: (context) => DateRangePickerDialog(
        startDate: startDate,
        endDate: endDate,
      ),
    ).then((value) {
      if (value != null) {
        setState(() {
          startDate = value['startDate'];
          endDate = value['endDate'];
        });
      }
    });
  }
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      PermissionStatus status;
      if (Platform.isAndroid) {
        status = await Permission.manageExternalStorage.request();
      } else {
        status = await Permission.storage.request();
      }

      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        _showPermissionDialog();
        return false;
      }
      return false;
    } else if (Platform.isIOS) {
      return true;
    }
    return true;
  }
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
            "Storage permission is required to save salary slip files. "
                "Please grant the permission in app settings."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }


  Future<void> _generateAndSaveCSV() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date range")),
      );
      return;
    }

    // Check storage permission

    if (await _requestPermissions() ) {
      final type = ref.read(typeProvider);

      try {
        final res = await AttendanceApi.fetchAttendanceFromTo(
          type: type!,
          siteId: widget.siteId,
          startDate: startDate,
          endDate: endDate,
        );

        // Generate CSV content
        final csvContent = _generateCSVContent(res.data);

        // Save file
        final fileName = 'attendance_${DateFormat('yyyyMMdd').format(startDate!)}_to_${DateFormat('yyyyMMdd').format(endDate!)}.csv';
        final filePath = await _saveCSVFile(fileName, csvContent);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("File saved to: $filePath"),
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
          ),
        );
      }

    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Storage permission is required to save the file")),
    );
    return;


  }

  String _generateCSVContent(dynamic data) {
    // If the data is already formatted as CSV lines (from your log output)
    if (data is String) {
      return data;
    }

    // If data is a List of strings (CSV lines)
    if (data is List<String>) {
      return data.join('\n');
    }

    // If data is a List of dynamic objects, try to extract CSV content
    if (data is List) {
      final buffer = StringBuffer();

      // Check if the first item contains CSV headers or formatted data
      for (var item in data) {
        if (item is String) {
          buffer.writeln(item);
        } else if (item is Map) {
          // If it's a map, convert to CSV format
          // Adjust this based on your actual API response structure
          buffer.writeln('${item['date']},${item['employeeId']},${item['employeeName']},${item['checkIn']},${item['checkOut']},${item['totalHours']},${item['status']}');
        }
      }
      return buffer.toString();
    }

    // Fallback - convert the entire response to string
    return data.toString();
  }
  Future<String> _saveCSVFile(String fileName, String content) async {
    final csvBytes = utf8.encode(content);
    final String? savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Attendance Sheet',
      fileName: fileName,
      lockParentWindow: true,
      bytes: csvBytes
     );

    if (savePath != null) {
      final File file = File(savePath);
      await file.writeAsBytes(csvBytes); // Fix: writeAsString instead of writeAsBytes
      return file.path;
    } else {
      throw Exception('User cancelled file save');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate Attendance Sheet"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date Range Selection Card
            InkWell(
              onTap: _showDateRangePicker,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Date Range",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      startDate != null && endDate != null
                          ? '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}'
                          : "Tap to select date range",
                      style: TextStyle(
                        fontSize: 16,
                        color: startDate != null && endDate != null
                            ? Colors.black
                            : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (startDate != null && endDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${endDate!.difference(startDate!).inDays + 1} days selected',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Generate Button
            ElevatedButton.icon(
              icon: const Icon(Icons.download_rounded),
              label: const Text("Generate & Save CSV"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _generateAndSaveCSV,
            )
          ],
        ),
      ),
    );
  }
}

// Date Range Picker Dialog
// Date Range Picker Dialog
class DateRangePickerDialog extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const DateRangePickerDialog({
    super.key,
    this.startDate,
    this.endDate,
  });

  @override
  State<DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<DateRangePickerDialog> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.startDate;
    _selectedEndDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Date Range",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedStartDate, day) ||
                    isSameDay(_selectedEndDate, day);
              },
              rangeStartDay: _selectedStartDate,
              rangeEndDay: _selectedEndDate,
              calendarFormat: CalendarFormat.month,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              onDaySelected: (selectedDay, focusedDay) {
                if (_selectedStartDate == null) {
                  setState(() {
                    _selectedStartDate = selectedDay;
                  });
                } else if (_selectedEndDate == null && selectedDay.isAfter(_selectedStartDate!)) {
                  setState(() {
                    _selectedEndDate = selectedDay;
                  });
                } else {
                  setState(() {
                    _selectedStartDate = selectedDay;
                    _selectedEndDate = null;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                rangeHighlightColor: Colors.blue.withOpacity(0.3),
                rangeStartDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                withinRangeTextStyle: const TextStyle(color: Colors.black),
                withinRangeDecoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _selectedStartDate != null && _selectedEndDate != null
                      ? () {
                    Navigator.of(context).pop({
                      'startDate': _selectedStartDate,
                      'endDate': _selectedEndDate,
                    });
                  }
                      : null,
                  child: const Text("Confirm"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}