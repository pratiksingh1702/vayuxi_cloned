// screens/expense/expense_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';

import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../Manpower Details/model/manpower_model.dart';
import '../../Manpower Details/service/manPowerProvider.dart';
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

  // Common controllers
  final _descriptionController = TextEditingController();
  final _remarksController = TextEditingController();
  final _amountController = TextEditingController();

  // Material & Tools specific
  final _invoiceNumberController = TextEditingController();
  final _hardwareShopController = TextEditingController();
  final _quantityController = TextEditingController(text: "1");
  final _monthController = TextEditingController();

  // Travel specific
  final _placeController = TextEditingController();

  // Advance specific
  ManpowerModel? _selectedManpower;

  DateTime? _selectedDate;
  bool _isLoading = false;
  bool get _isEditing => widget.expenseId != null;

  // Month options for dropdown
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    // Set current date
    _selectedDate = DateTime.now();
    _loadExpenseData();
    // Fetch manpower for advance dropdown
    if (widget.expenseType == 'advance') {
      _fetchManpower();
    }
  }

  void _loadExpenseData() {
    if (_isEditing && widget.expense != null) {
      final expense = widget.expense!;
      _descriptionController.text = expense.description ?? '';
      _remarksController.text = expense.remarks ?? '';
      _selectedDate = expense.date;

      // Load amount if exists
      if (expense.amount != null) {
        _amountController.text = expense.amount!.toString();
      }

      // Load type-specific fields
      if (expense.invoiceNumber != null) {
        _invoiceNumberController.text = expense.invoiceNumber!;
      }
      if (expense.hardwareShopName != null) {
        _hardwareShopController.text = expense.hardwareShopName!;
      }
      if (expense.quantity != null) {
        _quantityController.text = expense.quantity!.toString();
      }
      if (expense.month != null) {
        _monthController.text = expense.month!;
      }
      if (expense.place != null) {
        _placeController.text = expense.place!;
      }
      // Note: For manpower, we would need to fetch and match from API
    }
  }

  Future<void> _fetchManpower() async {
    try {
      final type = ref.read(typeProvider);
      if (type != null) {
        await ref.read(manpowerProvider.notifier).fetchManpower(type);
      }
    } catch (e) {
      print('Error fetching manpower: $e');
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
      'Miscllaneous': 'Miscellaneous',
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

  Map<String, dynamic> _buildExpenseData() {
    // Base data for all types
    final baseData = {
      'expenseType': widget.expenseType,
      'description': _descriptionController.text.trim(),
      'date': _selectedDate!.toIso8601String(),
      'remarks': _remarksController.text.trim(),
    };

    // Add type-specific fields
    switch (widget.expenseType) {
      case 'material_tools':
        return {
          ...baseData,
          'invoiceNumber': _invoiceNumberController.text.trim(),
          'hardwareShop': _hardwareShopController.text.trim(),
          'quantity': _quantityController.text.isNotEmpty ? int.parse(_quantityController.text) : 1,
          'month': _monthController.text.trim(),
          'year': DateTime.now().year,
        };

      case 'travelling':
        return {
          ...baseData,
          'place': _placeController.text.trim(),
          'amount': _amountController.text.isNotEmpty ? double.parse(_amountController.text) : 0.0,
        };

      case 'food':
      case 'accommodation':
      case 'advance':
      case 'Miscllaneous':
        final data = {
          ...baseData,
          'amount': _amountController.text.isNotEmpty ? double.parse(_amountController.text) : 0.0,
        };

        // Add manpower ID for advance if selected
        if (widget.expenseType == 'advance' && _selectedManpower != null) {
          data['manpowerId'] = _selectedManpower!.id as Object;
        }

        return data;

      default:
        return baseData;
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

    // Validate amount for types that require it
    if (widget.expenseType != 'material_tools' && _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter amount")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final type = ref.read(typeProvider);
      final expenseData = _buildExpenseData();

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

  Widget _buildFormFields() {
    switch (widget.expenseType) {
      case 'material_tools':
        return _buildMaterialToolsFields();
      case 'travelling':
        return _buildTravelFields();
      case 'food':
        return _buildFoodFields();
      case 'accommodation':
        return _buildAccommodationFields();
      case 'advance':
        return _buildAdvanceFields();
      case 'Miscllaneous':
        return _buildMiscellaneousFields();
      default:
        return _buildCommonFields();
    }
  }

  Widget _buildMaterialToolsFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: "Description",
          isRequired: true,
          maxLines: 3,
          controller: _descriptionController,
          hint: "Enter expense description",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Invoice Number",
          controller: _invoiceNumberController,
          hint: "Enter invoice number",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Hardware Shop",
          controller: _hardwareShopController,
          hint: "Enter hardware shop name",
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quantity*",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          onPressed: () {
                            int current = int.tryParse(_quantityController.text) ?? 1;
                            if (current > 1) {
                              setState(() {
                                _quantityController.text = (current - 1).toString();
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "1",
                              counterText: "",
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                int val = int.tryParse(value) ?? 1;
                                if (val < 1) {
                                  _quantityController.text = "1";
                                }
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () {
                            int current = int.tryParse(_quantityController.text) ?? 1;
                            setState(() {
                              _quantityController.text = (current + 1).toString();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Month*",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _monthController.text.isNotEmpty ? _monthController.text : null,
                        isExpanded: true,
                        hint: const Text("Select Month"),
                        items: _months.map((String month) {
                          return DropdownMenuItem<String>(
                            value: month,
                            child: Text(month),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _monthController.text = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Remarks",
          maxLines: 3,
          controller: _remarksController,
          hint: "Enter any additional remarks",
        ),
      ],
    );
  }

  Widget _buildTravelFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: "Description",
          isRequired: true,
          maxLines: 3,
          controller: _descriptionController,
          hint: "Enter travel description",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Place",
          isRequired: true,
          controller: _placeController,
          hint: "Enter destination",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Amount (Rs.)",
          isRequired: true,
          controller: _amountController,
          hint: "0.00",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Remarks",
          maxLines: 3,
          controller: _remarksController,
          hint: "Enter any additional remarks",
        ),
      ],
    );
  }

  Widget _buildFoodFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: "Description",
          isRequired: true,
          maxLines: 3,
          controller: _descriptionController,
          hint: "Enter food expense description",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Amount (Rs.)",
          isRequired: true,
          controller: _amountController,
          hint: "0.00",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Remarks",
          maxLines: 3,
          controller: _remarksController,
          hint: "Enter any additional remarks",
        ),
      ],
    );
  }

  Widget _buildAccommodationFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: "Description",
          isRequired: true,
          maxLines: 3,
          controller: _descriptionController,
          hint: "Enter accommodation details",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Amount (Rs.)",
          isRequired: true,
          controller: _amountController,
          hint: "0.00",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Remarks",
          maxLines: 3,
          controller: _remarksController,
          hint: "Enter any additional remarks",
        ),
      ],
    );
  }

  Widget _buildAdvanceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Manpower Selection Dropdown
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Employee*",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final manpowerState = ref.watch(manpowerProvider);

                  if (manpowerState.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return DropdownButtonHideUnderline(
                    child: DropdownButton<ManpowerModel>(
                      value: _selectedManpower,
                      isExpanded: true,
                      hint: const Text("Select Employee"),
                      items: manpowerState.manpowerList.map((ManpowerModel manpower) {
                        return DropdownMenuItem<ManpowerModel>(
                          value: manpower,
                          child: Text(
                            "${manpower.fullName ?? 'Unknown'} - ${manpower.employeeCode ?? 'No Code'}",
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (ManpowerModel? newValue) {
                        setState(() {
                          _selectedManpower = newValue;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Description",
          isRequired: true,
          maxLines: 3,
          controller: _descriptionController,
          hint: "Enter advance description",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Amount (Rs.)",
          isRequired: true,
          controller: _amountController,
          hint: "0.00",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Remarks",
          maxLines: 3,
          controller: _remarksController,
          hint: "Enter any additional remarks",
        ),
      ],
    );
  }

  Widget _buildMiscellaneousFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: "Description",
          isRequired: true,
          maxLines: 3,
          controller: _descriptionController,
          hint: "Enter expense description",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Amount (Rs.)",
          isRequired: true,
          controller: _amountController,
          hint: "0.00",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Remarks",
          maxLines: 3,
          controller: _remarksController,
          hint: "Enter any additional remarks",
        ),
      ],
    );
  }

  Widget _buildCommonFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: "Description",
          isRequired: true,
          maxLines: 3,
          controller: _descriptionController,
          hint: "Enter description",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Remarks",
          maxLines: 3,
          controller: _remarksController,
          hint: "Enter any additional remarks",
        ),
      ],
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _remarksController.dispose();
    _amountController.dispose();
    _invoiceNumberController.dispose();
    _hardwareShopController.dispose();
    _quantityController.dispose();
    _monthController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: _getScreenTitle()),
      backgroundColor: AppColors.lightBlue,
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
            button: RoundedButton(
              text: "Save",
              color: Colors.blue,
              textColor: Colors.white,
              onPressed: _isLoading ? (){} : _submitForm,
              isOutlined: false,
              width: null,
            ),
          ),
          if (_isEditing)
            CustomButton(
              button: RoundedButton(
                text: "Remove",
                color: Colors.red,
                textColor: Colors.red,
                onPressed: _isLoading ? (){} : _deleteExpense,
                isOutlined: true,
                width: null,
              ),
            ),
        ],
        showBackButton: true,
        onBackPressed: _isLoading ? null : () => Navigator.pop(context),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Field (Common for all types)
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

                  // Dynamic Form Fields
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildFormFields(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// expense_model.dart - Update with new fields
