import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
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
      _quantityController.text = widget.inventory.totalUnits?.toString() ?? "";
      _uomController.text = widget.inventory.uom ?? "";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _uomController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId == null) return;

    if (!_formKey.currentState!.validate()) return;

    try {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Updating...")));

      await ref.read(updateInventoryProvider(UpdateInventoryParams(
        siteId: siteId,
        inventoryId: widget.inventory.id,
        name: _nameController.text.trim(),
        uom: _uomController.text.trim(),
        minimumStockLevel: widget.inventory.type == "consumable"
            ? double.tryParse(_minStockController.text)
            : null,
        totalUnits: widget.inventory.type == "fixed"
            ? int.tryParse(_quantityController.text)
            : null,
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        condition: null,
      )).future);

      _success("Updated successfully");
      context.pop(true);
    } catch (e) {
      _error("Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConsumable = widget.inventory.type == "consumable";
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(title: "Edit Inventory"),
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
            button: RoundedButton(
              text: "Update",
              color: colorScheme.primary,
              textColor: colorScheme.onPrimary,
              onPressed: _submit,
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // ---------- CATEGORY (read-only display) ----------
                _ReadOnlyField(
                  label: "Category",
                  value: widget.inventory.type,
                  icon: Icons.category,
                ),

                const SizedBox(height: 16),

                // ---------- NAME ----------
                CustomTextField(
                  label: 'Inventory Name',
                  isRequired: true,
                  controller: _nameController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Name required" : null,
                ),

                const SizedBox(height: 16),

                // ---------- CONSUMABLE FIELDS ----------
                if (isConsumable) ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Quantity',
                          isRequired: true,
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Required";
                            final n = double.tryParse(v);
                            if (n == null) return "Invalid";
                            if (n < 0) return "Negative";
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'UOM',
                          isRequired: true,
                          controller: _uomController,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? "Required" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Minimum Stock Level',
                    isRequired: true,
                    controller: _minStockController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Required";
                      final n = double.tryParse(v);
                      if (n == null) return "Invalid";
                      if (n < 0) return "Negative";
                      return null;
                    },
                  ),
                ],

                // ---------- FIXED FIELDS ----------
                if (!isConsumable) ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Total Units',
                          isRequired: true,
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Required";
                            final n = int.tryParse(v);
                            if (n == null) return "Invalid";
                            if (n < 0) return "Negative";
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'UOM',
                          isRequired: true,
                          controller: _uomController,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? "Required" : null,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // ---------- REMARKS ----------
                CustomTextField(
                  label: 'Remarks',
                  controller: _remarksController,
                  maxLines: 3,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _success(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
  void _error(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
}

// ---------------------------------------------------------------------------
// Read-only field to display category (non-editable, matches form style)
// ---------------------------------------------------------------------------

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Text(
                value,
                style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
              ),
              const Spacer(),
              Icon(Icons.lock_outline,
                  size: 16, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ],
    );
  }
}
