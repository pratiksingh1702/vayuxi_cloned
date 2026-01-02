// screens/expense/expense_report_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/date_picker.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/select_card.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../model/expense_model.dart';
import '../service/expense_service.dart';

class ExpenseReportScreen extends ConsumerStatefulWidget {
  final String siteId;

  const ExpenseReportScreen({
    super.key,
    required this.siteId,
  });

  @override
  ConsumerState<ExpenseReportScreen> createState() => _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends ConsumerState<ExpenseReportScreen> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String selectedExpenseType='';
  bool isLoading = false;
  bool isDownloading = false;

  final List<Map<String, dynamic>> expenseTypes = [
    {'value': '', 'label': 'All Expenses', 'icon': Icons.receipt_long},
    {'value': 'material_tools', 'label': 'Material & Tools', 'icon': Icons.build},
    {'value': 'travelling', 'label': 'Travelling', 'icon': Icons.directions_car},
    {'value': 'food', 'label': 'Food', 'icon': Icons.restaurant},
    {'value': 'accommodation', 'label': 'Accommodation', 'icon': Icons.hotel},
    {'value': 'advance', 'label': 'Advance', 'icon': Icons.attach_money},
  ];

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    final now = DateTime.now();
    _selectedEndDate = DateTime(now.year, now.month, now.day);
    _selectedStartDate = DateTime(now.year, now.month, now.day - 30);
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

  String _formatCategoryName(String category) {
    if (category == 'All') return 'All Expenses';
    return category.replaceAll('_', ' ').toUpperCase();
  }

  void _showExpenseTypeSelectionDialog(String expenseType, String label, IconData icon) {
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

    setState(() {
      selectedExpenseType = expenseType;
    });

    _showShareOrDownloadDialog(label);
  }

  void _showShareOrDownloadDialog(String typeName) {
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
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Title
              Text(
                "$typeName Report",
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
                "What would you like to do?",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // Actions
              _ActionTile(
                icon: Icons.share_rounded,
                color: Colors.blue,
                title: "Share",
                subtitle: "Send CSV file via apps",
                onTap: () {
                  Navigator.pop(context);
                  _downloadAndShareCSV();
                },
              ),

              const SizedBox(height: 12),

              _ActionTile(
                icon: Icons.download_rounded,
                color: Colors.green,
                title: "Download",
                subtitle: "Save CSV to your device",
                onTap: () {
                  Navigator.pop(context);
                  _downloadCSVFile();
                },
              ),

              const SizedBox(height: 16),

              // Cancel
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

  Future<void> _downloadAndShareCSV() async {
    try {
      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      final csvData = await _generateCSVData();
      if (csvData.isEmpty) return;

      final bytes = Uint8List.fromList(csvData.codeUnits);
      final tempDir = await getTemporaryDirectory();
      final fileName = 'expense_report_${DateFormat('yyyyMMdd').format(_selectedStartDate!)}_${DateFormat('yyyyMMdd').format(_selectedEndDate!)}.csv';
      final tempPath = '${tempDir.path}/$fileName';
      final tempFile = File(tempPath);

      await tempFile.writeAsBytes(bytes, flush: true);
      debugPrint('💾 Temporary CSV saved for sharing: $tempPath');

      await Share.shareXFiles(
        [XFile(tempPath, mimeType: 'text/csv')],
        text: 'Here is your Expense Report for period ${DateFormat('dd/MM/yyyy').format(_selectedStartDate!)} to ${DateFormat('dd/MM/yyyy').format(_selectedEndDate!)}',
        subject: 'Expense Report - ${DateFormat('dd/MM/yyyy').format(_selectedStartDate!)} to ${DateFormat('dd/MM/yyyy').format(_selectedEndDate!)}',
      );

      Future.delayed(const Duration(seconds: 30), () {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
          debugPrint('🗑️ Temporary file deleted: $tempPath');
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("CSV file ready for sharing"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Share CSV failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to share: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isDownloading = false;
        });
      }
    }
  }

  Future<void> _downloadCSVFile() async {
    try {
      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      final csvData = await _generateCSVData();
      if (csvData.isEmpty) return;

      final bytes = Uint8List.fromList(csvData.codeUnits);

      if (Platform.isAndroid || Platform.isIOS) {
        await _saveMobileCSV(bytes);
      } else {
        await _saveDesktopCSV(bytes);
      }
    } catch (e) {
      debugPrint('❌ Download CSV failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Download failed: Data not available for selected period !!!"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isDownloading = false;
        });
      }
    }
  }

  String _formatDateForAPI(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<String> _generateCSVData() async {
    try {
      if (_selectedStartDate == null || _selectedEndDate == null) {
        throw Exception('Date range not selected');
      }

      debugPrint('🔄 Generating CSV');
      debugPrint('   Type: $selectedExpenseType');
      debugPrint('   Start Date: ${_formatDateForAPI(_selectedStartDate!)}');
      debugPrint('   End Date: ${_formatDateForAPI(_selectedEndDate!)}');

      final type = ref.read(typeProvider);

      final response = await ExpenseAPI.generateExpenseCSV(
        serviceType: type!,
        type: selectedExpenseType.isEmpty ? "" : selectedExpenseType,

        siteId: widget.siteId,
        startDate: _formatDateForAPI(_selectedStartDate!),
        endDate: _formatDateForAPI(_selectedEndDate!),
      );

      if (response.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No data found for the selected criteria"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return '';
      }

      return response;
    } catch (e) {
      debugPrint('❌ CSV generation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to generate CSV, might be an internal error"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
      return '';
    }
  }
  Future<void> downloadAllExpensesCSV() async {
    try {
      // Hard validation
      if (_selectedStartDate == null || _selectedEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select start and end dates first"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      final type = ref.read(typeProvider);
      if (type == null) {
        throw Exception("Service type not found");
      }

      // FORCE all expenses
      final response = await ExpenseAPI.generateExpenseCSV(
        serviceType: type,
        type: "", // 🔥 IMPORTANT: ALL EXPENSES ONLY
        siteId: widget.siteId,
        startDate: _formatDateForAPI(_selectedStartDate!),
        endDate: _formatDateForAPI(_selectedEndDate!),
      );

      if (response.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No expense data found for selected period"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final bytes = Uint8List.fromList(response.codeUnits);

      if (Platform.isAndroid || Platform.isIOS) {
        await _saveMobileCSV(bytes);
      } else {
        await _saveDesktopCSV(bytes);
      }

    } catch (e) {
      debugPrint('❌ All expenses download failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to download all expenses CSV"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isDownloading = false;
        });
      }
    }
  }


  Future<void> _saveMobileCSV(Uint8List bytes) async {
    try {
      final fileName = 'expense_report_${DateFormat('yyyyMMdd').format(_selectedStartDate!)}_${DateFormat('yyyyMMdd').format(_selectedEndDate!)}.csv';

      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV File',
        fileName: fileName,
        bytes: bytes,
      );

      if (outputPath != null) {
        debugPrint('💾 CSV saved to: $outputPath');

        final result = await OpenFile.open(outputPath);
        debugPrint('📂 Open file result: ${result.type} - ${result.message}');

        if (mounted) {
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
                            await Share.shareXFiles(
                              [XFile(outputPath, mimeType: 'text/csv')],
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
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Save operation canceled.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Mobile CSV save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save file: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _saveDesktopCSV(Uint8List bytes) async {
    final fileName = 'expense_report_${DateFormat('yyyyMMdd').format(_selectedStartDate!)}_${DateFormat('yyyyMMdd').format(_selectedEndDate!)}.csv';

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save CSV File',
      fileName: fileName,
    );

    if (path == null) return;

    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    if (mounted) {
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
  }

  Widget _expenseTypeCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return SelectCard(
      icon: Icon(icon),
      label: label,
      onTap: () => _showExpenseTypeSelectionDialog(value, label, icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "Generate Expense Report"),
      body: BottomButtonWrapper(
        customButtons: [
           CustomButton(
            button: RoundedButton(
              text: "Save All",
              color: Colors.blue,
              textColor: Colors.white,
              onPressed: () {
                _showShareOrDownloadDialog("");

              },
            ),
          ),
        ],
        child: Stack(
          children: [
            Column(
              children: [
                // Date Range Section
                Container(
                  margin: const EdgeInsets.all(12),
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
        
                // Grid of expense type cards
                Expanded(
                  child: GridView.count(
                    physics: const BouncingScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 1,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: expenseTypes.map((type) {
                      return _expenseTypeCard(
                        value: type['value'],
                        label: type['label'],
                        icon: type['icon'],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        
            // Loading Overlay
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