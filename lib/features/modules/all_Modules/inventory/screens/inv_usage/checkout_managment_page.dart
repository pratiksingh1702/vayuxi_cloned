import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../Manpower Details/model/manpower_model.dart';
import '../../../Manpower Details/service/manPowerProvider.dart';
import '../../../site_Details/providers/site_current_provider.dart';
import '../../models/inventory_model.dart';
import '../../offline/repo/inventory_sync.dart';
import '../../provider/inventory_provider.dart';
import '../../../../../../core/utlis/widgets/custom_dropdown.dart';
import '../../../../../../core/utlis/widgets/fields/custom_textField.dart';

// Beautiful Date Picker Widget (reused from usage page)
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
                    selectedTextStyle: const TextStyle(
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

class CheckoutManagementPage extends ConsumerStatefulWidget {
  const CheckoutManagementPage({super.key});

  @override
  ConsumerState<CheckoutManagementPage> createState() =>
      _CheckoutManagementPageState();
}

class _CheckoutManagementPageState
    extends ConsumerState<CheckoutManagementPage> {
  String? selectedInventoryId;
  final issuedToController = TextEditingController();
  final quantityController = TextEditingController();
  final remarksController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DateTime? _expectedReturnDate;

  @override
  void initState() {
    super.initState();

    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId != null) {
      ref.read(inventorySyncControllerProvider(siteId)).runSync();
    }
    final type=ref.read(typeProvider);
    Future.microtask(() {
      ref.read(manpowerProvider.notifier).fetchManpower(type!);
    });
  }

  @override
  void dispose() {
    issuedToController.dispose();
    quantityController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  // Helper method to get available units
  int _getAvailableUnits(List<Inventory> inventoryList) {
    if (selectedInventoryId == null) return 0;
    try {
      final selected = inventoryList.firstWhere((e) => e.id == selectedInventoryId);
      return selected.availableUnits ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Helper method to get selected inventory
  Inventory? _getSelectedInventory(List<Inventory> inventoryList) {
    if (selectedInventoryId == null) return null;
    try {
      return inventoryList.firstWhere((e) => e.id == selectedInventoryId);
    } catch (e) {
      return null;
    }
  }

  // Function to show BeautifulDatePicker
  Future<void> _pickReturnDate() async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => BeautifulDatePicker(
        initialDate: _expectedReturnDate ?? DateTime.now().add(const Duration(days: 7)),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
        title: "Select Expected Return Date",
        primaryColor: Theme.of(context).primaryColor,
        accentColor: Theme.of(context).colorScheme.secondary,
      ),
    );

    if (picked != null) {
      setState(() {
        _expectedReturnDate = picked;
      });
    }
  }

  // Issue item function
  Future<void> _issueItem(List<Inventory> inventoryList, String siteId) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedInventoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an item."),
          backgroundColor: Colors.orange,
        ),
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

    final quantity = int.tryParse(quantityController.text) ?? 0;

    // Validate quantity
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid quantity.")),
      );
      return;
    }

    // Check if sufficient inventory is available
    if (quantity > (selected.availableUnits ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Insufficient inventory. Available: ${selected.availableUnits}, Requested: $quantity",
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
              Text("Issuing item..."),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      await ref.read(createCheckoutProvider((
      siteId: siteId,
      inventoryId: selectedInventoryId!,
      issuedToName: issuedToController.text,
      quantity: quantity,
      expectedReturnDate: _expectedReturnDate,
      remarks: remarksController.text.isEmpty ? null : remarksController.text,
      )).future);

      // Clear form
      issuedToController.clear();
      quantityController.clear();
      remarksController.clear();
      setState(() {
        selectedInventoryId = null;
        _expectedReturnDate = null;
      });

      ref.invalidate(checkoutProvider(siteId));
      ref.invalidate(inventorySyncControllerProvider(siteId));

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Item issued successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error issuing item: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(selectedSiteIdProvider);
    final manpowerState = ref.watch(manpowerProvider);


    if (siteId == null) {
      return const Scaffold(body: Center(child: Text("No site selected")));
    }

    final inventoryAsync = ref.watch(inventoryProvider(siteId));
    final checkoutAsync = ref.watch(checkoutProvider(siteId));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "Checkout Management"),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
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
                e.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(inventoryProvider(siteId)),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
        data: (inventory) {
          // Only FIXED items
          final fixedItems = inventory.where((e) => e.type == "fixed").toList();
          final inventoryMap = {
            for (final i in inventory) i.id: i.name,
          };


          return Column(
            children: [
              // ================= ISSUE SECTION =================
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.assignment_turned_in, color: Colors.blue.shade600, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Issue Item to User",
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ---------------- ITEM DROPDOWN ----------------
                          CustomDropdownField<String>(
                            label: "Select Item",
                            isRequired: true,
                            value: selectedInventoryId,
                            items: fixedItems.map((inv) {
                              final available = inv.availableUnits ?? 0;
                              final isOutOfStock = available == 0;

                              return DropdownMenuItem(
                                value: inv.id,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      inv.name ?? 'Unknown Item',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: isOutOfStock ? Colors.grey : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Available: $available units",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isOutOfStock ? Colors.red : Colors.green,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            selectedItemBuilder: (context) {
                              return fixedItems.map((inv) {
                                return Text(inv.name ?? 'Unknown Item');
                              }).toList();
                            },
                            onChanged: (value) {
                              setState(() {
                                selectedInventoryId = value;
                                quantityController.clear();

                                if (value != null) {
                                  final selected = fixedItems.firstWhere((e) => e.id == value);
                                  if (selected.availableUnits == 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("${selected.name ?? 'Item'} is out of stock."),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              });
                            },
                            hint: "Choose an item from inventory",
                          ),

                          const SizedBox(height: 20),

                          // ---------------- ISSUED TO FIELD ----------------
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Issued To",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),

                              DropdownSearch<ManpowerModel>(
                                itemAsString: (m) => m.fullName ?? '',
                                compareFn: (a, b) => a.id == b.id,

                                items: (filter, _) {
                                  return manpowerState.manpowerList
                                      .where((m) => (m.fullName ?? "")
                                      .toLowerCase()
                                      .contains(filter.toLowerCase()))
                                      .toList();
                                },

                                onChanged: (selected) {
                                  /// put value in controller → API remains unchanged
                                  issuedToController.text = selected?.fullName ?? '';
                                },

                                popupProps: const PopupProps.modalBottomSheet(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                      hintText: 'Search manpower',
                                      contentPadding:
                                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),

                                decoratorProps: const DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    hintText: "Select person",
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),

                                validator: (value) {
                                  if (value == null) {
                                    return "Select a person";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),


                          const SizedBox(height: 20),

                          // ---------------- QUANTITY FIELD ----------------
                          CustomTextField(
                            label: "Quantity${selectedInventoryId != null ? " (Max: ${_getAvailableUnits(fixedItems)} units)" : ""}",
                            controller: quantityController,
                            isRequired: true,
                            hint: "Enter quantity to issue",
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter quantity';
                              }
                              final quantity = int.tryParse(value);
                              if (quantity == null) {
                                return 'Please enter a valid number';
                              }
                              if (quantity <= 0) {
                                return 'Quantity must be greater than 0';
                              }

                              // Check available stock if item is selected
                              if (selectedInventoryId != null) {
                                final available = _getAvailableUnits(fixedItems);
                                if (quantity > available) {
                                  return 'Insufficient stock. Available: $available';
                                }
                              }

                              return null;
                            },
                          ),

                          // Available quantity display
                          if (selectedInventoryId != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _getAvailableUnits(fixedItems) == 0
                                    ? Colors.red.shade50
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getAvailableUnits(fixedItems) == 0
                                      ? Colors.red.shade200
                                      : Colors.green.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getAvailableUnits(fixedItems) == 0
                                        ? Icons.warning_amber_rounded
                                        : Icons.inventory_2_rounded,
                                    color: _getAvailableUnits(fixedItems) == 0
                                        ? Colors.red
                                        : Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _getAvailableUnits(fixedItems) == 0
                                          ? "Out of stock - Cannot issue this item"
                                          : "Available units: ${_getAvailableUnits(fixedItems)}",
                                      style: TextStyle(
                                        color: _getAvailableUnits(fixedItems) == 0
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

                          const SizedBox(height: 20),

                          // ---------------- EXPECTED RETURN DATE ----------------
                          GestureDetector(
                            onTap: _pickReturnDate,
                            child: AbsorbPointer(
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
                                          Icons.event,
                                          size: 20,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _expectedReturnDate == null
                                              ? "Expected Return Date (Optional)"
                                              : "${_expectedReturnDate!.day.toString().padLeft(2, '0')}/"
                                              "${_expectedReturnDate!.month.toString().padLeft(2, '0')}/"
                                              "${_expectedReturnDate!.year}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: _expectedReturnDate == null
                                                ? FontWeight.w400
                                                : FontWeight.w500,
                                            color: _expectedReturnDate == null
                                                ? Colors.grey.shade600
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(Icons.arrow_drop_down, size: 24),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ---------------- REMARKS FIELD ----------------
                          CustomTextField(
                            label: "Remarks (Optional)",
                            controller: remarksController,
                            isRequired: false,
                            hint: "Add any additional notes",
                            keyboardType: TextInputType.text,
                            maxLines: 3,
                          ),

                          const SizedBox(height: 30),

                          // ---------------- ISSUE BUTTON ----------------
                          SizedBox(
                            width: double.infinity,
                            child: RoundedButton(
                              text: "Issue Item",
                              color: Colors.blue,
                              textColor: Colors.white,
                              onPressed: () => _issueItem(fixedItems, siteId),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Information card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade100),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange.shade600, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Checkout Information",
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Issuing items will reduce available units. Items must be returned to restore inventory.",
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20,),
                          Container(

                            decoration: BoxDecoration(
                              color: Colors.white,



                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Section Header
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.list_alt, color: Colors.blue.shade700, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Active Checkouts",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Divider(height: 1),

                                // Checkout List
                                SizedBox(
                                  height: 250,
                                  child: checkoutAsync.when(
                                    loading: () => const Center(child: CircularProgressIndicator()),
                                    error: (e, _) => Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Error loading checkouts",
                                              style: TextStyle(color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    data: (checkouts) {
                                      final activeCheckouts =
                                      checkouts.where((c) => c.status != "returned").toList();
                                      if (activeCheckouts.isEmpty) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.inbox_outlined,
                                                size: 60,
                                                color: Colors.grey.shade300,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                "No active checkouts",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Issue items to see them here",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return ListView.separated(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        itemCount: activeCheckouts.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                                        itemBuilder: (_, i) {
                                          final c = activeCheckouts[i];
                                          final itemName = c.inventory.name;

                                          final isReturned = c.status == "returned";

                                          return Container(
                                            decoration: BoxDecoration(
                                              color: isReturned ? Colors.green.shade50 : Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isReturned
                                                    ? Colors.green.shade200
                                                    : Colors.grey.shade200,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                children: [
                                                  // Icon
                                                  Container(
                                                    padding: const EdgeInsets.all(10),
                                                    decoration: BoxDecoration(
                                                      color: isReturned
                                                          ? Colors.green.shade100
                                                          : Colors.orange.shade100,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      isReturned
                                                          ? Icons.check_circle
                                                          : Icons.schedule,
                                                      color: isReturned
                                                          ? Colors.green.shade700
                                                          : Colors.orange.shade700,
                                                      size: 20,
                                                    ),
                                                  ),

                                                  const SizedBox(width: 12),

                                                  // Details
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        /// Person
                                                        Text(
                                                          c.issuedToName,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 15,
                                                          ),
                                                        ),

                                                        const SizedBox(height: 2),

                                                        /// Item name
                                                        Text(
                                                          itemName,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w500,
                                                            color: Colors.blueGrey.shade700,
                                                          ),
                                                        ),

                                                        const SizedBox(height: 6),

                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.inventory_2,
                                                              size: 14,
                                                              color: Colors.grey.shade600,
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              "Qty: ${c.quantity}",
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                color: Colors.grey.shade700,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 12),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 2,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: isReturned
                                                                    ? Colors.green.shade100
                                                                    : Colors.orange.shade100,
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              child: Text(
                                                                c.status.toUpperCase(),
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: isReturned
                                                                      ? Colors.green.shade800
                                                                      : Colors.orange.shade800,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                  // Action Button
                                                  if (!isReturned)
                                                    SizedBox(
                                                      height: 36,
                                                      child: ElevatedButton(
                                                        onPressed: () async {
                                                          await ref.read(updateCheckoutProvider((
                                                          siteId: siteId,
                                                          checkoutId: c.id,
                                                          status: "returned",
                                                          actualReturnDate: DateTime.now(),
                                                          returnRemarks: null,
                                                          condition: null,
                                                          )).future);

                                                          ref.invalidate(inventorySyncControllerProvider(siteId));

                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text("Item returned successfully"),
                                                              backgroundColor: Colors.green,
                                                            ),
                                                          );
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.blue,
                                                          foregroundColor: Colors.white,
                                                          elevation: 0,
                                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          "Return",
                                                          style: TextStyle(fontSize: 12),
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green.shade600,
                                                      size: 28,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  ),
                ),
              ),

              // ================= ACTIVE CHECKOUTS SECTION =================

            ],
          );
        },
      ),
    );
  }
}