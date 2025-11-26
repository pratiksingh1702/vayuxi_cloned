// screens/expense/expense_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';

import 'package:untitled2/typeProvider/type_provider.dart';

import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../model/expense_model.dart';
import '../service/expense_service.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String expenseType;
  final String? expenseId;
  final ExpenseModel? expense;

  const ExpenseFormScreen({
    super.key,
    required this.siteId,
    required this.expenseType,
    this.expenseId,
    this.expense,
  });

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _hardwareShopNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _uomController = TextEditingController();
  final _rateInRsController = TextEditingController();
  final _invoiceValueController = TextEditingController();
  final _remarksController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;
  bool get _isEditing => widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    _loadExpenseData();
    // Add listener to calculate invoice value automatically
    _quantityController.addListener(_calculateInvoiceValue);
    _rateInRsController.addListener(_calculateInvoiceValue);
  }

  void _calculateInvoiceValue() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final rate = double.tryParse(_rateInRsController.text) ?? 0;
    final invoiceValue = quantity * rate;

    if (invoiceValue > 0) {
      _invoiceValueController.text = invoiceValue.toStringAsFixed(2);
    } else {
      _invoiceValueController.text = '';
    }
  }

  void _loadExpenseData() {
    if (_isEditing && widget.expense != null) {
      final expense = widget.expense!;
      _descriptionController.text = expense.description;
      _invoiceNumberController.text = expense.invoiceNumber ?? '';
      _hardwareShopNameController.text = expense.hardwareShopName ?? '';
      // _quantityController.text = expense.quantity?.toString() ?? '';
      // _uomController.text = expense.uom ?? '';
      _rateInRsController.text = expense.rateInRs.toString();
      // _invoiceValueController.text = expense.invoiceValue?.toString() ?? '';
      _remarksController.text = expense.remarks;
      _selectedDate = expense.date;
    }
  }

  String _getScreenTitle() {
    final typeName = _getExpenseTypeName(widget.expenseType);
    return _isEditing ? "Edit $typeName Expense" : "$typeName Expense Details";
  }

  String _getExpenseTypeName(String type) {
    final names = {
      'material_tools': 'Material & Tools',
      'travelling': 'Travelling',
      'food': 'Food',
      'accommodation': 'Accommodation',
      'advance': 'Advance',
    };
    return names[type] ?? type;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final type = ref.read(typeProvider);
      final expenseData = {
        'expenseType': widget.expenseType,
        'description': _descriptionController.text.trim(),
        'date': _selectedDate!.toIso8601String(),
        'invoiceNumber': _invoiceNumberController.text.trim(),
        'hardwareShopName': _hardwareShopNameController.text.trim(),
        'quantity': _quantityController.text.isNotEmpty ? double.parse(_quantityController.text) : null,
        'uom': _uomController.text.trim(),
        'rateInRs': double.parse(_rateInRsController.text),
        'invoiceValue': _invoiceValueController.text.isNotEmpty ? double.parse(_invoiceValueController.text) : null,
        'remarks': _remarksController.text.trim(),
      };

      if (_isEditing) {
        await ExpenseAPI.updateExpense(
          data: expenseData,
          siteId: widget.siteId,
          expenseId: widget.expenseId!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense updated successfully")),
        );
      } else {
        await ExpenseAPI.createExpense(
          data: expenseData,
          type: type!,
          siteId: widget.siteId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense created successfully")),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save expense: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this expense?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ExpenseAPI.deleteExpense(
          siteId: widget.siteId,
          expenseId: widget.expenseId!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense deleted successfully")),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete expense: $e")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _invoiceNumberController.dispose();
    _hardwareShopNameController.dispose();
    _quantityController.dispose();
    _uomController.dispose();
    _rateInRsController.dispose();
    _invoiceValueController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Expense Details"),
      backgroundColor: AppColors.lightBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getScreenTitle(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Field
                        const Text(
                          "Select Date*",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedDate != null
                                      ? "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}"
                                      : "Select Date",
                                  style: TextStyle(
                                    color: _selectedDate != null
                                        ? Colors.black
                                        : Colors.grey.shade500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Description Field
                        CustomTextField(
                          label: "Description",
                          isRequired: true,
                          maxLines: 3,
                          controller: _descriptionController,
                          hint: "Enter expense description",
                        ),

                        const SizedBox(height: 16),

                        // Invoice Number Field
                        CustomTextField(
                          label: "Invoice Number",
                          controller: _invoiceNumberController,
                          hint: "Enter invoice number",
                        ),

                        const SizedBox(height: 16),

                        // Hardware Shop Name Field
                        CustomTextField(
                          label: "Hardware Shop Name",
                          controller: _hardwareShopNameController,
                          hint: "Enter shop name",
                        ),

                        const SizedBox(height: 16),

                        // Quantity and UOM Row
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: CustomTextField(
                                label: "Quantity",
                                controller: _quantityController,
                                hint: "0",
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: CustomTextField(
                                label: "UOM",
                                controller: _uomController,
                                hint: "pieces",
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Rate and Invoice Value Row
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: "Rate (Rs.)",
                                isRequired: true,
                                controller: _rateInRsController,
                                hint: "0",
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                label: "Invoice Value (Rs.)",
                                controller: _invoiceValueController,
                                hint: "0",
                                keyboardType: TextInputType.number,
                                TextSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Remarks Field
                        CustomTextField(
                          label: "Remarks",
                          maxLines: 3,
                          controller: _remarksController,
                          hint: "Enter any additional remarks",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Buttons
                Column(
                  children: [
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                            : const Text(
                          "Save & Submit",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Delete and Back Buttons
                    Row(
                      children: [
                        if (_isEditing) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _deleteExpense,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text("Remove"),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text("Back"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}