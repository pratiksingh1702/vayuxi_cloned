import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import '../../../../../../core/utlis/colors/colors.dart';
import '../../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../site_Details/providers/site_current_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final primaryColor= AppColors.primaryColor;
    final accentColor=AppColors.accentColor;
    final backgroundColor= AppColors.lightBlue;

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
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  focusedDay: _focusedDate,
                  selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDate = selectedDay;
                      _focusedDate = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDate = focusedDay;
                  },
                  calendarFormat: _calendarFormat,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },

                  // Calendar styling
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: const TextStyle(fontWeight: FontWeight.w500),
                    weekendTextStyle: const TextStyle(fontWeight: FontWeight.w500),
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
                    leftChevronIcon: Icon(Icons.chevron_left, color: primaryColor),
                    rightChevronIcon: Icon(Icons.chevron_right, color: primaryColor),
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
    return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1];
  }
}

class DailyUsagePage extends ConsumerStatefulWidget {
  const DailyUsagePage({super.key});

  @override
  ConsumerState<DailyUsagePage> createState() => _DailyUsagePageState();
}

class _DailyUsagePageState extends ConsumerState<DailyUsagePage> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool isLoading = false;
  bool isDownloading = false;

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

  // Share/Download Dialog
  void _showShareOrDownloadDialog() {
    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId == null || _selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date first")),
      );
      return;
    }

    final startDateStr = DateFormat('dd/MM/yyyy').format(_selectedStartDate!);
    final endDateStr = _selectedEndDate != null
        ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!)
        : DateFormat('dd/MM/yyyy').format(_selectedStartDate!);

    final sheetName = "Daily Usage Report $startDateStr${_selectedEndDate != null ? ' to $endDateStr' : ''}";

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
                subtitle: "Send report via apps",
                onTap: () {
                  Navigator.pop(context);
                  _downloadAndShareReport();
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
                  _downloadReportFile();
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

  // Generate report and share directly
  Future<void> _downloadAndShareReport() async {
    try {
      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      // Check if dates are selected
      if (_selectedStartDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a date")),
        );
        return;
      }

      // Check permissions first
      if (!await _requestPermissions()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Storage permission is required to save the file"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Generate report data
      final reportData = await _generateReportData();
      if (reportData == null) return;

      // Convert to bytes
      final bytes = reportData;

      // Save to temporary directory for sharing
      final tempDir = await getTemporaryDirectory();
      final fileName = "daily_usage_${DateFormat('yyyyMMdd').format(_selectedStartDate!)}_${_selectedEndDate != null ? DateFormat('yyyyMMdd').format(_selectedEndDate!) : DateFormat('yyyyMMdd').format(_selectedStartDate!)}.xlsx";
      final tempPath = '${tempDir.path}/$fileName';
      final tempFile = File(tempPath);

      await tempFile.writeAsBytes(bytes, flush: true);
      debugPrint('💾 Temporary report saved for sharing: $tempPath');

      // Share the file
      await Share.shareXFiles(
        [XFile(tempPath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        text: 'Daily Usage Report - ${DateFormat('dd/MM/yyyy').format(_selectedStartDate!)}${_selectedEndDate != null ? ' to ${DateFormat('dd/MM/yyyy').format(_selectedEndDate!)}' : ''}',
        subject: 'Daily Inventory Usage Report',
      );

      // Clean up temp file after a delay
      Future.delayed(const Duration(seconds: 30), () {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
          debugPrint('🗑️ Temporary file deleted: $tempPath');
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Report ready for sharing"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      debugPrint('❌ Share report failed: $e');
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

  // Download report file to device
  Future<void> _downloadReportFile() async {
    try {
      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      // Check if dates are selected
      if (_selectedStartDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a date")),
        );
        return;
      }

      // Check permissions
      if (!await _requestPermissions()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Storage permission is required to save the file"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Generate report data
      final reportData = await _generateReportData();
      if (reportData == null) return;

      // Convert to bytes
      final bytes = reportData;

      if (Platform.isAndroid || Platform.isIOS) {
        await _saveMobileReport(bytes);
      } else {
        await _saveDesktopReport(bytes);
      }

    } catch (e) {
      debugPrint('❌ Download report failed: $e');
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
      final fileName = "daily_usage_${DateFormat('yyyyMMdd').format(_selectedStartDate!)}${_selectedEndDate != null ? '_to_${DateFormat('yyyyMMdd').format(_selectedEndDate!)}' : ''}.xlsx";

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
                            [XFile(outputPath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
                            text: 'Daily Usage Report - ${DateFormat('dd/MM/yyyy').format(_selectedStartDate!)}${_selectedEndDate != null ? ' to ${DateFormat('dd/MM/yyyy').format(_selectedEndDate!)}' : ''}',
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
    final fileName = "daily_usage_${DateFormat('yyyyMMdd').format(_selectedStartDate!)}${_selectedEndDate != null ? '_to_${DateFormat('yyyyMMdd').format(_selectedEndDate!)}' : ''}.xlsx";

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

  // ---------------------- STORAGE PERMISSION ----------------------
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) return true;

      PermissionStatus status;
      status = await Permission.manageExternalStorage.request();

      if (status.isGranted) return true;

      if (status.isPermanentlyDenied) {
        _showPermissionDialog();
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
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
            "Storage permission is required to save files. Please allow it in settings."),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Open Settings"),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(selectedSiteIdProvider);
    if (siteId == null) {
      return const Scaffold(
        body: Center(child: Text("No site selected")),
      );
    }

    final dailyUsageAsync = ref.watch(dailyUsageProvider((siteId: siteId, date: _selectedStartDate)));

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
                  onPressed: _showShareOrDownloadDialog, // Updated to show dialog
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                                        ? DateFormat('dd/MM/yyyy').format(_selectedStartDate!)
                                        : "Start Date",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedStartDate != null ? Colors.black : Colors.grey,
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                                        ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!)
                                        : "End Date",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _selectedEndDate != null ? Colors.black : Colors.grey,
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
                  child: dailyUsageAsync.when(
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
                          return Card(
                            elevation: 0,
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(usage.displayItemName),
                              trailing: IconButton(
                                  onPressed: () {
                                    if (usage.inventory != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditInventoryScreen(
                                              inventory: usage.inventory!),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.edit_outlined)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Category: ${usage.displayCategoryName} | Subcategory: ${usage.displaySubcategoryName}"),
                                  Text(
                                      "Quantity Used: ${usage.quantityUsed} ${usage.inventory?.uom ?? ''}"),
                                  Text("Used By: ${usage.usedByName ?? 'Unknown'}"),
                                  Text(
                                      "Date: ${DateFormat('dd/MM/yyyy').format(usage.usageDate)}"),
                                ],
                              ),
                              onTap: () {
                                if (usage.inventory != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditInventoryScreen(
                                          inventory: usage.inventory!),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                    const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Error: $e")),
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