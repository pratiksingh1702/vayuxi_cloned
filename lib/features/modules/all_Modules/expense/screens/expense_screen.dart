// screens/expense/expense_list_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../../../../../core/utlis/widgets/image_clipped.dart';
import '../model/expense_model.dart';
import '../service/expense_service.dart';
import 'genericFormScreen.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  final String siteId;

  const ExpenseListScreen({super.key, required this.siteId});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  List<ExpenseModel> expenseList = [];
  bool isLoading = false;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() => isLoading = true);
    try {
      final type = ref.read(typeProvider);
      final response = await ExpenseAPI.fetchExpenses(
        type: type!,
        siteId: widget.siteId,
      );

      setState(() {
        expenseList = response
            .map<ExpenseModel>((item) => ExpenseModel.fromJson(item))
            .toList();
      });
    } catch (e) {
      debugPrint("Error fetching expenses: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load expenses")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Share/Download Dialog for CSV
  void _showShareOrDownloadDialog() {
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
              const Text(
                "Expense Report",
                style: TextStyle(
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
  Future<void> _downloadAndShareCSV() async {
    try {
      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      // First generate CSV data
      final csvData = await _generateCSVData();
      if (csvData.isEmpty) return;

      // Convert CSV string to bytes
      final bytes = Uint8List.fromList(csvData.codeUnits);

      // Save to temporary directory for sharing
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'expense_report_$timestamp.csv';
      final tempPath = '${tempDir.path}/$fileName';
      final tempFile = File(tempPath);

      await tempFile.writeAsBytes(bytes, flush: true);
      debugPrint('💾 Temporary CSV saved for sharing: $tempPath');

      // Share the file
      await Share.shareXFiles(
        [XFile(tempPath, mimeType: 'text/csv')],
        text: 'Expense Report - ${widget.siteId}',
        subject: 'Expense Report CSV',
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
          content: Text("CSV file ready for sharing"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      debugPrint('❌ Share CSV failed: $e');
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

  // Download CSV file to device
  Future<void> _downloadCSVFile() async {
    try {
      setState(() {
        isLoading = true;
        isDownloading = true;
      });

      // Generate CSV data
      final csvData = await _generateCSVData();
      if (csvData.isEmpty) return;

      // Convert to bytes
      final bytes = Uint8List.fromList(csvData.codeUnits);

      if (Platform.isAndroid || Platform.isIOS) {
        await _saveMobileCSV(bytes);
      } else {
        await _saveDesktopCSV(bytes);
      }

    } catch (e) {
      debugPrint('❌ Download CSV failed: $e');
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

  // Generate CSV data (internal method)
  Future<String> _generateCSVData() async {
    try {
      final type = ref.read(typeProvider);
      debugPrint('🔄 Generating CSV for type: $type');

      // Date formatting function
      String formatDate(DateTime dt) {
        final isoString = dt.toIso8601String();
        return isoString.split("T")[0];
      }

      final now = DateTime.now();
      final thirtyDaysAgo = DateTime(now.year, now.month, now.day - 30);

      debugPrint('   Start Date: ${formatDate(thirtyDaysAgo)}');
      debugPrint('   End Date: ${formatDate(now)}');

      final response = await ExpenseAPI.generateExpenseCSV(
        serviceType: type!,
        type: type,
        siteId: widget.siteId,
        startDate: formatDate(thirtyDaysAgo),
        endDate: formatDate(now),
      );

      if (response.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No data found for the selected dates"),
            backgroundColor: Colors.orange,
          ),
        );
        return '';
      }

      return response;
    } catch (e) {
      debugPrint('❌ CSV generation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Sorry, Failed to generate CSV, might be a internal error"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return '';
    }
  }

  // Save CSV on mobile devices
  Future<void> _saveMobileCSV(Uint8List bytes) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultFileName = 'expense_report_$timestamp.csv';

      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV File',
        fileName: defaultFileName,
        bytes: bytes,
      );

      if (outputPath != null) {
        debugPrint('💾 CSV saved to: $outputPath');

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
                const Text('✅ CSV file saved successfully!'),
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
                            text: 'Expense Report CSV',
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
      debugPrint('❌ Mobile CSV save error: $e');
      rethrow;
    }
  }

  // Save CSV on desktop
  Future<void> _saveDesktopCSV(Uint8List bytes) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'expense_report_$timestamp.csv';

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save CSV File',
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
            Text('✅ CSV saved: $path'),
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

  void _showCategoryModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _CategoryModal(
        onCategorySelected: (category) {
          Navigator.pop(context);
          _navigateToAddExpense(category);
        },
      ),
    );
  }

  void _navigateToAddExpense(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExpenseFormScreen(siteId: widget.siteId, expenseType: category),
      ),
    ).then((_) {
      // Refresh the list when returning from form
      _fetchExpenses();
    });
  }

  void _navigateToEditExpense(ExpenseModel expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseFormScreen(
          siteId: widget.siteId,
          expenseType: expense.expenseType!,
          expenseId: expense.id,
          expense: expense,
        ),
      ),
    ).then((_) {
      // Refresh the list when returning from form
      _fetchExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(title: "Expense List"),
          ];
        },
        body: Stack(
          children: [
            CornerClippedScreenSimple(
              child: SafeArea(
                child: Column(
                  children: [
                    // Top buttons: Edit and Generate CSV


                    // Expense List with loader only for the list area
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : expenseList.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 100,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No expenses found",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: expenseList.length,
                        itemBuilder: (context, index) {
                          final expense = expenseList[index];
                          return _ExpenseCard(
                            expense: expense,
                            onEdit: () => _navigateToEditExpense(expense),
                          );
                        },
                      ),
                    ),

                    // Bottom buttons: Back and Add Expense
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: RoundedButton(
                                  text: "Back",
                                  color: Colors.white,
                                  textColor: Colors.black,
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RoundedButton(
                                  text: "Sheet",
                                  color: Colors.blue,
                                  textColor: Colors.white,
                                  onPressed: _showShareOrDownloadDialog,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Loading overlay for CSV download
            if (isDownloading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        isDownloading ? 'Downloading CSV...' : 'Loading...',
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

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onEdit;

  const _ExpenseCard({
    required this.expense,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final description =
    (expense.description == null || expense.description!.isEmpty)
        ? "null"
        : expense.description!;

    final category =
    (expense.expenseType == null || expense.expenseType!.isEmpty)
        ? "null"
        : expense.expenseType!;

    final amountText = expense.amount == null
        ? "null"
        : "₹${expense.amount!.toStringAsFixed(2)}";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        "Category:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        category,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Trailing info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: expense.amount == null
                        ? Colors.grey
                        : Colors.green,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: onEdit,
                  tooltip: "Edit",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryModal extends StatelessWidget {
  final Function(String) onCategorySelected;

  const _CategoryModal({required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    final categories = [
      'material_tools',
      'travelling',
      'food',
      'accommodation',
      'advance',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Select Expense Category",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...categories.map(
                (category) => ListTile(
              title: Text(_formatCategoryName(category)),
              onTap: () => onCategorySelected(category),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  String _formatCategoryName(String category) {
    return category.replaceAll('_', ' ').toUpperCase();
  }
}