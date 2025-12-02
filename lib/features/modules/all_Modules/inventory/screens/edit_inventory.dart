import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utlis/colors/colors.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/custom_dropdown.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../models/inventory_Model.dart';
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

  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  final _uomController = TextEditingController();
  final _remarksController = TextEditingController();
  final _newItemNameController = TextEditingController();

  String? _selectedItemId;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;

  bool _createNewItem = false;

  @override
  void initState() {
    super.initState();

    _selectedItemId = widget.inventory.itemId;
    _selectedCategoryId = widget.inventory.categoryId;
    _selectedSubcategoryId = widget.inventory.subcategoryId;

    _quantityController.text =
        widget.inventory.totalQuantityAdded.toString();
    _minStockController.text =
        widget.inventory.minimumStockLevel.toString();
    _uomController.text = widget.inventory.uom;
    _remarksController.text = widget.inventory.remarks ?? "";
  }

  double safeParse(String value) {
    return double.tryParse(value.trim()) ?? 0.0;
  }

  Future<void> _onItemChanged(String? value) async {
    if (value == null) return;

    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId == null) return;

    setState(() {
      _selectedItemId = value;
      _createNewItem = value == "new";
    });

    if (value == "new") return;

    final items =
    await ref.read(itemsProvider((siteId: siteId)).future);

    final selected =
    items.firstWhere((e) => e.id == value, orElse: () => throw "Item not found");

    setState(() {
      _selectedCategoryId = selected.categoryId;
      _selectedSubcategoryId = selected.subcategoryId;
    });
  }

  Future<void> _updateInventory() async {
    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId == null) return;

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedSubcategoryId == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updating...")),
      );

      String finalItemId = _selectedItemId!;

      if (_createNewItem) {
        if (_newItemNameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Enter item name")),
          );
          return;
        }

        final newItem = await ref.read(createItemProvider((
        siteId: siteId,
        name: _newItemNameController.text.trim(),
        categoryId: _selectedCategoryId!,
        subcategoryId: _selectedSubcategoryId!,
        )).future);

        finalItemId = newItem.id;
        ref.invalidate(itemsProvider((siteId: siteId)));
      }

      await ref.read(addUpdateInventoryStockProvider((
      siteId: siteId,
      itemId: finalItemId,
      categoryId: _selectedCategoryId!,
      subcategoryId: _selectedSubcategoryId!,
      totalQuantityAdded: safeParse(_quantityController.text),
      minimumStockLevel: safeParse(_minStockController.text),
      uom: _uomController.text.trim(),
      remarks: _remarksController.text.trim().isEmpty
          ? null
          : _remarksController.text.trim(),
      )).future);

      ref.invalidate(itemsProvider((siteId: siteId)));
      ref.invalidate(categoriesProvider(siteId));
      ref.invalidate(subcategoriesProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inventory updated successfully!")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(selectedSiteIdProvider);
    final itemsAsync = ref.watch(itemsProvider((siteId: siteId!)));
    final categoriesAsync = ref.watch(categoriesProvider(siteId));

    final subAsync = _selectedCategoryId == null
        ? const AsyncValue.data(<Subcategory>[])
        : ref.watch(subcategoriesProvider(
        (siteId: siteId, categoryId: _selectedCategoryId!)));

    return Scaffold(
      appBar: CustomAppBar(title: "Edit Inventory"),
      backgroundColor: AppColors.lightBlue,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ---------------- ITEM ----------------
              itemsAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text("Failed to load items"),
                data: (items) => CustomDropdownField<String>(
                  label: "Item",
                  isRequired: true,
                  value: _createNewItem ? "new" : _selectedItemId,
                  items: [
                    ...items.map((i) =>
                        DropdownMenuItem(value: i.id, child: Text(i.name))),
                    const DropdownMenuItem(
                        value: "new",
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 18),
                            SizedBox(width: 8),
                            Text("Create New Item")
                          ],
                        )),
                  ],
                  onChanged: _onItemChanged,
                ),
              ),

              if (_createNewItem) ...[
                const SizedBox(height: 12),
                CustomTextField(
                  label: "New Item Name",
                  controller: _newItemNameController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.edit),
                ),
              ],

              const SizedBox(height: 16),

              // ---------------- CATEGORY ----------------
              categoriesAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text("Failed to load categories"),
                data: (categories) => CustomDropdownField<String>(
                  label: "Category",
                  isRequired: true,
                  value: _selectedCategoryId,
                  items: categories
                      .map((c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedCategoryId = v;
                      _selectedSubcategoryId = null;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ---------------- SUBCATEGORY ----------------
              subAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text("Failed to load subcategories"),
                data: (subs) => CustomDropdownField<String>(
                  label: "Subcategory",
                  isRequired: true,
                  value: _selectedSubcategoryId,
                  items: subs
                      .map((s) =>
                      DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedSubcategoryId = v),
                ),
              ),

              const SizedBox(height: 16),

              CustomTextField(
                label: 'Quantity',
                isRequired: true,
                controller: _quantityController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.format_list_numbered),
              ),

              const SizedBox(height: 16),

              CustomTextField(
                label: 'Unit of Measure',
                isRequired: true,
                controller: _uomController,
                prefixIcon: const Icon(Icons.safety_check),
              ),

              const SizedBox(height: 16),

              CustomTextField(
                label: 'Minimum Stock Level',
                isRequired: true,
                controller: _minStockController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.warning_amber),
              ),

              const SizedBox(height: 16),

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
