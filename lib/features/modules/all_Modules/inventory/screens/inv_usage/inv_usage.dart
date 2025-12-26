import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../../../../core/utlis/widgets/custom_dropdown.dart';
import '../../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../site_Details/providers/site_current_provider.dart';
import '../../models/inventory_Model.dart';
import '../../provider/inventory_provider.dart';

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
    final primaryColor = widget.primaryColor ?? Theme.of(context).primaryColor;
    final accentColor = widget.accentColor ?? Theme.of(context).colorScheme.secondary;
    final backgroundColor = widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

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

class InventorySelectionPage extends ConsumerStatefulWidget {
  const InventorySelectionPage({super.key});

  @override
  ConsumerState<InventorySelectionPage> createState() =>
      _InventorySelectionPageState();
}

class _InventorySelectionPageState
    extends ConsumerState<InventorySelectionPage> {
  String? _selectedInventoryId;
  final TextEditingController _uomController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();


  @override
  void dispose() {
    _uomController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Helper method to get available quantity
  double _getAvailableQuantity(List<Inventory> inventoryList) {
    if (_selectedInventoryId == null) return 0;
    try {
      final selected = inventoryList.firstWhere((e) => e.id == _selectedInventoryId);
      return selected.currentBalance;
    } catch (e) {
      return 0;
    }
  }

  // Function to show BeautifulDatePicker
  Future<void> _pickDate() async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => BeautifulDatePicker(
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        title: "Select Usage Date",
        primaryColor: Theme.of(context).primaryColor,
        accentColor: Theme.of(context).colorScheme.secondary,
      ),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Helper method to get selected inventory
  Inventory? _getSelectedInventory(List<Inventory> inventoryList) {
    if (_selectedInventoryId == null) return null;
    try {
      return inventoryList.firstWhere((e) => e.id == _selectedInventoryId);
    } catch (e) {
      return null;
    }
  }

  // Separate method for recording usage
  Future<void> _recordUsage(List<Inventory> inventoryList, String siteId) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInventoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an item.")),
      );
      return;
    }

    final selected = _getSelectedInventory(inventoryList);
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selected item not found.")),
      );
      return;
    }

    final quantityUsed = double.tryParse(_quantityController.text) ?? 0;

    // Validate quantity
    if (quantityUsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid quantity.")),
      );
      return;
    }

    // Check if sufficient inventory is available
    if (quantityUsed > selected.currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Insufficient inventory. Available: ${selected.currentBalance}, Requested: $quantityUsed",
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(width: 10),
              Text("Recording usage..."),
            ],
          ),
          duration: Duration(seconds: 3), // Long duration for async operation
        ),
      );

      // Build args
      final args = RecordUsageArgs(
        inventoryId: selected.id,
        itemId: selected.item!.id,
        siteId: siteId,
        quantityUsed: quantityUsed,
        categoryId: selected.category?.id,
        subcategoryId: selected.subcategory?.id,
        usageDate: _selectedDate.toIso8601String(),
        remarks: "Usage recorded via mobile app",
      );

      // Call provider
      await ref.read(recordUsageProvider(args).future);

      // Clear form
      setState(() {
        _selectedInventoryId = null;
        _quantityController.clear();
        _uomController.clear();
      });



      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Usage recorded successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh inventory list
      ref.invalidate(allInventoryProvider(siteId));

    } catch (e) {
      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("Error recording usage: ${e.toString()}"),
      //     backgroundColor: Colors.red,
      //     duration: const Duration(seconds: 3),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(selectedSiteIdProvider);

    if (siteId == null) {
      return const Scaffold(
        body: Center(child: Text("No site selected")),
      );
    }

    final inventoryAsync = ref.watch(allInventoryProvider(siteId));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "Inventory usage"),
      body: BottomButtonWrapper(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: inventoryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        "Error loading inventory",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(allInventoryProvider(siteId)),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
                data: (inventoryList) {
                  // Filter out items with no stock if needed
                  final availableItems = inventoryList.where((item) => item.currentBalance > 0).toList();
                  final allItems = inventoryList;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Picker Container with BeautifulDatePicker
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFDFE2E6)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "${_selectedDate.day.toString().padLeft(2,'0')}/"
                                        "${_selectedDate.month.toString().padLeft(2,'0')}/"
                                        "${_selectedDate.year}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.arrow_drop_down, size: 24),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ---------------- ITEM DROPDOWN ----------------
                      CustomDropdownField<String>(
                        label: "Select Inventory Item",
                        isRequired: true,
                        value: _selectedInventoryId,
                        items: allItems.map((inv) {
                          final isLowStock = inv.currentBalance <= inv.minimumStockLevel;
                          final isOutOfStock = inv.currentBalance == 0;

                          return DropdownMenuItem(
                            value: inv.id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  inv.item?.name ?? 'Unknown Item',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: isOutOfStock ? Colors.grey : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Available: ${inv.currentBalance} ${inv.uom}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOutOfStock
                                        ? Colors.red
                                        : isLowStock
                                        ? Colors.orange
                                        : Colors.green,
                                    fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                if (isLowStock && !isOutOfStock) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    "Low stock warning!",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                        selectedItemBuilder: (context) {
                          return allItems.map((inv) {
                            return Text(inv.item?.name ?? 'Unknown Item');
                          }).toList();
                        },
                        onChanged: (value) {
                          setState(() {
                            _selectedInventoryId = value;

                            final selected = allItems.firstWhere(
                                  (e) => e.id == value,
                            );

                            _uomController.text = selected.uom;
                            _quantityController.text = ""; // Clear previous quantity

                            // Show available quantity to user
                            if (selected.currentBalance == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${selected.item?.name ?? 'Item'} is out of stock."),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else if (selected.currentBalance <= selected.minimumStockLevel) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${selected.item?.name ?? 'Item'} is low on stock."),
                                  backgroundColor: Colors.orange,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          });
                        },
                        hint: "Choose an item from inventory",
                      ),

                      const SizedBox(height: 20),

                      // ---------------- UOM FIELD ----------------
                      CustomTextField(
                        label: "Unit of Measure",
                        controller: _uomController,
                        isRequired: true,
                        hint: "Unit will auto-fill when item is selected",
                        keyboardType: TextInputType.text,
                        validator: null,

                      ),

                      const SizedBox(height: 20),

                      // ---------------- QUANTITY FIELD ----------------
                      CustomTextField(
                        label: "Quantity to Use${_selectedInventoryId != null ? " (Max: ${_getAvailableQuantity(allItems)} ${_uomController.text})" : ""}",
                        controller: _quantityController,
                        isRequired: true,
                        hint: "Enter quantity to use",
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          final quantity = double.tryParse(value);
                          if (quantity == null) {
                            return 'Please enter a valid number';
                          }
                          if (quantity <= 0) {
                            return 'Quantity must be greater than 0';
                          }

                          // Check available stock if item is selected
                          if (_selectedInventoryId != null) {
                            final available = _getAvailableQuantity(allItems);
                            if (quantity > available) {
                              return 'Insufficient stock. Available: $available';
                            }
                          }

                          return null;
                        },

                      ),

                      // Available quantity display
                      if (_selectedInventoryId != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getAvailableQuantity(allItems) == 0
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getAvailableQuantity(allItems) == 0
                                  ? Colors.red.shade200
                                  : Colors.green.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getAvailableQuantity(allItems) == 0
                                    ? Icons.warning_amber_rounded
                                    : Icons.inventory_2_rounded,
                                color: _getAvailableQuantity(allItems) == 0
                                    ? Colors.red
                                    : Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getAvailableQuantity(allItems) == 0
                                      ? "Out of stock - Cannot use this item"
                                      : "Available stock: ${_getAvailableQuantity(allItems)} ${_uomController.text}",
                                  style: TextStyle(
                                    color: _getAvailableQuantity(allItems) == 0
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 30),

                      // ---------------- RECORD USAGE BUTTON ----------------
                      SizedBox(
                          width: double.infinity,
                          child: RoundedButton(text: "Record Usage",
                              color:Colors.blue,
                              textColor: Colors.white,
                              onPressed: () => _recordUsage(allItems, siteId))
                      ),

                      // Information card
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  "Usage Information",
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Recording usage will deduct the quantity from available stock. "
                                  "This action cannot be undone automatically.",
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}