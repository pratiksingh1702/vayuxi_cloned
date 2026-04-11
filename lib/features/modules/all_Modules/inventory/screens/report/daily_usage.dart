import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import '../../../../../../core/utlis/colors/colors.dart';
import '../../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../site_Details/providers/site_current_provider.dart';
import '../../models/inventory_model.dart';
import '../../provider/inventory_provider.dart';
import '../edit_inventory.dart';

// BeautifulDatePicker Widget
class BeautifulDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;
  final Color? primaryColor;
  final Color? accentColor;
  final Color? backgroundColor;

  const BeautifulDatePicker({
    super.key,
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
    this.primaryColor,
    this.accentColor,
    this.backgroundColor,
  });

  @override
  State<BeautifulDatePicker> createState() => _BeautifulDatePickerState();
}

class _BeautifulDatePickerState extends State<BeautifulDatePicker> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _focusedDate = widget.initialDate ?? DateTime.now();
  }

  DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime clampFocusedDay({
    required DateTime focusedDay,
    required DateTime firstDay,
    required DateTime lastDay,
  }) {
    if (focusedDay.isAfter(lastDay)) return lastDay;
    if (focusedDay.isBefore(firstDay)) return firstDay;
    return focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final accentColor = Theme.of(context).colorScheme.tertiary;
    final backgroundColor = Theme.of(context).colorScheme.surfaceContainerLowest;
    final firstDay = DateTime(2020, 1, 1);
    final lastDay = normalize(DateTime.now());

    final safeFocusedDay = clampFocusedDay(
      focusedDay: normalize(_focusedDate),
      firstDay: firstDay,
      lastDay: lastDay,
    );

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Selected date display
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, color: primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(_selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Calendar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: widget.firstDate,
                  lastDay: widget.lastDate,
                  focusedDay: safeFocusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDate, day),

                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDate = normalize(selectedDay);
                      _focusedDate = normalize(focusedDay);
                    });
                  },

                  onPageChanged: (focusedDay) {
                    _focusedDate = normalize(focusedDay);
                  },
                  calendarFormat: _calendarFormat,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },

                  // Calendar styling
                  calendarStyle: CalendarStyle(
                    defaultTextStyle:
                        const TextStyle(fontWeight: FontWeight.w500),
                    weekendTextStyle:
                        const TextStyle(fontWeight: FontWeight.w500),
                    selectedTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    todayTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor),
                    ),
                    weekendDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade50,
                    ),
                    outsideDaysVisible: false,
                  ),

                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    formatButtonTextStyle: const TextStyle(color: Colors.white),
                    leftChevronIcon:
                        Icon(Icons.chevron_left, color: primaryColor),
                    rightChevronIcon:
                        Icon(Icons.chevron_right, color: primaryColor),
                    titleTextStyle: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    weekendStyle: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selectedDate),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Select',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getDayName(date)}, ${date.day} ${_getMonthName(date)} ${date.year}';
  }

  String _getDayName(DateTime date) {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
  }

  String _getMonthName(DateTime date) {
    return [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][date.month - 1];
  }
}

class DailyUsagePage extends ConsumerStatefulWidget {
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;

  const DailyUsagePage(
      {super.key, this.selectedStartDate, this.selectedEndDate});

  @override
  ConsumerState<DailyUsagePage> createState() => _DailyUsagePageState();
}

class _DailyUsagePageState extends ConsumerState<DailyUsagePage> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool isLoading = false;
  bool isDownloading = false;
  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.selectedStartDate;
    _selectedEndDate = widget.selectedEndDate;
  }

  // Function to show BeautifulDatePicker for start date
  Future<void> _showStartDatePicker() async {
    final date = await showDialog<DateTime>(
      context: context,
      builder: (context) => BeautifulDatePicker(
        initialDate: _selectedStartDate ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        title: "Select Start Date",
        primaryColor: Theme.of(context).primaryColor,
        accentColor: Theme.of(context).colorScheme.secondary,
      ),
    );

    if (date != null) {
      setState(() => _selectedStartDate = date);
    }
  }

  DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime clampFocusedDay({
    required DateTime focusedDay,
    required DateTime firstDay,
    required DateTime lastDay,
  }) {
    if (focusedDay.isAfter(lastDay)) return lastDay;
    if (focusedDay.isBefore(firstDay)) return firstDay;
    return focusedDay;
  }

  // Function to show BeautifulDatePicker for end date
  Future<void> _showEndDatePicker() async {
    final date = await showDialog<DateTime>(
      context: context,
      builder: (context) => BeautifulDatePicker(
        initialDate: _selectedEndDate ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        title: "Select End Date",
        primaryColor: Theme.of(context).primaryColor,
        accentColor: Theme.of(context).colorScheme.secondary,
      ),
    );

    if (date != null) {
      setState(() => _selectedEndDate = date);
    }
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

// =========================
// SHARE OR DOWNLOAD DIALOG
// =========================
  void _showShareOrDownloadDialog() {
    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select start date first"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final start = DateFormat('dd/MM/yyyy').format(_selectedStartDate!);
    final end = _selectedEndDate != null
        ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!)
        : start;

    final sheetName = "Daily Usage Report ($start to $end)";

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
              const SizedBox(height: 20),

              _ActionTile(
                icon: Icons.share,
                color: Colors.blue,
                title: "Share",
                subtitle: "Send file via apps",
                onTap: () {
                  Navigator.pop(context);
                  _downloadAndShare();
                },
              ),

              const SizedBox(height: 12),

              _ActionTile(
                icon: Icons.download,
                color: Colors.green,
                title: "Download",
                subtitle: "Save to device",
                onTap: () {
                  Navigator.pop(context);
                  _downloadReport();
                },
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _downloadReport() async {
    try {
      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      final bytes = await _generateReportData();
      if (bytes == null || bytes.isEmpty) {
        throw Exception("Empty file");
      }

      final startStr =
      DateFormat('yyyyMMdd').format(_selectedStartDate!);

      final endStr = _selectedEndDate != null
          ? DateFormat('yyyyMMdd').format(_selectedEndDate!)
          : startStr;

      final fileName = "daily_usage_${startStr}_to_${endStr}.xlsx";

      if (Platform.isAndroid || Platform.isIOS) {
        await _saveMobile(bytes, fileName);
      } else {
        await _saveDesktop(bytes, fileName);
      }
    } catch (e) {
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
  Future<void> _downloadAndShare() async {
    try {
      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      final bytes = await _generateReportData();
      if (bytes == null || bytes.isEmpty) {
        throw Exception("Empty file");
      }

      final tempDir = await getTemporaryDirectory();

      final startStr =
      DateFormat('yyyyMMdd').format(_selectedStartDate!);

      final endStr = _selectedEndDate != null
          ? DateFormat('yyyyMMdd').format(_selectedEndDate!)
          : startStr;

      final fileName = "daily_usage_${startStr}_to_${endStr}.xlsx";
      final tempPath = "${tempDir.path}/$fileName";

      final file = File(tempPath);
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [
          XFile(
            tempPath,
            mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          )
        ],
        text: "Daily Usage Report",
        subject: "Daily Usage Report ($startStr to $endStr)",
      );

      Future.delayed(const Duration(seconds: 30), () {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Share failed: ${e.toString()}"),
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
  Future<void> _saveMobile(Uint8List bytes, String fileName) async {
    final String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Report',
      fileName: fileName,
      bytes: bytes,
    );

    if (outputPath == null) return;

    await OpenFile.open(outputPath);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("File saved successfully"),
        backgroundColor: Colors.green,
      ),
    );
  }
  Future<void> _saveDesktop(Uint8List bytes, String fileName) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Report',
      fileName: fileName,
    );

    if (path == null) return;

    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("File saved at: $path"),
        backgroundColor: Colors.green,
      ),
    );
  }
  // Generate report data
  Future<Uint8List?> _generateReportData() async {
    try {
      final siteId = ref.read(selectedSiteIdProvider);
      if (siteId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No site selected")),
        );
        return null;
      }

      final result = await ref.read(generateReportProvider(
        (siteId: siteId, from: _selectedStartDate!),
      ).future);

      if (result.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No usage data found for the selected dates"),
            backgroundColor: Colors.orange,
          ),
        );
        return null;
      }

      return result;
    } catch (e) {
      debugPrint('❌ Report generation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to generate report: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  // Save report on mobile devices
  Future<void> _saveMobileReport(Uint8List bytes) async {
    try {
      final fileName =
          "daily_usage_${DateFormat('yyyyMMdd').format(_selectedStartDate!)}${_selectedEndDate != null ? '_to_${DateFormat('yyyyMMdd').format(_selectedEndDate!)}' : ''}.xlsx";

      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Daily Usage Report',
        fileName: fileName,
        bytes: bytes,
      );

      if (outputPath != null) {
        debugPrint('💾 Report saved to: $outputPath');

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
                const Text('✅ Report saved successfully!'),
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
                            [
                              XFile(outputPath,
                                  mimeType:
                                      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
                            ],
                            text:
                                'Daily Usage Report - ${DateFormat('dd/MM/yyyy').format(_selectedStartDate!)}${_selectedEndDate != null ? ' to ${DateFormat('dd/MM/yyyy').format(_selectedEndDate!)}' : ''}',
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
      debugPrint('❌ Mobile report save error: $e');
      rethrow;
    }
  }

  // Save report on desktop
  Future<void> _saveDesktopReport(Uint8List bytes) async {
    final fileName =
        "daily_usage_${DateFormat('yyyyMMdd').format(_selectedStartDate!)}${_selectedEndDate != null ? '_to_${DateFormat('yyyyMMdd').format(_selectedEndDate!)}' : ''}.xlsx";

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Daily Usage Report',
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
            Text('✅ Report saved: $path'),
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




  @override
  Widget build(BuildContext context) {
    print("🧱 BUILD DailyUsagePage");
    print("   StartDate: $_selectedStartDate");
    print("   EndDate: $_selectedEndDate");
    final siteId = ref.watch(selectedSiteIdProvider);
    if (siteId == null) {
      return const Scaffold(
        body: Center(child: Text("No site selected")),
      );
    }
    final firstDay = DateTime(2020, 1, 1);
    final lastDay = normalize(DateTime.now());

    final inventoriesAsync = ref.watch(inventoryProvider(siteId));

    final usageAsync = ref.watch(
      inventoryUsageRangeProvider(InventoryUsageRangeParams(
        siteId: siteId,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      )),
    );

    return Scaffold(
      appBar: CustomAppBar(title: "Daily Inventory Usage"),
      body: Stack(
        children: [
          BottomButtonWrapper(
            customButtons: [
              CustomButton(
                button: RoundedButton(
                  text: "Download Report",
                  color: Colors.blue,
                  textColor: Colors.white,
                  onPressed:
                      _showShareOrDownloadDialog, // Updated to show dialog
                ),
              ),
            ],
            child: Column(
              children: [
                // Date picker section
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // START DATE FIELD
                      Expanded(
                        child: GestureDetector(
                          onTap: _showStartDatePicker,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: Theme.of(context).primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedStartDate != null
                                        ? DateFormat('dd/MM/yyyy')
                                            .format(_selectedStartDate!)
                                        : "Start Date",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedStartDate != null
                                          ? Colors.black
                                          : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // END DATE FIELD
                      Expanded(
                        child: GestureDetector(
                          onTap: _showEndDatePicker,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: Theme.of(context).primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedEndDate != null
                                        ? DateFormat('dd/MM/yyyy')
                                            .format(_selectedEndDate!)
                                        : "End Date",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedEndDate != null
                                          ? Colors.black
                                          : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // List of usages
                Expanded(
                  child: usageAsync.when(
                    loading: () =>
                    const Center(child: CircularProgressIndicator()),
                    error: (e, _) {print("Usage error: $e");return Center(child: Text("Usage error: $e"));},
                    data: (usages) {
                      if (usages.isEmpty) {
                        return const Center(
                            child: Text("No usage records found."));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: usages.length,
                        itemBuilder: (context, index) {
                          final usage = usages[index];

                          // 🔥 JOIN HAPPENS HERE
                          final inventory = usage.inventory!;

                          return Card(
                            elevation: 0,
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(inventory.name),
                              trailing: inventory.id.isEmpty
                                  ? null
                                  : IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditInventoryScreen(
                                              inventory: inventory),
                                    ),
                                  );
                                },
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text("Type: ${inventory.type}"),
                                  Text(
                                    "Quantity: ${usage.quantityUsed} ${inventory.uom ?? ''}",
                                  ),
                                  Text("Used By: ${usage.usedByName}"),
                                  Text(
                                    "Date: ${DateFormat('dd/MM/yyyy').format(usage.usageDate)}",
                                  ),
                                ],
                              ),
                              onTap: inventory.id.isEmpty
                                  ? null
                                  : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditInventoryScreen(
                                            inventory: inventory),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
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
                      isDownloading ? 'Downloading report...' : 'Loading...',
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
