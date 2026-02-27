// lib/screens/persist_dpr_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:untitled2/features/modules/all_Modules/rate/data/rateApi.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../../../core/utlis/colors/colors.dart';
import '../../../../../../../core/utlis/common_functions.dart';
import '../../../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../../../core/utlis/widgets/fields/searchableDropdown.dart';
import '../../../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../rate/data/rate_provider.dart';
import '../../../../site_Details/providers/site_current_provider.dart';
import '../../../models/data/eqipment_provider.dart';
import '../../../models/data/piping_provider.dart';
import '../../../models/equipmentModel.dart';
import '../../../models/pipingModel.dart';
import '../../../models/rate_file_models.dart';
import '../../../providers/dprService.dart';
import '../../../providers/material_service.dart';
import '../../../providers/rate_variant_provider.dart';
import '../../../providers/service/rate_upload_material_dpr.dart';


class PersistDPRScreen extends ConsumerStatefulWidget {
  final String? editMaterialId;
  final String? designation;
  final PipingItem? pipingMaterial;
  final EquipmentItem? equipmentMaterial;
  final bool isDpr;
  final String dprId;
  final String? siteId;
  final String? teamId;
  final bool isRateUploadMaterial;
  final String? rateUploadId;


  const PersistDPRScreen({
    super.key,
    this.editMaterialId,
    this.designation,
    this.pipingMaterial,
    this.equipmentMaterial,
    this.isDpr=false,
    this.dprId="",
    this.siteId,
    this.teamId,
    this.isRateUploadMaterial = true,
    this.rateUploadId,
  });

  @override
  ConsumerState<PersistDPRScreen> createState() => _PersistDPRScreenState();
}

class _PersistDPRScreenState extends ConsumerState<PersistDPRScreen> {
  final _formKey = GlobalKey<FormState>();
  final _materialNameController = TextEditingController();
  final _uomController = TextEditingController();
  String? siteId = '';
  List<DynamicField> _dynamicFields = [];

  String? _calculationCategory;
  String? _imagePath;
  List<String> _allUOM = [];
  String? _expandedCategory;

  // Fields from documentation
  String? _selectedDesignation;
  bool _isApplied = false;

  // Calculation categories
  final List<CalculationCategory> _calculationCategories = [
    CalculationCategory(
      id: "A",
      label: "Per Item (Fixed Rate)",
      description: "Quantity × Fixed Rate",
      fullDetails: CategoryDetails(
        title: "Option A: Quantity × Rate",
        formula: "Total Cost = Quantity × Rate",
        rateList: [
          RateItem(
            desc: "Structure Fabrication & Erection",
            uom: "kg",
            rate: "₹105",
          ),
        ],
        howItWorks: [
          "Every unit has a fixed cost",
          "Total = Quantity × Rate",
        ],
        example: "20 kg × ₹105 = ₹2100",
      ),
    ),

    CalculationCategory(
      id: "B",
      label: "Per Item × Measurement",
      description: "Qty × Size × Rate",
      fullDetails: CategoryDetails(
        title: "Option B: Qty × Size × Rate",
        formula: "Total = Qty × Size × Rate",
        rateList: [
          RateItem(
            desc: "Pipe Erection",
            uom: "inch dia",
            rate: "₹50",
          ),
        ],
        howItWorks: [
          "Cost depends on pipe length (Qty)",
          "Cost depends on pipe size (inch dia)",
          "Formula: Qty × Size × Rate",
        ],
        example: "10 × 2 × 50 = ₹1000",
      ),
    ),

    CalculationCategory(
      id: "C",
      label: "Per Item × Rate by Range",
      description: "Rate varies by range",
      fullDetails: CategoryDetails(
        title: "Option C: Rate × Range",
        formula: "Total = Qty × Selected Rate",
        rateList: [
          RateItem(desc: "Pump Erection (0–5 HP)", uom: "HP", rate: "₹1000"),
          RateItem(desc: "Pump Erection (6–10 HP)", uom: "HP", rate: "₹2000"),
          RateItem(desc: "Pump Erection (10+ HP)", uom: "HP", rate: "₹10000"),
        ],
        howItWorks: [
          "Rate depends on HP bracket",
          "Total = Qty × Rate",
        ],
        example: "4 Pumps (7 HP) → 2000 × 4 = ₹8000",
      ),
    ),
  ];


  @override
  void initState() {
    super.initState();

    // Initialize designation
    _selectedDesignation = widget.designation ?? 'piping';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    // Fetch UOM list
    final uomList = await RateApiClient().getRateUOM();
    setState(() {
      _allUOM = uomList.map<String>((item) => item['name'].toString()).toList();
    });

    // Get site ID from provider
    siteId = ref.read(selectedSiteIdProvider);

    // Load material data if editing or if material data is provided
    if (widget.pipingMaterial != null) {
      _prefillFromPiping(widget.pipingMaterial!);
    } else if (widget.equipmentMaterial != null) {
      _prefillFromEquipment(widget.equipmentMaterial!);
    }

  }



  void _prefillFromPiping(PipingItem material) {
    _materialNameController.text = material.materialName;
    _uomController.text = material.uom;
    _calculationCategory = material.calculationCategory;
    _selectedDesignation = 'piping';
    _imagePath = material.image;
    _dynamicFields = material.dynamicFields
        .map((e) => e.copyWith())
        .toList();

  }

  void _prefillFromEquipment(EquipmentItem material) {
    _materialNameController.text = material.materialName;
    _uomController.text = material.uom;
    _calculationCategory = material.calculationCategory;
    _selectedDesignation = 'equipment';
    _imagePath = material.image;


  }


  @override
  void dispose() {
    _materialNameController.dispose();
    _uomController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if(widget.isDpr){
      _handleDprMaterialAdd();
      return;
    }

    if (widget.isRateUploadMaterial != true) {
      _showError("This screen supports only Rate Upload materials.");
      return;
    }

    if (_calculationCategory == null || _calculationCategory!.isEmpty) {
      _showError("Please select a calculation category");
      return;
    }

    if (_selectedDesignation == null || _selectedDesignation!.isEmpty) {
      _showError("Please select material designation");
      return;
    }

    /// 🔥 STEP 1 — Resolve RateUploadId (Clean Logic)

    String? rateUploadId;

    // Priority 1 → If widget has it
    if (widget.rateUploadId != null &&
        widget.rateUploadId!.trim().isNotEmpty) {
      rateUploadId = widget.rateUploadId!;
    }
    // Priority 2 → Fallback to provider
    else {
      final siteID = ref.read(selectedSiteIdProvider);

      if (siteID == null || siteID.isEmpty) {
        _showError("Site ID missing");
        return;
      }

      final rateFileMeta = ref.read(rateFileMetaProvider(siteID));

      if (rateFileMeta == null ||
          rateFileMeta['rateFileId'] == null ||
          rateFileMeta['rateFileId'].toString().isEmpty) {
        _showError("Rate Upload ID not found");
        return;
      }

      rateUploadId = rateFileMeta['rateFileId'].toString();
    }

    /// 🔥 STEP 2 — Safety Check
    if (rateUploadId == null || rateUploadId.isEmpty) {
      _showError("Rate Upload ID resolution failed");
      return;
    }

    try {
      File? imageFile;

      if (_imagePath != null &&
          _imagePath!.isNotEmpty &&
          !_imagePath!.startsWith('http')) {
        imageFile = File(_imagePath!);
      }

      final isEdit =
          widget.editMaterialId != null &&
              widget.editMaterialId!.isNotEmpty;

      final formData = FormData.fromMap({
        "materialName": _materialNameController.text.trim(),
        "uom": _uomController.text.trim(),
        "designation": _selectedDesignation,
        "calculationCategory": _calculationCategory,
        "isApplied": _isApplied,
        "dynamicFields":
        jsonEncode(_dynamicFields.map((e) => e.toJson()).toList()),
        if (imageFile != null)
          "image": await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
      });

      if (isEdit) {
        await RateUploadApi.updateLineItem(
          rateUploadId: rateUploadId,
          lineItemId: widget.editMaterialId!,
          data: formData,
        );
        _showSuccess("Material updated successfully");
      } else {
        await RateUploadApi.addLineItem(
          rateUploadId: rateUploadId,
          data: formData,
        );
        _showSuccess("Material added successfully");
      }

      /// 🔄 Refresh provider
      final siteID = ref.read(selectedSiteIdProvider);
      if (siteID != null) {
        ref.invalidate(rateFileAnalysisProvider(siteID));
      }

      if (mounted) Navigator.pop(context, true);

    } catch (e, st) {
      debugPrint("❌ Submit failed: $e");
      debugPrintStack(stackTrace: st);
      final msg = extractBackendError(e);
      _showError(msg);
    }
  }
  String _generateObjectId() {
    final seconds = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toRadixString(16)
        .padLeft(8, '0');

    final random = Random.secure();
    final randomPart = List.generate(10, (_) => random.nextInt(16))
        .map((e) => e.toRadixString(16))
        .join();

    final counter =
    random.nextInt(0xffffff).toRadixString(16).padLeft(6, '0');

    return seconds + randomPart + counter;
  }
  Future<void> _handleDprMaterialAdd() async {
    try {
      File? imageFile;

      if (_imagePath != null &&
          _imagePath!.isNotEmpty &&
          !_imagePath!.startsWith('http')) {
        imageFile = File(_imagePath!);
      }

      final formData = FormData.fromMap({
        "materialName": _materialNameController.text.trim(),
        "uom": _uomController.text.trim(),
        "designation": _selectedDesignation,
        "calculationCategory": _calculationCategory,
        "dynamicFields":
        jsonEncode(_dynamicFields.map((e) => e.toJson()).toList()),
        if (imageFile != null)
          "image": await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
      });
      final isNewDpr = widget.dprId.isEmpty;

      // 🔥 If NO DPR ID → local draft mode
      if (isNewDpr) {
        final newId = _generateObjectId();

        if (_selectedDesignation == "piping") {
          final newItem = PipingItem(
            id: newId,
            materialName: _materialNameController.text.trim(),
            uom: _uomController.text.trim(),
            designation: ["piping"],
            calculationCategory: _calculationCategory!,
            dynamicFields: _dynamicFields,
            image: _imagePath ?? "",
            qty: 0,
            length: 0,
            weight: 0,
            power: 0,
            diameter: 0,
            rmt: 0,
            remarks: "",
            rateFileId: null,
            rateVariantId: null, rawMaterialName: '', normalizedMaterialName: '', floor: '', elevation: '', actualRate: 0, rate: 0, moc: '', size: '', location: '', plant: '',
          );

          ref.read(pipingMaterialsProvider.notifier).addMaterial(newItem);
        }

        if (_selectedDesignation == "equipment") {
          final newItem = EquipmentItem(
            id: newId,
            materialName: _materialNameController.text.trim(),
            uom: _uomController.text.trim(),


            dynamicFields: _dynamicFields,
            image: _imagePath ?? "",
            qty: 0,
            length: 0,
            weight: 0,
            power: 0,
            diameter: 0,
            rmt: 0,
            remarks: "",

            rateFileId: null,
            rateVariantId: null, rawMaterialName: '', normalizedMaterialName: '', actualRate: 0, rate: 0, moc: '', size: '', location: '', plant: '', calculationCategory: '', designation: [],
          );

          ref.read(equipmentMaterialsProvider.notifier).addMaterial(newItem);
        }

        _showSuccess("Material added locally (Draft Mode)");
        if (mounted) Navigator.pop(context, true);
        return;
      }

      final response = await DprApi.addMechanicalMaterial(
        dprId: widget.dprId,
        formData: formData,
      );

      if (response["success"] != true) {
        _showError("Failed to add material");
        return;
      }
      final updatedDpr = response["data"]?["data"];

      if (updatedDpr == null) {
        _showError("Invalid response structure");
        return;
      }

      final List pipingList = updatedDpr["piping"] ?? [];
      final List equipmentList = updatedDpr["equipment"] ?? [];

      if (_selectedDesignation == "piping" && pipingList.isNotEmpty) {
        final last = pipingList.last;
        final newItem = PipingItem.fromJson(last);

        ref.read(pipingMaterialsProvider.notifier).addMaterial(newItem);
      }

      if (_selectedDesignation == "equipment" && equipmentList.isNotEmpty) {
        final last = equipmentList.last;
        final newItem = EquipmentItem.fromJson(last);

        ref.read(equipmentMaterialsProvider.notifier).addMaterial(newItem);
      }

      _showSuccess("Material added successfully");


      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      final msg = extractBackendError(e);
      _showError(msg);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
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
  Widget _buildDynamicFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Dynamic Fields",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        if (_dynamicFields.isEmpty)
          Text(
            "No dynamic fields added",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),

        const SizedBox(height: 10),

        ...List.generate(_dynamicFields.length, (i) {
          final f = _dynamicFields[i];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f.key,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() => _dynamicFields.removeAt(i));
                      },
                      child: const Icon(Icons.delete, color: Colors.red),
                    )
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    /// Label
                    Expanded(
                      child: TextFormField(
                        initialValue: f.label,
                        decoration: InputDecoration(
                          labelText: "Label",
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {
                            _dynamicFields[i] = f.copyWith(label: v);
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// Unit
                    Expanded(
                      child: TextFormField(
                        initialValue: f.unit,
                        decoration: InputDecoration(
                          labelText: "Unit",
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {
                            _dynamicFields[i] = f.copyWith(unit: v);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 6),

        /// ADD BUTTON
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add Field"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              setState(() {
                _dynamicFields.add(
                  DynamicField(
                    key: DateTime.now().millisecondsSinceEpoch.toString(),
                    label: "",
                    unit: "",
                    value: null,
                    displayText: "",
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(
        title: widget.editMaterialId != null ? 'Edit Material' : 'Add Material',
      ),
      body: CornerClippedScreenSimple(
        child: SingleChildScrollView(
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

                _buildDynamicFieldsSection(),
                const SizedBox(height: 20),


                // Material Designation Field
                _buildDesignationField(),
                const SizedBox(height: 20),

                // isApplied Toggle
                _buildIsAppliedField(),
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
          'Unit of Measurement (UOM)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        SearchableDropdown(
          data: _allUOM,
          value: _uomController.text,
          placeholder: "Search or type UOM (e.g., MTR, NOS, TON, KG, HP)",
          onSelect: (value) {
            setState(() {
              _uomController.text = value;
            });
          },
        ),

        if (_uomController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              "UOM is required",
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesignationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Material Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDesignation,
              isExpanded: true,
              hint: const Text('Select material type'),
              items: const [
                DropdownMenuItem(
                  value: 'piping',
                  child: Text('Piping Materials'),
                ),
                DropdownMenuItem(
                  value: 'equipment',
                  child: Text('Equipment Materials'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDesignation = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIsAppliedField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply to all sites in company',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isApplied
                      ? 'This material will be available for ALL sites in your company'
                      : 'This material will only be available for the current site',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isApplied,
            onChanged: (value) {
              setState(() {
                _isApplied = value;
              });
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calculation Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Determines how price is calculated for this material',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  category.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
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
                          const SizedBox(height: 8),

                          // Formula
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "Formula: ${category.fullDetails.formula}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1B6DCE),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Rate list examples
                          const Text(
                            "Example Materials:",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...category.fullDetails.rateList.map((rateItem) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  "• ${rateItem.desc} (${rateItem.uom}) - ${rateItem.rate}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                              )),

                          // How It Works
                          const SizedBox(height: 8),
                          const Text(
                            "How It Works:",
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
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              category.fullDetails.example,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
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
  void _toggleKnowMore(String categoryId) {
    setState(() {
      _expandedCategory = _expandedCategory == categoryId ? null : categoryId;
    });
  }

  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Material Image (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload image for easy identification',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),

        UploadBox(
          title: 'Upload Image',
          subtitle: 'Supported formats: JPG, PNG, Max 5MB',
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
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Save Material',
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
              'Cancel',
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