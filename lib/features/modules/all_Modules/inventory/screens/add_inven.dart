import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../core/utlis/widgets/fields/searchableDropdown.dart';
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
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  final _uomController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _selectedItemName;
  String? _selectedCategoryName;
  String? _selectedSubcategoryName;

  String? _selectedItemId;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;

  List<Subcategory> _filteredSubcategories = [];
  List<InventoryItem> _allItems = [];
  List<Category> _allCategories = [];

  @override
  void dispose() {
    _quantityController.dispose();
    _minStockController.dispose();
    _uomController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  // ---------------- Item Selection ----------------
  Future<void> _onItemSelected(String itemName) async {
    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId == null) return;

    // Check if item exists
    InventoryItem? existingItem;
    try {
      existingItem = _allItems.firstWhere(
            (item) => item.name.toLowerCase() == itemName.toLowerCase(),
      );
    } catch (e) {
      existingItem = null;
    }

    if (existingItem != null) {
      // Existing item selected
      setState(() {
        _selectedItemName = itemName;
        _selectedItemId = existingItem!.id;
      });
    } else {
      // New item - will be created on submit
      setState(() {
        _selectedItemName = itemName;
        _selectedItemId = null;
      });
    }
  }

  // ---------------- Category Selection ----------------
  Future<void> _onCategorySelected(String categoryName) async {
    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId == null) return;

    // Check if category exists
    Category? existingCategory;
    try {
      existingCategory = _allCategories.firstWhere(
            (cat) => cat.name.toLowerCase() == categoryName.toLowerCase(),
      );
    } catch (e) {
      existingCategory = null;
    }

    if (existingCategory != null) {
      // Existing category
      setState(() {
        _selectedCategoryName = categoryName;
        _selectedCategoryId = existingCategory!.id;
        _selectedSubcategoryName = null;
        _selectedSubcategoryId = null;
        _filteredSubcategories = [];
      });

      // Load subcategories
      try {
        final subcategories = await ref
            .read(subcategoriesProvider((siteId: siteId, categoryId: existingCategory.id)).future);
        if (mounted) {
          setState(() {
            _filteredSubcategories = subcategories;
          });
        }
      } catch (e) {
        debugPrint('Error loading subcategories: $e');
      }
    } else {
      // New category - create it
      try {
        _showLoadingSnackBar('Creating category...');

        final newCategory = await ref.read(createCategoryProvider((
        siteId: siteId,
        name: categoryName,
        )).future);

        setState(() {
          _selectedCategoryName = categoryName;
          _selectedCategoryId = newCategory.id;
          _selectedSubcategoryName = null;
          _selectedSubcategoryId = null;
          _filteredSubcategories = [];
        });

        // Refresh categories list
        ref.invalidate(categoriesProvider(siteId));

        _hideLoadingSnackBar();
        _showSuccessSnackBar('Category created successfully!');
      } catch (e) {
        _hideLoadingSnackBar();
        _showErrorSnackBar('Failed to create category: ${e.toString()}');
      }
    }
  }

  // ---------------- Subcategory Selection ----------------
  Future<void> _onSubcategorySelected(String subcategoryName) async {
    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId == null || _selectedCategoryId == null) return;

    // Check if subcategory exists
    Subcategory? existingSubcategory;
    try {
      existingSubcategory = _filteredSubcategories.firstWhere(
            (subcat) => subcat.name.toLowerCase() == subcategoryName.toLowerCase(),
      );
    } catch (e) {
      existingSubcategory = null;
    }

    if (existingSubcategory != null) {
      // Existing subcategory
      setState(() {
        _selectedSubcategoryName = subcategoryName;
        _selectedSubcategoryId = existingSubcategory!.id;
      });
    } else {
      // New subcategory - create it
      try {
        _showLoadingSnackBar('Creating subcategory...');

        final newSubcategory = await ref.read(createSubcategoryProvider((
        siteId: siteId,
        name: subcategoryName,
        categoryId: _selectedCategoryId!,
        )).future);

        setState(() {
          _selectedSubcategoryName = subcategoryName;
          _selectedSubcategoryId = newSubcategory.id;
        });

        // Refresh subcategories list
        ref.invalidate(subcategoriesProvider((siteId: siteId, categoryId: _selectedCategoryId!)));

        _hideLoadingSnackBar();
        _showSuccessSnackBar('Subcategory created successfully!');
      } catch (e) {
        _hideLoadingSnackBar();
        _showErrorSnackBar('Failed to create subcategory: ${e.toString()}');
      }
    }
  }

  // ---------------- Submit Form ----------------
  Future<void> _submitForm() async {
    final siteId = ref.read(selectedSiteIdProvider);
    if (siteId == null) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedItemName == null || _selectedItemName!.trim().isEmpty) {
      _showErrorSnackBar('Please select or create an item');
      return;
    }
    if (_selectedCategoryId == null) {
      _showErrorSnackBar('Please select or create a category');
      return;
    }
    if (_selectedSubcategoryId == null) {
      _showErrorSnackBar('Please select or create a subcategory');
      return;
    }

    try {
      _showLoadingSnackBar('Creating inventory...');

      String finalItemId = _selectedItemId ?? '';

      // Create new item if needed
      if (finalItemId.isEmpty) {
        final newItem = await ref.read(createItemProvider((
        siteId: siteId,
        name: _selectedItemName!,
        categoryId: _selectedCategoryId!,
        subcategoryId: _selectedSubcategoryId!,
        )).future);

        finalItemId = newItem.id;
        ref.invalidate(itemsProvider((siteId: siteId)));
      }

      // Add inventory stock
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

      _hideLoadingSnackBar();
      _showSuccessSnackBar('Inventory created successfully!');

      // Reset form
      _formKey.currentState!.reset();
      _quantityController.clear();
      _minStockController.clear();
      _uomController.clear();
      _remarksController.clear();

      setState(() {
        _selectedItemName = null;
        _selectedCategoryName = null;
        _selectedSubcategoryName = null;
        _selectedItemId = null;
        _selectedCategoryId = null;
        _selectedSubcategoryId = null;
        _filteredSubcategories = [];
      });
    } catch (e) {
      _hideLoadingSnackBar();
      _showErrorSnackBar('Failed to create inventory: ${e.toString()}');
    }
  }

  // ---------------- Snackbar Helpers ----------------
  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );
  }

  void _hideLoadingSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
              _buildItemSearchableDropdown(itemsAsync),
              const SizedBox(height: 16),
              _buildCategorySearchableDropdown(categoriesAsync),
              const SizedBox(height: 16),
              _buildSubcategorySearchableDropdown(),
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
                child: const Text('Add Inventory Stock', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Searchable Dropdown Widgets ----------------
  Widget _buildItemSearchableDropdown(AsyncValue<List<InventoryItem>> itemsAsync) {
    final items = itemsAsync.value ?? const <InventoryItem>[];
    final isLoading = itemsAsync.isLoading;

    if (items.isNotEmpty) {
      _allItems = items;
    }

    final itemNames = _allItems.map((item) => item.name).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF124559),
          ),
        ),
        const SizedBox(height: 8),

        IgnorePointer(
          ignoring: isLoading,
          child: Opacity(
            opacity: isLoading ? 0.6 : 1,
            child: SearchableDropdown(
              data: itemNames,
              value: _selectedItemName,
              placeholder: isLoading
                  ? 'Loading items...'
                  : 'Search or create item...',
              onSelect: _onItemSelected,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySearchableDropdown(AsyncValue<List<Category>> categoriesAsync) {
    final categories = categoriesAsync.value ?? const <Category>[];
    final isLoading = categoriesAsync.isLoading;

    if (categories.isNotEmpty) {
      _allCategories = categories;
    }

    final categoryNames = _allCategories.map((cat) => cat.name).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF124559),
          ),
        ),
        const SizedBox(height: 8),

        IgnorePointer(
          ignoring: isLoading,
          child: Opacity(
            opacity: isLoading ? 0.6 : 1,
            child: SearchableDropdown(
              data: categoryNames,
              value: _selectedCategoryName,
              placeholder: isLoading
                  ? 'Loading categories...'
                  : 'Search or create category...',
              onSelect: _onCategorySelected,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubcategorySearchableDropdown() {
    if (_selectedCategoryId == null) {
      return const Text('Select a category first', style: TextStyle(color: Colors.grey));
    }

    final subcategoryNames = _filteredSubcategories.map((subcat) => subcat.name).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subcategory *',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF124559)),
        ),
        const SizedBox(height: 8),
        SearchableDropdown(
          data: subcategoryNames,
          value: _selectedSubcategoryName,
          placeholder: "Search or create subcategory...",
          onSelect: _onSubcategorySelected,
        ),
      ],
    );
  }

  // ---------------- Other Fields ----------------
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