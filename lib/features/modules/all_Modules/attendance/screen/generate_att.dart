import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../provider/AttendanceService.dart';
import 'attendanceScreen.dart';

class GenerateAttendanceSheetScreen extends ConsumerStatefulWidget {
  const GenerateAttendanceSheetScreen({super.key});

  @override
  ConsumerState<GenerateAttendanceSheetScreen> createState() =>
      _GenerateAttendanceSheetScreenState();
}

class _GenerateAttendanceSheetScreenState
    extends ConsumerState<GenerateAttendanceSheetScreen> {
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;
  bool isDownloading = false;

  // Share/Download Dialog
// ✅ STEP 1: Show format selection (Excel / PDF)
  void _showFormatSelectionDialog() {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please select a date range first"),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      return;
    }

    String selectedFormat = 'excel';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Text(
                    "Select Format",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Choose file format to export",
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),

                  // Excel option
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.table_chart,
                          color: Colors.green, size: 24),
                    ),
                    title: Text(
                      "Excel (.xlsx)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: selectedFormat == 'excel'
                            ? Colors.green
                            : colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      "Spreadsheet format",
                      style: TextStyle(
                          fontSize: 13, color: colorScheme.onSurfaceVariant),
                    ),
                    trailing: selectedFormat == 'excel'
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const SizedBox.shrink(),
                    onTap: () {
                      setSheetState(() => selectedFormat = 'excel');
                      context.pop();
                      _showShareOrDownloadDialog(format: selectedFormat);
                    },
                  ),

                  const SizedBox(height: 12),

                  // PDF option
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.picture_as_pdf,
                          color: Colors.red, size: 24),
                    ),
                    title: Text(
                      "PDF (.pdf)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: selectedFormat == 'pdf'
                            ? Colors.red
                            : colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      "Document format",
                      style: TextStyle(
                          fontSize: 13, color: colorScheme.onSurfaceVariant),
                    ),
                    trailing: selectedFormat == 'pdf'
                        ? const Icon(Icons.check_circle, color: Colors.red)
                        : const SizedBox.shrink(),
                    onTap: () {
                      setSheetState(() => selectedFormat = 'pdf');
                      context.pop();
                      _showShareOrDownloadDialog(format: selectedFormat);
                    },
                  ),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text("Cancel", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// ✅ STEP 2: Share or Download (now receives format)
  void _showShareOrDownloadDialog({required String format}) {
    final fileExt = format == 'pdf' ? 'PDF' : 'Excel';
    final sheetName =
        "Attendance Sheet ${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
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
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(sheetName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                "Format: $fileExt",
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                "What would you like to do?",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _ActionTile(
                icon: Icons.share_rounded,
                color: colorScheme.primary,
                title: "Share",
                subtitle: "Send file via apps",
                onTap: () {
                  context.pop();
                  _downloadAndShareAttendance(format: format);
                },
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.download_rounded,
                color: colorScheme.tertiary,
                title: "Download",
                subtitle: "Save to your device",
                onTap: () {
                  context.pop();
                  _downloadAttendanceFile(format: format);
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text("Cancel", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  // Action Tile Widget
  Widget _ActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
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
        style: TextStyle(
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }

  // Generate CSV and share directly

  // Download attendance file to device
  Future<void> _downloadAndShareAttendance({String format = 'excel'}) async {
    try {
      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      final type = ref.read(typeProvider);
      final siteId = ref.read(selectedSiteIdProvider);

      final bytes = await AttendanceApi.fetchAttendanceFromTo(
        type: type!,
        siteId: siteId!,
        startDate: startDate,
        endDate: endDate,
        format: format, // ✅
      );

      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("No attendance data available"),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final fileExt = format == 'pdf' ? '.pdf' : '.xlsx';
      final mimeType = format == 'pdf'
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      final fileName =
          'attendance_${DateFormat('yyyyMMdd').format(startDate!)}_to_${DateFormat('yyyyMMdd').format(endDate!)}$fileExt';
      final tempPath = '${tempDir.path}/$fileName';

      await File(tempPath).writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(tempPath, mimeType: mimeType)],
        text:
            'Attendance Sheet: ${DateFormat('dd/MM/yyyy').format(startDate!)} to ${DateFormat('dd/MM/yyyy').format(endDate!)}',
        subject: 'Attendance Report',
      );

      Future.delayed(const Duration(seconds: 60), () async {
        final f = File(tempPath);
        if (await f.exists()) await f.delete();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to share: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
        isDownloading = false;
      });
    }
  }

  Future<void> _downloadAttendanceFile({String format = 'excel'}) async {
    try {
      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      final type = ref.read(typeProvider);
      final siteId = ref.read(selectedSiteIdProvider);

      final bytes = await AttendanceApi.fetchAttendanceFromTo(
        type: type!,
        siteId: siteId!,
        startDate: startDate,
        endDate: endDate,
        format: format, // ✅
      );

      if (bytes.isEmpty) return;

      final fileExt = format == 'pdf' ? '.pdf' : '.xlsx';
      final fileName =
          'attendance_${DateFormat('yyyyMMdd').format(startDate!)}_to_${DateFormat('yyyyMMdd').format(endDate!)}$fileExt';

      if (Platform.isAndroid || Platform.isIOS) {
        await _saveMobileAttendance(bytes, fileName);
      } else {
        await _saveDesktopAttendance(bytes, fileName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Download failed: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
        isDownloading = false;
      });
    }
  }

  // Save CSV on mobile devices
  Future<void> _saveMobileAttendance(Uint8List bytes, String fileName) async {
    try {
      final fileName =
          'attendance_${DateFormat('yyyyMMdd').format(startDate!)}_to_${DateFormat('yyyyMMdd').format(endDate!)}.csv';

      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Attendance Sheet',
        fileName: fileName,
        bytes: bytes,
      );

      if (outputPath != null) {
        debugPrint('💾 Attendance CSV saved to: $outputPath');

        // Try to open the saved file
        final result = await OpenFile.open(outputPath);
        debugPrint('📂 Open file result: ${result.type} - ${result.message}');

        // Show success message with open and share options
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✅ Attendance file saved successfully!'),
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
                          await Share.shareXFiles(
                            [XFile(outputPath, mimeType: 'text/csv')],
                            text:
                                'Attendance Sheet - ${DateFormat('dd/MM/yyyy').format(startDate!)} to ${DateFormat('dd/MM/yyyy').format(endDate!)}',
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
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 8),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save operation canceled.'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Mobile attendance save error: $e');
      rethrow;
    }
  }

  // Save CSV on desktop
  Future<void> _saveDesktopAttendance(Uint8List bytes, String filename) async {
    final fileName =
        'attendance_${DateFormat('yyyyMMdd').format(startDate!)}_to_${DateFormat('yyyyMMdd').format(endDate!)}.csv';

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Attendance Sheet',
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
            Text('✅ Attendance file saved: $path'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => OpenFile.open(path),
              child: const Text('Open File'),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 8),
      ),
    );
  }

  String _generateCSVContent(dynamic data) {
    debugPrint('📊 Generating CSV from data type: ${data.runtimeType}');

    // CASE 1: If data is already a complete CSV string (most likely your API response)
    if (data is String) {
      debugPrint('✅ Data is already a CSV string, returning directly');
      return data;
    }

    // CASE 2: If data is a List of strings where each is a CSV line
    if (data is List<String>) {
      debugPrint('✅ Data is List<String> with ${data.length} lines');
      return data.join('\n');
    }

    // CASE 3: If data is a List of other types (check what we actually have)
    if (data is List) {
      debugPrint('📋 Data is List with ${data.length} items');
      debugPrint(
          '📋 First item type: ${data.isNotEmpty ? data.first.runtimeType : "empty"}');

      // Check if first item is a complete CSV string header
      if (data.isNotEmpty &&
          data.first is String &&
          (data.first as String).contains("ATTENDANCE SHEET")) {
        debugPrint(
            '✅ First item contains CSV header, treating as List<String>');
        return (data as List<String>).join('\n');
      }

      // Otherwise, if it's structured data (List of Maps) - your current logic
      final buffer = StringBuffer();

      for (var item in data) {
        if (item is String) {
          buffer.writeln(item);
        } else if (item is Map) {
          // Check what keys the Map has
          debugPrint('🗺️ Map keys: ${item.keys}');

          // If it has the attendance grid format
          if (item.containsKey('employeeName') &&
              item.containsKey('attendance')) {
            // This would need custom formatting for your specific grid
            // _formatAttendanceGrid(buffer, item);
          } else {
            // Simple CSV row format
            buffer.writeln(
                '${item['date']},${item['employeeId']},${item['employeeName']},${item['checkIn']},${item['checkOut']},${item['totalHours']},${item['status']}');
          }
        } else {
          buffer.writeln(item.toString());
        }
      }
      return buffer.toString();
    }

    // CASE 4: Any other type
    debugPrint('📦 Fallback: Converting data to string');
    return data.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: CustomDrawer(),
      appBar: CustomAppBar(title: "Generate Attendance Sheet"),
      body: Stack(
        children: [
          CornerClippedScreenSimple(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Date Range Selection Card
                  DateRangePickerDialog(
                    startDate: startDate,
                    endDate: endDate,
                    onDownload: (start, end) {
                      setState(() {
                        startDate = start;
                        endDate = end;
                      });
                      _showFormatSelectionDialog();
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Loading overlay
          if (isLoading && isDownloading)
            Container(
              color: colorScheme.shadow.withOpacity(0.54),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: colorScheme.onPrimary),
                    const SizedBox(height: 16),
                    Text(
                      isDownloading
                          ? 'Downloading attendance sheet...'
                          : 'Loading...',
                      style:
                          TextStyle(color: colorScheme.onPrimary, fontSize: 16),
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

class DateRangePickerDialog extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime start, DateTime end) onDownload;

  const DateRangePickerDialog({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDownload,
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

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_start ?? DateTime.now())
        : (_end ?? _start ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) _end = null;
      } else {
        if (_start != null && picked.isBefore(_start!)) {
          _start = picked;
          _end = null;
        } else {
          _end = picked; // ✅ same date as _start is now allowed
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // DATE RANGE ROW
        Row(
          children: [
            Expanded(
              child: _dateBox(
                "From",
                _start != null
                    ? DateFormat("dd/MM/yyyy").format(_start!)
                    : "Input Text",
                () => _pickDate(isStart: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _dateBox(
                "To",
                _end != null
                    ? DateFormat("dd/MM/yyyy").format(_end!)
                    : "Input Text",
                () => _pickDate(isStart: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // CALENDAR CONTAINER LIKE IMAGE
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
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
                } else if (!selectedDay.isBefore(_start!)) {
                  // ✅ isBefore check allows same day (isAfter was blocking it)
                  _end = selectedDay;
                }
                _focused = focusedDay;
              });
            },
            onPageChanged: (fd) => setState(() => _focused = fd),

            // STYLES MATCHING IMAGE
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              rangeStartDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              withinRangeDecoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15),
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
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.pop(),
                child: const Text("Back"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: (_start != null && _end != null)
                    ? () => widget.onDownload(_start!, _end!)
                    : null,
                child: const Text("Download"),
              ),
            ),
          ],
        )
      ],
    );
  }

  // SMALL BOX LIKE SCREENSHOT
  Widget _dateBox(String label, String value, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value,
                    style: TextStyle(
                      fontSize: 14,
                      color: value == "Input Text"
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                    )),
                Icon(Icons.calendar_today, size: 18, color: colorScheme.primary)
              ],
            ),
          ),
        )
      ],
    );
  }
}
