// screens/expense/expense_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/language/service/providers.dart';
import 'package:untitled2/features/modules/all_Modules/rate/data/rateApi.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../core/utlis/widgets/fields/searchableDropdown.dart';

import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../Manpower Details/model/manpower_model.dart';
import '../../Manpower Details/service/manPowerProvider.dart';
import '../model/expense_model.dart';
import '../service/expense_service.dart';
import 'package:dropdown_search/dropdown_search.dart';

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
  final _rateController = TextEditingController();
  final _balanceController = TextEditingController();
  String? _selectedUOM;

  // Travel specific
  final _placeController = TextEditingController();

  // Advance specific
  ManpowerModel? _selectedManpower;

  DateTime? _selectedDate;
  bool _isLoading = false;
  bool get _isEditing => widget.expenseId != null;

  // UOM list
  List<String> _uomList = [];
  bool _isLoadingUOM = false;

  final ScrollController _scrollController = ScrollController();

  // FocusNodes — used to ensureVisible when keyboard opens over a field
  final _descriptionFocusNode = FocusNode();
  final _remarksFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  final _invoiceNumberFocusNode = FocusNode();
  final _hardwareShopFocusNode = FocusNode();
  final _rateFocusNode = FocusNode();
  final _balanceFocusNode = FocusNode();
  final _placeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    // Auto-scroll to field when keyboard appears and it gets focus
    for (final node in [
      _descriptionFocusNode,
      _remarksFocusNode,
      _amountFocusNode,
      _invoiceNumberFocusNode,
      _hardwareShopFocusNode,
      _rateFocusNode,
      _balanceFocusNode,
      _placeFocusNode,
    ]) {
      node.addListener(() {
        if (node.hasFocus) {
          _ensureVisible(node);
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExpenseData();

      if (widget.expenseType == 'advance') {
        _fetchManpower();
      }

      if (widget.expenseType == 'material_tools') {
        _fetchUOM();
      }
    });
  }

  /// Scrolls the focused field into view after the keyboard has fully animated in.
  void _ensureVisible(FocusNode node) {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (node.context != null) {
        Scrollable.ensureVisible(
          node.context!,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: 0.5, // centre the field vertically in the visible area
        );
      }
    });
  }


  Future<void> _fetchUOM() async {
    setState(() => _isLoadingUOM = true);
    try {
      final uomData = await RateApiClient().getRateUOM();
      setState(() {
        _uomList = uomData.map((item) => item['name'].toString()).toList();
      });
    } catch (e) {
      print('Error fetching UOM: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load UOM options: $e")),
      );
    } finally {
      setState(() => _isLoadingUOM = false);
    }
  }

  void _loadExpenseData() {
    if (_isEditing && widget.expense != null) {
      final expense = widget.expense!;
      _descriptionController.text = expense.description ?? '';
      _remarksController.text = expense.remarks ?? '';
      _selectedDate = expense.date;
      print(expense.hardwareShopName);

      if (expense.amount != null) {
        _amountController.text = expense.amount!.toString();
      }

      if (expense.invoiceNumber != null) {
        _invoiceNumberController.text = expense.invoiceNumber!;
      }
      if (expense.hardwareShopName != null) {
        _hardwareShopController.text = expense.hardwareShopName!;
      }
      if (expense.quantity != null) {
        _quantityController.text = expense.quantity!.toString();
      }
      if (expense.rate != null) {
        _rateController.text = expense.rate!.toString();
      }
      _balanceController.text =
          expense.balance?.toString() ??
              expense.invoiceValue?.toString() ??
              '';
      if (expense.uom != null) {
        _selectedUOM = expense.uom;
      }
      if (expense.place != null) {
        _placeController.text = expense.place!;
      }
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
    final lang = ref.watch(dailyEntryTranslationHelperProvider);
    final names = {
      'material_tools': lang.materialToolsCategory,
      'travelling': lang.travelCategory,
      'food': lang.foodCategory,
      'accommodation': lang.accommodationCategory,
      'advance': lang.advanceCategory,
      'miscellaneous': lang.miscellaneousCategory,
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
    final baseData = {
      'expenseType': widget.expenseType,
      'description': _descriptionController.text.trim(),
      'date': _selectedDate!.toIso8601String(),
      'remarks': _remarksController.text.trim(),
    };

    switch (widget.expenseType) {
      case 'material_tools':
        return {
          ...baseData,
          'invoiceNumber': _invoiceNumberController.text.trim(),
          'hardwareShopName': _hardwareShopController.text.trim(),
          'quantity': _quantityController.text.isNotEmpty ? int.parse(_quantityController.text) : 1,
          'rateInRs': _rateController.text.isNotEmpty ? double.parse(_rateController.text) : 0.0,
          'invoiceValue': _balanceController.text.isNotEmpty ? double.parse(_balanceController.text) : 0.0,
          'uom': _selectedUOM ?? '',
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
      case 'miscellaneous':
        final data = {
          ...baseData,
          'amount': _amountController.text.isNotEmpty ? double.parse(_amountController.text) : 0.0,
        };

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

    if (widget.expenseType != 'material_tools' && _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter amount")),
      );
      return;
    }

    if (widget.expenseType == 'material_tools' && (_selectedUOM == null || _selectedUOM!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select UOM")),
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
        AppToast.success("Expense updated successfully");
      } else {
        await ExpenseAPI.createExpense(
          data: expenseData,
          type: type!,
          siteId: widget.siteId,
        );
       AppToast.success("Expense created successfully");
      }

      Navigator.pop(context);
    } catch (e) {
      AppToast.error("Failed to save expense: $e");
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
      case 'miscellaneous':
        return _buildmiscellaneousFields();
      default:
        return _buildCommonFields();
    }
  }

  Widget _buildMaterialToolsFields() {
    final lang = ref.watch(dailyEntryTranslationHelperProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: "Description",
          maxLines: 3,
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          hint: "Enter expense description",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Invoice Number",
          controller: _invoiceNumberController,
          focusNode: _invoiceNumberFocusNode,
          hint: "Enter invoice number",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: lang.hardwareShopLabel,
          controller: _hardwareShopController,
          focusNode: _hardwareShopFocusNode,
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
                    "UOM*",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isLoadingUOM
                      ? Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(child: Text("Loading...")),
                  )
                      : SearchableDropdown(
                    data: _uomList,
                    value: _selectedUOM,
                    placeholder: "Select UOM",
                    onSelect: (value) {
                      setState(() {
                        _selectedUOM = value;
                      });
                    },
                    containerDecoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Rate (Rs.)",
          controller: _rateController,
          focusNode: _rateFocusNode,
          hint: "0.00",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Invoice Balance (Rs.)",
          isRequired: true,
          controller: _balanceController,
          focusNode: _balanceFocusNode,
          hint: "0.00",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Remarks",
          maxLines: 3,
          controller: _remarksController,
          focusNode: _remarksFocusNode,
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
          maxLines: 3,
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          hint: "Enter travel description",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Amount (Rs.)",
          isRequired: true,
          controller: _amountController,
          focusNode: _amountFocusNode,
          hint: "0.00",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Remarks",
          maxLines: 3,
          controller: _remarksController,
          focusNode: _remarksFocusNode,
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
          maxLines: 3,
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          hint: "Enter food expense description",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Amount (Rs.)",
          isRequired: true,
          controller: _amountController,
          focusNode: _amountFocusNode,
          hint: "0.00",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Remarks",
          maxLines: 3,
          controller: _remarksController,
          focusNode: _remarksFocusNode,
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
          maxLines: 3,
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          hint: "Enter accommodation details",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Amount (Rs.)",
          isRequired: true,
          controller: _amountController,
          focusNode: _amountFocusNode,
          hint: "0.00",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Remarks",
          maxLines: 3,
          controller: _remarksController,
          focusNode: _remarksFocusNode,
          hint: "Enter any additional remarks",
        ),
      ],
    );
  }

  Widget _buildAdvanceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                      child: Center(child: CircularProgressIndicator(color: Colors.white,)),
                    );
                  }

                  return DropdownSearch<ManpowerModel>(
                    selectedItem: _selectedManpower,
                    items: (f, cs) => manpowerState.manpowerList,

                    itemAsString: (ManpowerModel m) =>
                    "${m.fullName ?? 'Unknown'} - ${m.employeeCode ?? 'No Code'}",

                    onChanged: (ManpowerModel? newValue) {
                      setState(() {
                        _selectedManpower = newValue;
                      });
                    },

                    compareFn: (item, selectedItem) =>
                    item.id == selectedItem.id,

                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(
                        hintText: "Select Employee",

                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),

                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "Search employee...",

                        ),
                      ),
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
          maxLines: 3,
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          hint: "Enter advance description",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Amount (Rs.)",
          isRequired: true,
          controller: _amountController,
          focusNode: _amountFocusNode,
          hint: "0.00",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Remarks",
          maxLines: 3,
          controller: _remarksController,
          focusNode: _remarksFocusNode,
          hint: "Enter any additional remarks",
        ),
      ],
    );
  }

  Widget _buildmiscellaneousFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: "Description",
          maxLines: 3,
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          hint: "Enter expense description",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Amount (Rs.)",
          isRequired: true,
          controller: _amountController,
          focusNode: _amountFocusNode,
          hint: "0.00",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Remarks",
          maxLines: 3,
          controller: _remarksController,
          focusNode: _remarksFocusNode,
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
          maxLines: 3,
          controller: _descriptionController,
          focusNode: _descriptionFocusNode,
          hint: "Enter description",
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Remarks",
          maxLines: 3,
          controller: _remarksController,
          focusNode: _remarksFocusNode,
          hint: "Enter any additional remarks",
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _descriptionController.dispose();
    _remarksController.dispose();
    _amountController.dispose();
    _invoiceNumberController.dispose();
    _hardwareShopController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _balanceController.dispose();
    _placeController.dispose();
    // FocusNodes
    _descriptionFocusNode.dispose();
    _remarksFocusNode.dispose();
    _amountFocusNode.dispose();
    _invoiceNumberFocusNode.dispose();
    _hardwareShopFocusNode.dispose();
    _rateFocusNode.dispose();
    _balanceFocusNode.dispose();
    _placeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.read(dailyEntryTranslationHelperProvider);
    return Scaffold(
      // ── FIX 1: resizeToAvoidBottomInset keeps layout intact when keyboard opens ──
      resizeToAvoidBottomInset: true,
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(title: _getScreenTitle()),
      backgroundColor: AppColors.lightBlue,
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
            button: RoundedButton(
              text: "Save",
              color: Colors.blue,
              textColor: Colors.white,
              onPressed: _isLoading ? () {} : _submitForm,
              isOutlined: false,
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
              child: SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lang.dateLabel}',
                      style: const TextStyle(
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
                    _buildFormFields(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}