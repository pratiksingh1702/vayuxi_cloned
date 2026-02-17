import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utlis/colors/colors.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../models/inventory_model.dart';
import '../provider/inventory_provider.dart';

class EditInventoryScreen extends ConsumerStatefulWidget {
  final Inventory inventory;

  const EditInventoryScreen({super.key, required this.inventory});

  @override
  ConsumerState<EditInventoryScreen> createState() =>
      _EditInventoryScreenState();
}

class _EditInventoryScreenState extends ConsumerState<EditInventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  final _uomController = TextEditingController();
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _nameController.text = widget.inventory.name;
    _remarksController.text = widget.inventory.remarks ?? "";

    if (widget.inventory.type == "consumable") {
      _quantityController.text =
          widget.inventory.totalQuantityAdded?.toString() ?? "";
      _minStockController.text =
          widget.inventory.minimumStockLevel?.toString() ?? "";
      _uomController.text = widget.inventory.uom ?? "";
    } else {
      _quantityController.text =
          widget.inventory.totalUnits?.toString() ?? "";
    }
  }

  Future<void> _updateInventory() async {
    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId == null) return;

    if (!_formKey.currentState!.validate()) return;

    try {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Updating...")));

      await ref.read(updateInventoryProvider((
      siteId: siteId,
      inventoryId: widget.inventory.id,
      name: _nameController.text.trim(),
      uom: widget.inventory.type == "consumable"
          ? _uomController.text.trim()
          : null,
      minimumStockLevel: widget.inventory.type == "consumable"
          ? double.tryParse(_minStockController.text)
          : null,
      totalUnits: widget.inventory.type == "fixed"
          ? int.tryParse(_quantityController.text)
          : null,
      remarks: _remarksController.text.trim().isEmpty
          ? null
          : _remarksController.text.trim(),
      ) as ({String? condition, String inventoryId, double? minimumStockLevel, String? name, String? remarks, String siteId, int? totalUnits, String? uom})).future);

      ref.invalidate(inventoryProvider(siteId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated successfully")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Edit Inventory"),
      backgroundColor: AppColors.lightBlue,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ---------------- NAME ----------------
              CustomTextField(
                label: "Item Name",
                controller: _nameController,
                isRequired: true,
                prefixIcon: const Icon(Icons.edit),
              ),

              const SizedBox(height: 16),

              // ---------------- QUANTITY / UNITS ----------------
              CustomTextField(
                label: widget.inventory.type == "consumable"
                    ? 'Total Quantity Added'
                    : 'Total Units',
                isRequired: true,
                controller: _quantityController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.format_list_numbered),
              ),

              const SizedBox(height: 16),

              // ---------------- UOM (only consumable) ----------------
              if (widget.inventory.type == "consumable") ...[
                CustomTextField(
                  label: 'Unit of Measure',
                  isRequired: true,
                  controller: _uomController,
                  prefixIcon: const Icon(Icons.safety_check),
                ),
                const SizedBox(height: 16),
              ],

              // ---------------- MIN STOCK (only consumable) ----------------
              if (widget.inventory.type == "consumable") ...[
                CustomTextField(
                  label: 'Minimum Stock Level',
                  isRequired: true,
                  controller: _minStockController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.warning_amber),
                ),
                const SizedBox(height: 16),
              ],

              // ---------------- REMARKS ----------------
              CustomTextField(
                label: 'Remarks',
                controller: _remarksController,
                maxLines: 3,
                hint: "Optional",
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _updateInventory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  "Update Inventory",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
