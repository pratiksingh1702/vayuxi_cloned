import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
  void _showShareOrDownloadDialog() {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date range first")),
      );
      return;
    }

    final sheetName = "Attendance Sheet ${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}";

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
              // ─── Drag Handle ───
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // ─── Title ───
              Text(
                sheetName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "What would you like to do?",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // ─── Actions ───
              _ActionTile(
                icon: Icons.share_rounded,
                color: Colors.blue,
                title: "Share",
                subtitle: "Send file via apps",
                onTap: () {
                  Navigator.pop(context);
                  _downloadAndShareAttendance();
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
                  _downloadAttendanceFile();
                },
              ),

              const SizedBox(height: 16),

              // ─── Cancel ───
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

  // Action Tile Widget
  Widget _ActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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

  // Generate CSV and share directly
  Future<void> _downloadAndShareAttendance() async {
    try {
      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      debugPrint('🔄 Starting share process...');

      // First generate CSV data
      final csvData = await _generateAttendanceCSVData();

      if (csvData.isEmpty) {
        debugPrint('❌ CSV data is empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No attendance data available"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      debugPrint('✅ CSV data generated: ${csvData.length} chars');

      // Add UTF-8 BOM for Excel compatibility (Excel prefers this)
      final bytes = Uint8List.fromList(
          [0xEF, 0xBB, 0xBF, ...utf8.encode(csvData)]
      );

      debugPrint('✅ Converted to bytes with BOM: ${bytes.length} bytes');

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'attendance_${DateFormat('yyyyMMdd').format(startDate!)}_to_${DateFormat('yyyyMMdd').format(endDate!)}.csv';
      final tempPath = '${tempDir.path}/$fileName';

      debugPrint('📁 Saving to temp path: $tempPath');

      // Save file
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes, flush: true);

      // Verify the file was created
      final fileExists = await tempFile.exists();
      final fileSize = await tempFile.length();

      if (!fileExists || fileSize == 0) {
        debugPrint('❌ File not created or empty. Exists: $fileExists, Size: $fileSize');
        throw Exception('Failed to create attendance file');
      }

      debugPrint('💾 File saved successfully: $tempPath (${fileSize} bytes)');

      // Read back a sample to verify
      final sampleContent = await tempFile.readAsString();
      debugPrint('📄 File preview (first 200 chars): ${sampleContent.substring(0, sampleContent.length > 200 ? 200 : sampleContent.length)}');

      // Prepare file for sharing
      final xFile = XFile(
        tempPath,
        mimeType: 'text/csv',
        name: fileName,
      );

      // Prepare share text
      final shareText = 'Attendance Sheet\n'
          'Site: ${DateFormat('dd/MM/yyyy').format(startDate!)} to ${DateFormat('dd/MM/yyyy').format(endDate!)}';

      debugPrint('📤 Sharing file...');

      // Share with proper configuration
      final shareResult = await Share.shareXFiles(
        [xFile],
        text: shareText,
        subject: 'Attendance Report CSV',
        sharePositionOrigin: Rect.fromLTWH(
            0,
            0,
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height / 3
        ),
      );

      debugPrint('✅ Share completed with result: $shareResult');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Attendance file ready for sharing"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.white,
            onPressed: () async {
              try {
                final result = await OpenFile.open(tempPath);
                debugPrint('📂 Open file result: ${result.type}');
              } catch (e) {
                debugPrint('❌ Error opening file: $e');
              }
            },
          ),
        ),
      );

      // Schedule cleanup (increased to 60 seconds to allow time for sharing)
      Future.delayed(const Duration(seconds: 60), () async {
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
            debugPrint('🗑️ Temporary file deleted: $tempPath');
          }
        } catch (e) {
          debugPrint('⚠️ Error deleting temp file: $e');
        }
      });

    } on PlatformException catch (e) {
      debugPrint('❌ PlatformException during share: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sharing failed: ${e.message}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _downloadAndShareAttendance: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to share: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
        isDownloading = false;
      });
    }
  }
  // Download attendance file to device
  Future<void> _downloadAttendanceFile() async {
    try {
      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      // Check storage permission
      if (!await _requestPermissions()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Storage permission is required to save the file"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Generate CSV data
      final csvData = await _generateAttendanceCSVData();
      if (csvData.isEmpty) return;

      // Convert to bytes
      final bytes = Uint8List.fromList(utf8.encode(csvData));

      if (Platform.isAndroid || Platform.isIOS) {
        await _saveMobileAttendance(bytes);
      } else {
        await _saveDesktopAttendance(bytes);
      }

    } catch (e) {
      debugPrint('❌ Download attendance failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Download failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
        isDownloading = false;
      });
    }
  }

  // Generate attendance CSV data
  Future<String> _generateAttendanceCSVData() async {
    try {
      final type = ref.read(typeProvider);
      final siteId = ref.read(selectedSiteIdProvider);

      if (siteId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a site first"),
            backgroundColor: Colors.red,
          ),
        );
        return '';
      }

      final res = await AttendanceApi.fetchAttendanceFromTo(
        type: type!,
        siteId: siteId,
        startDate: startDate,
        endDate: endDate,
      );

      debugPrint('🔍 API Response received successfully');
      debugPrint('📊 Data type: ${res.data.runtimeType}');
      debugPrint('📊 Data length: ${(res.data as String).length} chars');
      debugPrint('📊 First 200 chars: ${(res.data as String).substring(0, min((res.data as String).length, 200))}');

      // Generate CSV content
      final csvContent = _generateCSVContent(res.data);

      debugPrint('📊 Generated CSV length: ${csvContent.length} chars');
      debugPrint('📊 Generated CSV preview:\n${csvContent.substring(0, min(csvContent.length, 300))}');
      debugPrint('📊 Generated CSV ends with: ${csvContent.substring(csvContent.length - min(50, csvContent.length))}');

      if (csvContent.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No attendance data found for the selected dates"),
            backgroundColor: Colors.orange,
          ),
        );
        return '';
      }

      return csvContent;
    } catch (e) {
      debugPrint('❌ Attendance CSV generation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to generate attendance sheet: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
      return '';
    }
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
            "Storage permission is required to save attendance files. "
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

  // Save CSV on mobile devices
  Future<void> _saveMobileAttendance(Uint8List bytes) async {
    try {
      final fileName = 'attendance_${DateFormat('yyyyMMdd').format(startDate!)}_to_${DateFormat('yyyyMMdd').format(endDate!)}.csv';

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
                            text: 'Attendance Sheet - ${DateFormat('dd/MM/yyyy').format(startDate!)} to ${DateFormat('dd/MM/yyyy').format(endDate!)}',
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
      debugPrint('❌ Mobile attendance save error: $e');
      rethrow;
    }
  }

  // Save CSV on desktop
  Future<void> _saveDesktopAttendance(Uint8List bytes) async {
    final fileName = 'attendance_${DateFormat('yyyyMMdd').format(startDate!)}_to_${DateFormat('yyyyMMdd').format(endDate!)}.csv';

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
        backgroundColor: Colors.green,
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
      debugPrint('📋 First item type: ${data.isNotEmpty ? data.first.runtimeType : "empty"}');

      // Check if first item is a complete CSV string header
      if (data.isNotEmpty && data.first is String && (data.first as String).contains("ATTENDANCE SHEET")) {
        debugPrint('✅ First item contains CSV header, treating as List<String>');
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
          if (item.containsKey('employeeName') && item.containsKey('attendance')) {
            // This would need custom formatting for your specific grid
            // _formatAttendanceGrid(buffer, item);
          } else {
            // Simple CSV row format
            buffer.writeln('${item['date']},${item['employeeId']},${item['employeeName']},${item['checkIn']},${item['checkOut']},${item['totalHours']},${item['status']}');
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
    return Scaffold(
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
                      _showShareOrDownloadDialog();
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
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      isDownloading ? 'Downloading attendance sheet...' : 'Loading...',
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

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: Colors.white,
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