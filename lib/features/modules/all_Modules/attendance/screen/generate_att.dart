import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../provider/AttendanceService.dart';
import 'attendanceScreen.dart';
class GenerateAttendanceSheetScreen extends ConsumerStatefulWidget {


  const GenerateAttendanceSheetScreen({
    super.key,

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
        final siteId=ref.read(selectedSiteIdProvider);
        final res = await AttendanceApi.fetchAttendanceFromTo(
          type: type!,
          siteId: siteId!,
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
      appBar: CustomAppBar(
          title:"Generate Attendance Sheet"
      ),
      body: BottomButtonWrapper(
        child: Padding(
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
      ),
    );
  }
}
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
  DateTime? _start;
  DateTime? _end;
  DateTime _focused = DateTime.now();

  @override
  void initState() {
    super.initState();
    _start = widget.startDate;
    _end = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADER LIKE IMAGE
            const Text(
              "Select Date Range",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // DATE RANGE ROW
            Row(
              children: [
                Expanded(
                  child: _dateBox(
                    "From",
                    _start != null
                        ? DateFormat("dd/MM/yyyy").format(_start!)
                        : "Input Text",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _dateBox(
                    "To",
                    _end != null
                        ? DateFormat("dd/MM/yyyy").format(_end!)
                        : "Input Text",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // CALENDAR CONTAINER LIKE IMAGE
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffF7F9FC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TableCalendar(
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: _focused,
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {CalendarFormat.month: "Month"},
                rangeSelectionMode: RangeSelectionMode.toggledOn,
                rangeStartDay: _start,
                rangeEndDay: _end,

                // SELECT LOGIC
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    if (_start == null || (_start != null && _end != null)) {
                      _start = selectedDay;
                      _end = null;
                    } else if (selectedDay.isAfter(_start!)) {
                      _end = selectedDay;
                    }
                    _focused = focusedDay;
                  });
                },
                onPageChanged: (fd) => setState(() => _focused = fd),

                // STYLES MATCHING IMAGE
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  rangeStartDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  withinRangeDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  defaultDecoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                ),

                headerStyle: HeaderStyle(
                  titleCentered: true,
                  titleTextStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  formatButtonVisible: false,
                  leftChevronIcon: const Icon(Icons.chevron_left),
                  rightChevronIcon: const Icon(Icons.chevron_right),
                ),

                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // BUTTON ROW (LIKE BACK / DOWNLOAD)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xffF2F3F5),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Back"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: (_start != null && _end != null)
                        ? () => Navigator.pop(context, {
                      'startDate': _start,
                      'endDate': _end,
                    })
                        : null,
                    child: const Text("Download"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // SMALL BOX LIKE SCREENSHOT
  Widget _dateBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value,
                  style: TextStyle(
                    fontSize: 14,
                    color: value == "Input Text" ? Colors.grey : Colors.black,
                  )),
              const Icon(Icons.calendar_today, size: 18, color: Colors.blue)
            ],
          ),
        )
      ],
    );
  }
}

