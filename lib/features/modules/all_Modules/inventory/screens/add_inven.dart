import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/custom_dropdown.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../models/inventory_Model.dart';
import '../provider/inventory_provider.dart';

class CreateInventoryScreen extends ConsumerStatefulWidget {
  const CreateInventoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateInventoryScreen> createState() => _CreateInventoryScreenState();
}

class _CreateInventoryScreenState extends ConsumerState<CreateInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  final _uomController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String? _selectedItemId;
  bool _createNewItem = false;
  List<Subcategory> _filteredSubcategories = [];

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _uomController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  // ---------------- Category & Subcategory ----------------
  Future<void> _onCategoryChanged(String? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedSubcategoryId = null;
      _filteredSubcategories = [];
    });

    if (categoryId == null) return;

    try {
      final siteId = ref.read(selectedSiteIdProvider);
      if (siteId != null) {
        final subcategories = await ref
            .read(subcategoriesProvider((siteId: siteId, categoryId: categoryId)).future);
        if (mounted) {
          setState(() {
            _filteredSubcategories = subcategories;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading subcategories: $e');
    }
  }

  void _onSubcategoryChanged(String? subcategoryId) {
    setState(() {
      _selectedSubcategoryId = subcategoryId;
    });
  }

  // ---------------- Item ----------------
  void _onItemChanged(String? itemId) {
    setState(() {
      _selectedItemId = itemId;
      _createNewItem = itemId == 'new';
    });
  }

  // ---------------- Submit Form ----------------
  Future<void> _submitForm() async {
    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId == null) return;

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedSubcategoryId == null || _selectedItemId == null) return;
    if (_createNewItem && _itemNameController.text.trim().isEmpty) return;

    try {
      final overlay = ScaffoldMessenger.of(context);
      overlay.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Creating inventory...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      String finalItemId = _selectedItemId!;

      if (_createNewItem) {
        final newItem = await ref.read(createItemProvider((
        siteId: siteId,
        name: _itemNameController.text.trim(),
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
      totalQuantityAdded: double.parse(_quantityController.text),
      minimumStockLevel: double.parse(_minStockController.text),
      uom: _uomController.text.trim(),
      remarks: _remarksController.text.trim().isNotEmpty ? _remarksController.text.trim() : null,
      )).future);

      overlay.hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventory created successfully!')),
      );

      _formKey.currentState!.reset();
      setState(() {
        _selectedCategoryId = null;
        _selectedSubcategoryId = null;
        _selectedItemId = null;
        _filteredSubcategories = [];
        _createNewItem = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create inventory: ${e.toString()}')),
      );
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(selectedSiteIdProvider);
    final categoriesAsync = ref.watch(categoriesProvider(siteId!));
    final itemsAsync = ref.watch(itemsProvider((siteId: siteId)));

    return Scaffold(
      appBar: CustomAppBar(title: "Create Inventory"),
      backgroundColor: AppColors.lightBlue,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildItemDropdown(itemsAsync),
              if (_createNewItem) ...[
                const SizedBox(height: 16),
                _buildItemNameField(),
              ],
              const SizedBox(height: 16),
              _buildCategoryDropdown(categoriesAsync),
              const SizedBox(height: 16),
              _buildSubcategoryDropdown(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildQuantityField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildUOMField()),
                ],
              ),
              const SizedBox(height: 16),
              _buildMinStockField(),
              const SizedBox(height: 16),
              _buildRemarksField(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add Inventory Stock', style: TextStyle(fontSize: 16,color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Widgets ----------------
  Widget _buildItemDropdown(AsyncValue<List<InventoryItem>> itemsAsync) {
    return itemsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, _) => Text('Failed to load items', style: TextStyle(color: Colors.red)),
      data: (items) => CustomDropdownField<String>(
        label: 'Item',
        isRequired: true,
        value: _selectedItemId,
        items: [
          const DropdownMenuItem(value: null, child: Text('Select Item')),
          ...items.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))),
          const DropdownMenuItem(
            value: 'new',
            child: Row(children: [Icon(Icons.add, size: 18), SizedBox(width: 8), Text('Create New Item')]),
          ),
        ],
        onChanged: _onItemChanged,
      )

    );
  }

  Widget _buildCategoryDropdown(AsyncValue<List<Category>> categoriesAsync) {
    return categoriesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, _) => Text('Failed to load categories', style: TextStyle(color: Colors.red)),
      data: (categories) =>CustomDropdownField<String>(
        label: 'Category',
        isRequired: true,
        value: _selectedCategoryId,
        items: [
          const DropdownMenuItem(value: null, child: Text('Select Category')),
          ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
        ],
        onChanged: _onCategoryChanged,
      )
      ,
    );
  }

  Widget _buildSubcategoryDropdown() {
    return _selectedCategoryId == null
        ? const Text('Select a category first', style: TextStyle(color: Colors.grey))
        :CustomDropdownField<String>(
      label: 'Subcategory',
      isRequired: true,
      value: _selectedSubcategoryId,
      items: [
        const DropdownMenuItem(value: null, child: Text('Select Subcategory')),
        ..._filteredSubcategories.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
      ],
      onChanged: _onSubcategoryChanged,
    );
  }

  Widget _buildItemNameField() {
    return TextFormField(
      controller: _itemNameController,
      decoration: const InputDecoration(
        labelText: 'New Item Name *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.inventory_2_outlined),
      ),
      validator: (v) => (_createNewItem && (v == null || v.trim().isEmpty)) ? 'Enter item name' : null,
    );
  }

  Widget _buildQuantityField() {
    return CustomTextField(
      label: 'Quantity',
      isRequired: true,
      controller: _quantityController,
      keyboardType: TextInputType.number,
      prefixIcon: const Icon(Icons.format_list_numbered),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter quantity';
        if (double.tryParse(v) == null) return 'Enter valid number';
        if (double.parse(v) <= 0) return 'Must be > 0';
        return null;
      },
    );

  }

  Widget _buildUOMField() {
    return CustomTextField(
      label: 'Unit of Measure',
      isRequired: true,
      controller: _uomController,
      prefixIcon: const Icon(Icons.safety_check),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter UOM';
        return null;
      },
    );
  }

  Widget _buildMinStockField() {
    return CustomTextField(
      label: 'Minimum Stock Level',
      isRequired: true,
      controller: _minStockController,
      keyboardType: TextInputType.number,
      prefixIcon: const Icon(Icons.warning_amber),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter minimum stock';
        final parsed = double.tryParse(v);
        if (parsed == null) return 'Enter valid number';
        if (parsed < 0) return 'Cannot be negative';
        return null;
      },
    );
  }

  Widget _buildRemarksField() {
    return CustomTextField(
      label: 'Remarks',
      controller: _remarksController,
      maxLines: 3,
      hint: 'Optional',
    );
  }
}
