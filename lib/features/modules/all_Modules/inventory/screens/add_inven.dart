import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/inventory/offline/repo/inventory_sync.dart';
import '../../../../../core/utlis/widgets/custom_dropdown.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../models/inventory_model.dart';
import '../provider/inventory_provider.dart';
import 'add_bulk_inven.dart';

class CreateInventoryScreen extends ConsumerStatefulWidget {
  const CreateInventoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateInventoryScreen> createState() =>
      _CreateInventoryScreenState();
}

class _CreateInventoryScreenState extends ConsumerState<CreateInventoryScreen> {
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
      // SINGLE sync trigger in screen init ONLY
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
      return;
    }

    try {
      _loading("Creating inventory...");

      // 🔥 fetch latest categories
      final categories = await ref.read(categoriesProvider(siteId).future);

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

      await ref.read(createInventoryProvider(CreateInventoryParams(
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

      context.pop();
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(
        title: "Create Inventory",
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BulkUploadScreen()),
            ),
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text("Import Sheet"),
          ),
        ],
      ),
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
              button: RoundedButton(
                  text: "Save",
                  color: colorScheme.primary,
                  textColor: colorScheme.onPrimary,
                  onPressed: _submit))
        ],
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: categoriesAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
            error: (e, _) => Center(
              child: Text(
                e.toString(),
                style: TextStyle(color: colorScheme.error),
              ),
            ),
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
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return "Name is required";
                      return null;
                    },
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

                  if (selectedCategory?.type == "fixed") ...[
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Total Units',
                            isRequired: true,
                            controller: _unitsController,
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

                  CustomTextField(
                    label: 'Remarks',
                    controller: _remarksController,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Snackbars
  // ---------------------------------------------------------------------------

  void _loading(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
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
  void _showError(String m) => _error(m);
}
