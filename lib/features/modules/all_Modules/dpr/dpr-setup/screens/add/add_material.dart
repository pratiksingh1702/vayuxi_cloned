// lib/screens/persist_dpr_screen.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/models/dprModel.dart';
import 'package:untitled2/features/modules/all_Modules/rate/data/rateApi.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../../../core/utlis/colors/colors.dart';
import '../../../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../rate/data/rate_provider.dart';
import '../../../../site_Details/providers/site_current_provider.dart';
import '../../../providers/dpr_material_provider.dart';

class PersistDPRScreen extends ConsumerStatefulWidget {
  final String? siteId;
  final String? teamId;
  final String? editDprId;

  final String? insulationId;
  final String? designation;
  final String? workId;
  final String? type;
  final DprModel dpr;

  const PersistDPRScreen({
    super.key,
    this.siteId,
    this.teamId,
    this.editDprId,

    this.insulationId,
    this.designation,
    this.workId,
    required this.dpr,
    this.type,
  });

  @override
  ConsumerState<PersistDPRScreen> createState() => _PersistDPRScreenState();
}

class _PersistDPRScreenState extends ConsumerState<PersistDPRScreen> {
  final _formKey = GlobalKey<FormState>();
  final _materialNameController = TextEditingController();
  final _uomController = TextEditingController();

  String? _calculationCategory;
  String? _imagePath;
  List<String> _allUOM = [];
  String? _expandedCategory;
  late String _mechanicalId;


  // Calculation categories data
  final List<CalculationCategory> _calculationCategories = [
    CalculationCategory(
      id: "A",
      label: "Per Item",
      description: "Price per unit",
      fullDetails: CategoryDetails(
        title: "Per Item Calculation",
        formula: "Rate × Quantity",
        rateList: [
          RateItem(desc: "Structure Fabrication & Erection", uom: "kg", rate: "₹105"),
        ],
        howItWorks: [
          "Select the rate for the specific material",
          "Multiply rate by quantity of work done",
        ],
        example: "Example: 100 kg × ₹105 = ₹10,500",
      ),
    ),
    CalculationCategory(
      id: "B",
      label: "Per Item Measurement",
      description: "Price based on measurement",
      fullDetails: CategoryDetails(
        title: "Per Item Measurement Calculation",
        formula: "Rate × Measurement × Quantity",
        rateList: [
          RateItem(desc: "Pipe Erection", uom: "inch dia", rate: "₹50"),
        ],
        howItWorks: [
          "Multiply rate by measurement (e.g., diameter)",
          "Then multiply by quantity",
        ],
        example: "Example: 6 inch × ₹50 × 10 pipes = ₹3,000",
      ),
    ),
    CalculationCategory(
      id: "C",
      label: "Per Item Range",
      description: "Price based on range brackets",
      fullDetails: CategoryDetails(
        title: "Per Item Range Calculation",
        formula: "Bracket Rate × Quantity",
        rateList: [
          RateItem(desc: "Pump Erection", uom: "0–5 HP", rate: "₹1000"),
          RateItem(desc: "Pump Erection", uom: "6–10 HP", rate: "₹2000"),
          RateItem(desc: "Pump Erection", uom: "10+ HP", rate: "₹10000"),
        ],
        howItWorks: [
          "Select the appropriate rate bracket",
          "Multiply bracket rate by quantity",
        ],
        example: "Example: 8 HP Pump × ₹2,000 × 3 units = ₹6,000",
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _mechanicalId =   widget.dpr.id!;


    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() async {

    final uomList = await RateApiClient().getRateUOM();
    setState(() {
      _allUOM = uomList.map<String>((item) => item['name'].toString()).toList();
    });

    final siteId = ref.watch(selectedSiteIdProvider);
    final type = ref.read(typeProvider);
    ref.read(rateNotifierProvider.notifier).fetchRate(type!, siteId!);

    if (widget.editDprId != null && _mechanicalId
 != null) {
      ref.read(dprMaterialProvider.notifier).fetchMaterialById(
        mechanicalId: _mechanicalId
!,
        editDprId: widget.editDprId!,
      );
    }
  }

  @override
  void dispose() {
    _materialNameController.dispose();
    _uomController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_calculationCategory == null || _calculationCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a calculation category"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final formData = FormData();
      final type = ref.read(typeProvider);

      // Add text fields
      if (type == "insulation_work") {
        formData.fields.add(MapEntry('name', _materialNameController.text));
      } else {
        formData.fields.add(MapEntry('materialName', _materialNameController.text));
      }

      formData.fields.add(MapEntry('uom', _extractUOMValue(_uomController.text)));
      formData.fields.add(MapEntry('calculationCategory', _calculationCategory ?? ''));

      // Add image if exists
      if (_imagePath != null && !_imagePath!.startsWith('http')) {
        formData.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(_imagePath!),
        ));
      } else if (_imagePath != null) {
        formData.fields.add(MapEntry('file', _imagePath!));
      } else {
        formData.fields.add(MapEntry('file', ''));
      }

      // Add ID if editing
      if (widget.editDprId != null) {
        formData.fields.add(MapEntry('_id', widget.editDprId!));
      }

      // Submit based on type and mode
      if (widget.editDprId != null) {
        // Update
        if (type == "insulation_work") {
          // Call insulation update
        } else {
          await ref.read(dprMaterialProvider.notifier).updateMaterial(
            data: formData,
            mechanicalId: _mechanicalId
!,
          );
        }
      } else {
        // Create
        if (type == "insulation_work") {
          // Call insulation create
        } else {
          await ref.read(dprMaterialProvider.notifier).postMaterial(
            data: formData,
            mechanicalId: _mechanicalId
!,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editDprId != null
                ? 'Material updated successfully'
                : 'Material created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _extractUOMValue(String uomString) {
    final match = RegExp(r'\((.*?)\)').firstMatch(uomString);
    return match?.group(1) ?? uomString;
  }

  void _openUOMBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return UOMBottomSheet(
          items: _allUOM,
          selected: _uomController.text,
          onSelected: (value) {
            setState(() {
              _uomController.text = value;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _toggleKnowMore(String categoryId) {
    setState(() {
      _expandedCategory = _expandedCategory == categoryId ? null : categoryId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dprMaterialProvider);

    // Pre-fill form when data is loaded
    if (state.materialData != null && _materialNameController.text.isEmpty) {
      final material = state.materialData!;
      _materialNameController.text = material['materialName'] ?? material['name'] ?? '';
      _uomController.text = material['uom'] ?? '';
      _calculationCategory = material['calculationCategory'] ?? '';
      _imagePath = material['image'] is List
          ? material['image']?.first
          : material['image'] ?? '';
    }

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(
        title: widget.editDprId != null ? 'Edit Material' : 'Add Material',
      ),
      body: CornerClippedScreenSimple(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Material Name Field
                _buildMaterialNameField(),
                const SizedBox(height: 20),

                // UOM Field
                _buildUOMField(),
                const SizedBox(height: 20),

                // Calculation Category Section
                _buildCalculationCategorySection(),
                const SizedBox(height: 20),

                // Image Upload
                _buildImageUpload(),
                const SizedBox(height: 30),

                // Buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Material Name',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _materialNameController,
          keyboardType: TextInputType.text,
          label: "Enter material name",
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Material name is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUOMField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unit of Measurement',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _openUOMBottomSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _uomController.text.isEmpty
                        ? "Select UOM"
                        : _uomController.text,
                    style: TextStyle(
                      color: _uomController.text.isEmpty
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        if (_uomController.text.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              "UOM is required",
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildCalculationCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How is Price Determined?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _calculationCategories.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final category = _calculationCategories[index];
            final isSelected = _calculationCategory == category.id;
            final isExpanded = _expandedCategory == category.id;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF197278),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Radio button row
                  InkWell(
                    onTap: () {
                      setState(() {
                        _calculationCategory = category.id;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          // Radio button
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF1B6DCE)
                                    : const Color(0xFFD1D5DB),
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                              child: Container(
                                height: 8,
                                width: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF1B6DCE),
                                ),
                              ),
                            )
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // Category label
                          Expanded(
                            child: Text(
                              category.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // Know More button
                          InkWell(
                            onTap: () {
                              _toggleKnowMore(category.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B6DCE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isExpanded ? "Show Less" : "Know More",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expanded details
                  if (isExpanded)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 15)
                          .copyWith(bottom: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            category.fullDetails.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,

                            ),
                          ),

                          // Formula
                          Text(
                            category.fullDetails.formula,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1B6DCE),

                            ),
                          ),

                          // Rate list
                          ...category.fullDetails.rateList.map((rateItem) =>
                              Text(
                                "${rateItem.desc} → ${rateItem.uom} → ${rateItem.rate}",
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              )),

                          // How It Works
                          const SizedBox(height: 8),
                          const Text(
                            "How It Works",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...category.fullDetails.howItWorks.map((rule) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  "• $rule",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                          ),

                          // Example
                          const SizedBox(height: 6),
                          Text(
                            category.fullDetails.example,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        // Validation error
        if (_calculationCategory == null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Calculation category is required",
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        UploadBox(
          title: 'Upload Image',
          subtitle: 'Supported formats: JPG, PNG',
          buttonText: 'Choose Image',

          onPressed: () async {
            final helper = ImageUploadHelper(context);

            final file = await helper.pickAndCropImage(
              enableCropping: true,
              cropTitle: 'Crop Material Image',
            );

            if (file != null) {
              setState(() {
                _imagePath = file.path;
              });
            }
          },

          previewWidget: _imagePath != null && _imagePath!.isNotEmpty
              ? UploadBoxPreview(
            file: File(_imagePath!),
            isImage: true,

            onRemove: () {
              setState(() {
                _imagePath = null;
              });
            },

            onEdit: () async {
              final helper = ImageUploadHelper(context);

              final file = await helper.pickAndCropImage(
                enableCropping: true,
                cropTitle: 'Edit Image',
              );

              if (file != null) {
                setState(() {
                  _imagePath = file.path;
                });
              }
            },
          )
              : null,
        ),
      ],
    );
  }


  Widget _buildActionButtons() {
    final state = ref.watch(dprMaterialProvider);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: state.isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              'Save & Submit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.blue),
            ),
            child: const Text(
              'Back',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class UOMBottomSheet extends StatefulWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelected;

  const UOMBottomSheet({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<UOMBottomSheet> createState() => _UOMBottomSheetState();
}

class _UOMBottomSheetState extends State<UOMBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> filteredList;

  @override
  void initState() {
    super.initState();
    filteredList = widget.items;
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        filteredList = widget.items
            .where((item) => item.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Search Input
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search UOM...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 12),

              // List of all items
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    final isSelected = item == widget.selected;

                    return ListTile(
                      title: Text(item),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                      onTap: () => widget.onSelected(item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Data Models
class CalculationCategory {
  final String id;
  final String label;
  final String description;
  final CategoryDetails fullDetails;

  CalculationCategory({
    required this.id,
    required this.label,
    required this.description,
    required this.fullDetails,
  });
}

class CategoryDetails {
  final String title;
  final String formula;
  final List<RateItem> rateList;
  final List<String> howItWorks;
  final String example;

  CategoryDetails({
    required this.title,
    required this.formula,
    required this.rateList,
    required this.howItWorks,
    required this.example,
  });
}

class RateItem {
  final String desc;
  final String uom;
  final String rate;

  RateItem({
    required this.desc,
    required this.uom,
    required this.rate,
  });
}