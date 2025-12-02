// AnalysisReviewScreen (beautified version)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/expense/service/expense_service.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';

import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../attendance/provider/AttendanceProvider.dart';
import '../../attendance/provider/AttendanceService.dart';
import '../../dpr/providers/dprService.dart';
import '../../inventory/service/inventory_service.dart';

import '../../site_Details/providers/site_current_provider.dart';
import '../model/ai_analyze_model.dart';
import '../service/utils/attendance_util.dart';

class AnalysisReviewScreen extends ConsumerStatefulWidget {
  final AudioAnalysis data;

  const AnalysisReviewScreen({super.key, required this.data});

  @override
  ConsumerState<AnalysisReviewScreen> createState() =>
      _AnalysisReviewScreenState();
}

class _AnalysisReviewScreenState extends ConsumerState<AnalysisReviewScreen> {
  // General
  bool _isSubmitting = false;

  // Controllers for simple text fields
  late TextEditingController _transcriptCtrl;
  late TextEditingController _remarksCtrl;

  // Attendance editable list
  final List<TextEditingController> _attendanceControllers = [];

  // DPR editable fields + dynamic items
  late TextEditingController _dprMaterialCtrl;
  late TextEditingController _dprLineSizeCtrl;
  late TextEditingController _dprLengthCtrl;
  final List<_DprItemRow> _dprItems = [];

  // Expense editable fields + dynamic items
  late TextEditingController _expenseTotalCtrl;
  final List<_ExpenseItemRow> _expenseItems = [];

  // Inventory dynamic items
  final List<_InventoryItemRow> _inventoryItems = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // initialise transcript & remarks
    _transcriptCtrl =
        TextEditingController(text: widget.data.metadata.transcript);
    _remarksCtrl = TextEditingController(text: widget.data.metadata.siteRemarks);

    // attendance initialization
    final attendance = widget.data.modules.attendance;
    if (attendance.absentNames.isNotEmpty) {
      for (final name in attendance.absentNames) {
        _attendanceControllers.add(TextEditingController(text: name));
      }
    } else {
      // start with one empty row
      _attendanceControllers.add(TextEditingController());
    }

    // DPR
    final dpr = widget.data.modules.dpr;
    _dprMaterialCtrl = TextEditingController(text: dpr.material ?? "");
    _dprLineSizeCtrl = TextEditingController(text: dpr.lineSize ?? "");
    _dprLengthCtrl = TextEditingController(text: dpr.length.toString() ?? "");
    if (dpr.items.isNotEmpty) {
      for (final it in dpr.items) {
        _dprItems.add(_DprItemRow(
          itemNameCtrl: TextEditingController(text: it.itemName),
          qtyCtrl: TextEditingController(text: it.quantity?.toString() ?? ""),
          unitCtrl: TextEditingController(text: it.unit ?? ""),
        ));
      }
    } else {
      _dprItems.add(_DprItemRow(
        itemNameCtrl: TextEditingController(),
        qtyCtrl: TextEditingController(),
        unitCtrl: TextEditingController(),
      ));
    }

    // Expense
    final expense = widget.data.modules.expense;
    _expenseTotalCtrl = TextEditingController(text: expense.totalAmount?.toString() ?? "");
    if (expense.items.isNotEmpty) {
      for (final it in expense.items) {
        _expenseItems.add(_ExpenseItemRow(
          nameCtrl: TextEditingController(text: it.name),
          qtyCtrl: TextEditingController(text: it.qty?.toString() ?? ""),
          unitCtrl: TextEditingController(text: it.unit ?? ""),
        ));
      }
    } else {
      _expenseItems.add(_ExpenseItemRow(
        nameCtrl: TextEditingController(),
        qtyCtrl: TextEditingController(),
        unitCtrl: TextEditingController(),
      ));
    }

    // Inventory
    final inv = widget.data.modules.inventory;
    if (inv.items.isNotEmpty) {
      for (final it in inv.items) {
        _inventoryItems.add(_InventoryItemRow(
          nameCtrl: TextEditingController(text: it.name),
          qtyCtrl: TextEditingController(text: it.qty?.toString() ?? ""),
          unitCtrl: TextEditingController(text: it.unit ?? ""),
        ));
      }
    } else {
      _inventoryItems.add(_InventoryItemRow(
        nameCtrl: TextEditingController(),
        qtyCtrl: TextEditingController(),
        unitCtrl: TextEditingController(),
      ));
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _transcriptCtrl.dispose();
    _remarksCtrl.dispose();
    for (final c in _attendanceControllers) {
      c.dispose();
    }
    _dprMaterialCtrl.dispose();
    _dprLineSizeCtrl.dispose();
    _dprLengthCtrl.dispose();
    for (final r in _dprItems) {
      r.dispose();
    }
    _expenseTotalCtrl.dispose();
    for (final r in _expenseItems) {
      r.dispose();
    }
    for (final r in _inventoryItems) {
      r.dispose();
    }
  }

  // ---------------- UI BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Review & Edit Extracted Data",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          _buildAppBarActions(),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTranscriptSection(),
            const SizedBox(height: 20),
            _buildRemarksSection(),
            const SizedBox(height: 20),
            _buildAttendanceEditor(),
            const SizedBox(height: 20),
            _buildDprEditor(),
            const SizedBox(height: 20),
            _buildExpenseEditor(),
            const SizedBox(height: 20),
            _buildInventoryEditor(),
            const SizedBox(height: 28),
            _buildSubmitButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarActions() {
    return Row(
      children: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.refresh, size: 20),
          ),
          tooltip: "Reset to original",
          onPressed: _resetToOriginal,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                "AI Analysis Review",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Review and edit the extracted data before submitting to the system.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection() {
    return _buildSection(
      title: "Transcript",
      icon: Icons.transcribe,
      iconColor: Colors.blue,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: TextField(
          controller: _transcriptCtrl,
          maxLines: 6,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.all(16),
            border: InputBorder.none,
            hintText: "Enter transcript text...",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildRemarksSection() {
    return _buildSection(
      title: "Site Remarks",
      icon: Icons.comment,
      iconColor: Colors.green,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: TextField(
          controller: _remarksCtrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.all(16),
            border: InputBorder.none,
            hintText: "Enter site remarks...",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  // ---------------- Attendance Editor ----------------

  Widget _buildAttendanceEditor() {
    return _buildSection(
      title: "Attendance - Absent Team Members",
      icon: Icons.people_alt,
      iconColor: Colors.purple,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Absent Names", Icons.person_off),
              const SizedBox(height: 16),
              ..._attendanceControllers.asMap().entries.map((entry) {
                final i = entry.key;
                final ctrl = entry.value;
                return _buildAttendanceRow(i, ctrl);
              }).toList(),
              if (_attendanceControllers.isEmpty)
                _buildEmptyState("No absent names added", Icons.people_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceRow(int index, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Enter absent team member name",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              _buildRowActions(
                onRemove: _attendanceControllers.length == 1
                    ? null
                    : () {
                  setState(() {
                    controller.dispose();
                    _attendanceControllers.removeAt(index);
                  });
                },
                onAdd: () {
                  setState(() {
                    _attendanceControllers.insert(
                        index + 1, TextEditingController());
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- DPR Editor ----------------

  Widget _buildDprEditor() {
    return _buildSection(
      title: "DPR - Daily Progress Report",
      icon: Icons.construction,
      iconColor: Colors.orange,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Work Details", Icons.work),
              const SizedBox(height: 16),
              _buildDprFormFields(),
              const SizedBox(height: 20),
              _buildSectionHeader("Materials & Items", Icons.inventory_2),
              const SizedBox(height: 12),
              ..._dprItems.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                return _buildDprItemRow(i, row);
              }).toList(),
              if (_dprItems.isEmpty)
                _buildEmptyState("No DPR items added", Icons.list_alt),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDprFormFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildLabeledTextField(
                controller: _dprMaterialCtrl,
                label: "Material",
                hintText: "e.g., PVC, Steel",
                icon: Icons.architecture,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLabeledTextField(
                controller: _dprLineSizeCtrl,
                label: "Line Size",
                hintText: "e.g., 2 inch",
                icon: Icons.straighten,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildLabeledTextField(
          controller: _dprLengthCtrl,
          label: "Length (meters)",
          hintText: "0.0",
          icon: Icons.square_foot,
          isNumber: true,
        ),
      ],
    );
  }

  Widget _buildDprItemRow(int index, _DprItemRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Item",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  _buildRowActions(
                    onRemove: _dprItems.length == 1
                        ? null
                        : () {
                      setState(() {
                        row.dispose();
                        _dprItems.removeAt(index);
                      });
                    },
                    onAdd: () {
                      setState(() {
                        _dprItems.insert(
                          index + 1,
                          _DprItemRow(
                            itemNameCtrl: TextEditingController(),
                            qtyCtrl: TextEditingController(),
                            unitCtrl: TextEditingController(),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: row.itemNameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Item Name",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: row.qtyCtrl,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Quantity",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: row.unitCtrl,
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
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

  // ---------------- Expense Editor ----------------

  Widget _buildExpenseEditor() {
    return _buildSection(
      title: "Expenses",
      icon: Icons.attach_money,
      iconColor: Colors.green,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Total Expense", Icons.calculate),
              const SizedBox(height: 12),
              _buildLabeledTextField(
                controller: _expenseTotalCtrl,
                label: "Total Amount (₹)",
                hintText: "0.00",
                icon: Icons.currency_rupee,
                isNumber: true,
              ),
              const SizedBox(height: 20),
              _buildSectionHeader("Expense Items", Icons.receipt),
              const SizedBox(height: 12),
              ..._expenseItems.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                return _buildExpenseItemRow(i, r);
              }).toList(),
              if (_expenseItems.isEmpty)
                _buildEmptyState("No expense items added", Icons.money_off),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseItemRow(int index, _ExpenseItemRow r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Expense Item",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  _buildRowActions(
                    onRemove: _expenseItems.length == 1
                        ? null
                        : () {
                      setState(() {
                        r.dispose();
                        _expenseItems.removeAt(index);
                      });
                    },
                    onAdd: () {
                      setState(() {
                        _expenseItems.insert(
                          index + 1,
                          _ExpenseItemRow(
                            nameCtrl: TextEditingController(),
                            qtyCtrl: TextEditingController(),
                            unitCtrl: TextEditingController(),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: r.nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Item Name",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: r.qtyCtrl,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Quantity",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: r.unitCtrl,
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
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

  // ---------------- Inventory Editor ----------------

  Widget _buildInventoryEditor() {
    return _buildSection(
      title: "Inventory",
      icon: Icons.inventory,
      iconColor: Colors.blue,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Inventory Items", Icons.palette),
              const SizedBox(height: 12),
              ..._inventoryItems.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                return _buildInventoryItemRow(i, r);
              }).toList(),
              if (_inventoryItems.isEmpty)
                _buildEmptyState("No inventory items added", Icons.inventory_2_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryItemRow(int index, _InventoryItemRow r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Inventory Item",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  _buildRowActions(
                    onRemove: _inventoryItems.length == 1
                        ? null
                        : () {
                      setState(() {
                        r.dispose();
                        _inventoryItems.removeAt(index);
                      });
                    },
                    onAdd: () {
                      setState(() {
                        _inventoryItems.insert(
                          index + 1,
                          _InventoryItemRow(
                            nameCtrl: TextEditingController(),
                            qtyCtrl: TextEditingController(),
                            unitCtrl: TextEditingController(),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: r.nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Item Name",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: r.qtyCtrl,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Quantity",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: r.unitCtrl,
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
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

  // ---------------- Reusable Components ----------------

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber
              ? TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: Icon(icon, size: 20),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildRowActions({
    required VoidCallback? onRemove,
    required VoidCallback onAdd,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: onRemove == null ? Colors.grey.shade300 : Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.remove,
              size: 16,
              color: onRemove == null ? Colors.grey.shade500 : Colors.red,
            ),
          ),
          onPressed: onRemove,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.green),
          ),
          onPressed: onAdd,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitToBackend,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSubmitting)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.cloud_upload, size: 20),
            const SizedBox(width: 8),
            Text(
              _isSubmitting ? "Submitting..." : "Submit All Data to API",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Reset ----------------

  void _resetToOriginal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text("Reset Confirmation"),
          ],
        ),
        content: const Text(
          "Are you sure you want to reset all changes? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _disposeControllers();
                _initializeControllers();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("All data reset to original"),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Reset", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------- Submit Logic (unchanged) ----------------

  Future<void> _submitToBackend() async {
    final siteId = ref.read(selectedSiteIdProvider);
    final teamId = ref.read(selectedTeamIdProvider);
    final type = ref.read(typeProvider);

    if (siteId == null || type == null) {
      _showError("Site ID or Type is missing");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // build edited data
    final editedAbsentNames = _attendanceControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final editedDprItems = _dprItems
        .map((r) => {
      "item_name": r.itemNameCtrl.text.trim(),
      "qty": double.tryParse(r.qtyCtrl.text.trim()) ?? 0,
      "unit": r.unitCtrl.text.trim(),
    })
        .where((m) => (m["item_name"] as String).isNotEmpty)
        .toList();

    final editedExpenseItems = _expenseItems
        .map((r) => {
      "item": r.nameCtrl.text.trim(),
      "qty": double.tryParse(r.qtyCtrl.text.trim()) ?? 0,
      "unit": r.unitCtrl.text.trim(),
    })
        .where((m) => (m["item"] as String).isNotEmpty)
        .toList();

    final editedInventoryItems = _inventoryItems
        .map((r) => {
      "name": r.nameCtrl.text.trim(),
      "qty": double.tryParse(r.qtyCtrl.text.trim()) ?? 0,
      "unit": r.unitCtrl.text.trim(),
    })
        .where((m) => (m["name"] as String).isNotEmpty)
        .toList();

    // Update widget.data locally so helper validators use latest values
    widget.data.metadata.transcript = _transcriptCtrl.text.trim();
    widget.data.metadata.siteRemarks = _remarksCtrl.text.trim();
    widget.data.modules.attendance.absentNames = editedAbsentNames;

    try {
      // ----- VALIDATE AND SUBMIT ATTENDANCE -----
      await _submitAttendance(
        absentNames: editedAbsentNames,
        siteId: siteId,
        type: type,
        date: DateTime.now(),
      );

      // ----- DPR -----
      await DprApi.postDprWork(
        siteId: siteId,
        teamId: teamId!,
        data: {
          "material": _dprMaterialCtrl.text.trim(),
          "line_size": _dprLineSizeCtrl.text.trim(),
          "length": double.tryParse(_dprLengthCtrl.text.trim()) ?? 0,
          "items": editedDprItems,
        },
      );

      // ----- EXPENSE -----
      await ExpenseAPI.createExpense(
        siteId: siteId,
        type: type,
        data: {
          "total": double.tryParse(_expenseTotalCtrl.text.trim()) ?? 0,
          "items": editedExpenseItems,
        },
      );

      _showSuccess("Data submitted successfully");
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _submitAttendance({
    required List<String> absentNames,
    required String siteId,
    required String type,
    required DateTime date,
  }) async {
    try {
      // Validate manpower names
      final invalidNames = await ManpowerUtils.validateManpowerNames(
        names: absentNames,
        type: type,
        ref: ref,
      );

      if (invalidNames.isNotEmpty) {
        throw Exception("Invalid manpower names: ${invalidNames.join(", ")}");
      }

      // Create payload
      final payload = await ManpowerUtils.createAttendancePayload(
        absentNames: absentNames,
        siteId: siteId,
        type: type,
        date: date,
        ref: ref,
      );

      final shouldUpdate = await ManpowerUtils.shouldUpdateAttendance(
        siteId: siteId,
        type: type,
        date: date,
      );

      if (shouldUpdate) {
        await ref.read(attendanceNotifierProvider.notifier).updateMultipleAttendance(
          payload: payload,
          type: type,
          siteId: siteId,
          date: ManpowerUtils.formatDateForDisplay(date),
        );
      } else {
        await ref.read(attendanceNotifierProvider.notifier).postMultipleAttendance(
          payload: payload,
          type: type,
          siteId: siteId,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ---------------- Helper Row Classes ----------------

class _DprItemRow {
  final TextEditingController itemNameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  _DprItemRow({
    required this.itemNameCtrl,
    required this.qtyCtrl,
    required this.unitCtrl,
  });

  void dispose() {
    itemNameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
  }
}

class _ExpenseItemRow {
  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  _ExpenseItemRow({
    required this.nameCtrl,
    required this.qtyCtrl,
    required this.unitCtrl,
  });
  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
  }
}

class _InventoryItemRow {
  final TextEditingController nameCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController unitCtrl;
  _InventoryItemRow({
    required this.nameCtrl,
    required this.qtyCtrl,
    required this.unitCtrl,
  });
  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
  }
}