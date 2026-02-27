import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/inventory/offline/repo/inventory_sync.dart';
import '../../../../../core/utlis/widgets/custom_dropdown.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../core/utlis/widgets/fields/searchableDropdown.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../models/inventory_model.dart';
import '../provider/inventory_provider.dart';


class CreateInventoryScreen extends ConsumerStatefulWidget {
  const CreateInventoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateInventoryScreen> createState() => _CreateInventoryScreenState();
}



class _CreateInventoryScreenState
    extends ConsumerState<CreateInventoryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitsController = TextEditingController();
  final _minStockController = TextEditingController();
  final _uomController = TextEditingController();
  final _remarksController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();

    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId != null) {
      ref.read(inventorySyncControllerProvider(siteId));
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitsController.dispose();
    _minStockController.dispose();
    _uomController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SUBMIT
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId == null) return;



    if (_selectedCategoryId == null) {
      _showError("Select category");
      _showError("Select category");
      return;
    }

    try {
      _loading("Creating inventory...");

      // 🔥 fetch latest categories
      final categories =
      await ref.read(categoriesProvider(siteId).future);

      Category? selectedCategory;
      for (final c in categories) {
        if (c.id == _selectedCategoryId) {
          selectedCategory = c;
          break;
        }
      }

      if (selectedCategory == null) {
        _error("Invalid category");
        return;
      }

      await ref.read(createInventoryProvider((
      siteId: siteId,
      condition: null,
      name: _nameController.text.trim(),
      categoryId: selectedCategory.id,
      uom: _uomController.text.trim(),
      totalQuantityAdded: selectedCategory.type == "consumable"
          ? double.parse(_quantityController.text)
          : null,
      minimumStockLevel: selectedCategory.type == "consumable"
          ? double.parse(_minStockController.text)
          : null,
      totalUnits: selectedCategory.type == "fixed"
          ? int.parse(_unitsController.text)
          : null,
      remarks: _remarksController.text.trim().isEmpty
          ? null
          : _remarksController.text.trim(),
      )).future);

      ref.invalidate(inventoryProvider(siteId));

        ref.read(inventorySyncControllerProvider(siteId));


      Navigator.pop(context);
      _success("Inventory created");
    } catch (e) {
      print(e);
      _error(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(selectedSiteIdProvider);
    final categoriesAsync = ref.watch(categoriesProvider(siteId!));

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(title: "Create Inventory"),
      backgroundColor: AppColors.lightBlue,
      body: BottomButtonWrapper(
        key: _formKey,
        child: categoriesAsync.when(
          loading: () =>
          const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (categories) {
            Category? selectedCategory;
            for (final c in categories) {
              if (c.id == _selectedCategoryId) {
                selectedCategory = c;
                break;
              }
            }

            return ListView(
              children: [
                // CATEGORY
                CustomDropdownField<String>(
                  label: "Category",
                  isRequired: true,
                  value: _selectedCategoryId,
                  items: categories
                      .map((c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.name),
                  ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedCategoryId = v;

                      // Clear previous inputs when switching category
                      _quantityController.clear();
                      _unitsController.clear();
                      _minStockController.clear();
                      _uomController.clear();
                    });
                  },
                ),

            const SizedBox(height: 16),

                // NAME
                CustomTextField(
                  label: 'Inventory Name',
                  isRequired: true,
                  controller: _nameController,
                ),

                const SizedBox(height: 16),


                if (selectedCategory?.type == "consumable") ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Quantity',
                          isRequired: true,
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'UOM',
                          isRequired: true,
                          controller: _uomController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Minimum Stock Level',
                    isRequired: true,
                    controller: _minStockController,
                    keyboardType: TextInputType.number,
                  ),
                ],

                if (selectedCategory?.type == "fixed") ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Total Units',
                          isRequired: true,
                          controller: _unitsController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'UOM',
                          isRequired: true,
                          controller: _uomController,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Remarks',
                  controller: _remarksController,
                  maxLines: 3,
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _submit,
                  child: const Text("Create"),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Snackbars
  // ---------------------------------------------------------------------------

  void _loading(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m)),
  );
  void _success(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m), backgroundColor: Colors.green),
  );
  void _error(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(m), backgroundColor: Colors.red),
  );
  void _showError(String m) => _error(m);
}
