// screens/expense/expense_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../model/expense_model.dart';
import '../service/expense_service.dart';
import 'genericFormScreen.dart';
 // Import the new screen

class ExpenseListScreen extends ConsumerStatefulWidget {
  final String siteId;

  const ExpenseListScreen({super.key, required this.siteId});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  List<ExpenseModel> expenseList = [];
  bool isLoading = false;

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
      _fetchExpenses();
    });
  }

  void _navigateToExportScreen() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ExpenseExportScreen(siteId: widget.siteId),
    //   ),
    // );
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
        body: CornerClippedScreenSimple(
          child: BottomButtonWrapper(
            child: SafeArea(
              child: Column(
                children: [
                 
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
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _showCategoryModal,
                            child: const Text("Add your first expense"),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Keep the existing _ExpenseCard and _CategoryModal classes as they are
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
        ? "No description"
        : expense.description!;

    final category =
    (expense.expenseType == null || expense.expenseType!.isEmpty)
        ? "Unknown"
        : expense.expenseType!;

    final amountText = expense.amount == null
        ? "N/A"
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