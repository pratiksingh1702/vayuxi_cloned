// screens/expense/expense_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
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
  DateTime? startDate;
  DateTime? endDate;

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
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        expenseList = response
            .map<ExpenseModel>((item) => ExpenseModel.fromJson(item))
            .toList();
      });
    } catch (e) {
      debugPrint("Error fetching expenses: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load expenses")));
    } finally {
      setState(() => isLoading = false);
    }
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

  void _showViewOptionsModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ViewOptionsModal(
        onOptionSelected: (option) {
          Navigator.pop(context);
          _handleViewOption(option);
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
          expenseType: expense.expenseType,
          expenseId: expense.id,
          expense: expense,
        ),
      ),
    ).then((_) {
      // Refresh the list when returning from form
      _fetchExpenses();
    });
  }

  void _handleViewOption(String option) {
    switch (option) {
      case 'add':
        _showCategoryModal();
        break;
      case 'csv':
        _generateCSV();
        break;
      case 'filter':
        _showDateFilter();
        break;
    }
  }

  Future<void> _generateCSV() async {
    try {
      final type = ref.read(typeProvider);

      print('🔄 Generating CSV for type: $type');

      // Use the exact same date formatting as React Native
      String formatDate(DateTime dt) {
        final isoString = dt.toIso8601String();
        return isoString.split("T")[0]; // Extract YYYY-MM-DD part only
      }

      final now = DateTime.now();
      final thirtyDaysAgo = DateTime(now.year, now.month, now.day - 30);

      // Debug prints to verify dates
      print('   Raw Start Date: $thirtyDaysAgo');
      print('   Raw End Date: $now');
      print('   Formatted Start Date: ${formatDate(thirtyDaysAgo)}');
      print('   Formatted End Date: ${formatDate(now)}');

      final response = await ExpenseAPI.generateExpenseCSV(
        serviceType: type!,
        type: type,
        siteId: widget.siteId,
        startDate: formatDate(thirtyDaysAgo),
        endDate: formatDate(now),
      );

      if (response.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("CSV generated successfully")),
        );
        _handleCSVDownload(response);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No data found for the selected dates")),
        );
      }
    } catch (e) {
      print('❌ CSV generation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate CSV: ${e.toString()}")),
      );
    }
  }

  // Optional: Handle CSV file download
  void _handleCSVDownload(String response) {
    // If the API returns a file URL or CSV data, handle it here
    // You might need to implement file download logic based on your API response
    print('📄 CSV Response: $response');
  }

  void _showDateFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Filter by Date"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Start Date"),
              subtitle: Text(
                startDate != null
                    ? "${startDate!.day}/${startDate!.month}/${startDate!.year}"
                    : "Not set",
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => startDate = date);
                }
              },
            ),
            ListTile(
              title: const Text("End Date"),
              subtitle: Text(
                endDate != null
                    ? "${endDate!.day}/${endDate!.month}/${endDate!.year}"
                    : "Not set",
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => endDate = date);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                startDate = null;
                endDate = null;
              });
              Navigator.pop(context);
              _fetchExpenses();
            },
            child: const Text("Clear"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchExpenses();
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  void _clearDateFilter() {
    setState(() {
      startDate = null;
      endDate = null;
    });
    _fetchExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "Expense List"),
      body: SafeArea(
        child: Column(
          children: [
            // Date Range Filter Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Start Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Start Date", style: TextStyle(fontSize: 16)),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: GestureDetector(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: startDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() => startDate = date);
                                    _fetchExpenses();
                                  }
                                },
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        startDate != null
                                            ? "${startDate!.day}/${startDate!.month}/${startDate!.year}"
                                            : "Start Date",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: startDate != null
                                              ? Colors.black
                                              : Colors.grey,
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
                            Text("End Date", style: TextStyle(fontSize: 16)),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: GestureDetector(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: endDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() => endDate = date);
                                    _fetchExpenses();
                                  }
                                },
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        endDate != null
                                            ? "${endDate!.day}/${endDate!.month}/${endDate!.year}"
                                            : "End Date",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: endDate != null
                                              ? Colors.black
                                              : Colors.grey,
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
                  if (startDate != null || endDate != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _clearDateFilter,
                          child: const Text(
                            "Clear Filter",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Expense List
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

            // Buttons
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  if (expenseList.isNotEmpty) ...[

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
                            text: "View Options",
                            color: Colors.blue,
                            textColor: Colors.white,
                            onPressed: () => _showViewOptionsModal(),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: _showCategoryModal,
                      child: const Text("Add Expense"),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Back"),
                    ),
                  ],
                ],
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

  const _ExpenseCard({required this.expense, required this.onEdit});

  @override
  Widget build(BuildContext context) {
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
                    expense.description.isNotEmpty
                        ? expense.description
                        : "Not available",
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
                        expense.expenseType.isNotEmpty
                            ? expense.expenseType
                            : "Not available",
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
                  "₹${expense.rateInRs.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
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

class _ViewOptionsModal extends StatelessWidget {
  final Function(String) onOptionSelected;

  const _ViewOptionsModal({required this.onOptionSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "View Options",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("Add Expense"),
            onTap: () => onOptionSelected('add'),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text("Generate CSV"),
            onTap: () => onOptionSelected('csv'),
          ),
          ListTile(
            leading: const Icon(Icons.filter_alt),
            title: const Text("Filter by Date"),
            onTap: () => onOptionSelected('filter'),
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
}
