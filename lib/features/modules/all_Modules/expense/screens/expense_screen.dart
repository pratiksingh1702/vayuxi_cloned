import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
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

  // Selection mode state
  bool _isSelectionMode = false;
  Set<String> _selectedExpenseIds = {};

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

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedExpenseIds.clear();
      }
    });
  }

  /// Toggle individual expense selection
  void _toggleExpenseSelection(String expenseId) {
    setState(() {
      if (_selectedExpenseIds.contains(expenseId)) {
        _selectedExpenseIds.remove(expenseId);
      } else {
        _selectedExpenseIds.add(expenseId);
      }
    });
  }

  /// Select all expenses
  void _selectAllExpenses() {
    setState(() {
      for (var expense in expenseList) {
        if (expense.id != null) {
          _selectedExpenseIds.add(expense.id!);
        }
      }
    });
  }

  /// Delete selected expenses
  Future<void> _deleteSelectedExpenses() async {
    if (_selectedExpenseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No expenses selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Expenses'),
        content: Text(
          'Are you sure you want to delete ${_selectedExpenseIds.length} selected expenses?\n\n'
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ExpenseAPI.bulkDeleteExpenses(
        expenseIds: _selectedExpenseIds.toList(),
      );

      // Refresh expenses list
      await _fetchExpenses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully deleted ${_selectedExpenseIds.length} expenses',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _selectedExpenseIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to bulk delete: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk delete failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _deleteSingleExpense(String expenseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Expense"),
        content: const Text(
          "Are you sure you want to delete this expense?\n\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ExpenseAPI.deleteExpense(
        siteId: widget.siteId,
        expenseId: expenseId,
      );

      await _fetchExpenses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Expense deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Delete expense failed: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to delete expense"),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      drawer: const CustomDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(
              title: _isSelectionMode
                  ? '${_selectedExpenseIds.length} Selected'
                  : "Expense List",
            ),
          ];
        },
        body: BottomButtonWrapper(
          child: SafeArea(
            child: Column(
              children: [
                // Top action bar with selection controls
                if (expenseList.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [

                      Row(
                        children: [
                          if (_isSelectionMode) ...[
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _toggleSelectionMode,
                              tooltip: 'Cancel',
                            ),
                            TextButton(
                              onPressed: _selectAllExpenses,
                              child: const Text('Select All'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.delete_sweep,
                                size: 18,
                              ),
                              label: const Text('Delete'),
                              onPressed: _selectedExpenseIds.isEmpty
                                  ? null
                                  : _deleteSelectedExpenses,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ] else ...[
                            IconButton(
                              icon: const Icon(
                                Icons.delete_sweep,
                                color: Colors.red,
                              ),
                              onPressed: expenseList.isEmpty
                                  ? null
                                  : _toggleSelectionMode,
                              tooltip: 'Select Expenses to Delete',
                            ),
                          ],
                        ],
                      ),
                    ],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                    ),
                    itemCount: expenseList.length,
                    itemBuilder: (context, index) {
                      final expense = expenseList[index];
                      final isSelected = _selectedExpenseIds.contains(
                        expense.id,
                      );

                      return _buildExpenseCard(
                        expense,
                        isSelected,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense, bool isSelected) {
    debugPrint(expense.toString());
    final description =
    (expense.description == null || expense.description!.isEmpty)
        ? "No description"
        : expense.description!;

    final category =
    (expense.expenseType == null || expense.expenseType!.isEmpty)
        ? "Unknown"
        : expense.expenseType!;

    final amountText = () {
      if (expense.expenseType == "material_tools") {
        return expense.invoiceValue != null
            ? "₹${expense.invoiceValue!.toStringAsFixed(2)}"
            : "N/A";
      }

      if (expense.amount != null) {
        return "₹${expense.amount!.toStringAsFixed(2)}";
      }

      if (expense.rate != null) {
        return "₹${expense.rate!.toStringAsFixed(2)}";
      }

      return "N/A";
    }();
    return Stack(
      children: [
        Opacity(
          opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            color: Colors.white,
            child: InkWell(
              onTap: _isSelectionMode
                  ? () => _toggleExpenseSelection(expense.id!)
                  : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                    if (!_isSelectionMode)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            amountText,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: amountText.isEmpty
                                  ? Colors.grey
                                  : Colors.green,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _navigateToEditExpense(expense),
                                tooltip: "Edit",
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteSingleExpense(expense.id!),
                                tooltip: "Delete",
                              ),
                            ],
                          ),
                        ],
                      )
                  ],
                ),
              ),
            ),
          ),
        ),

        // Selection checkbox overlay
        if (_isSelectionMode)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _toggleExpenseSelection(expense.id!),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.red : Colors.white,
                  border: Border.all(
                    color: Colors.red,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                )
                    : null,
              ),
            ),
          ),
      ],
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