// lib/screens/edit_material_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/fields/custom_textField.dart';
import 'package:untitled2/core/utlis/widgets/file_upload.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';

import '../../../../../../core/utlis/widgets/fields/searchableDropdown.dart';
import '../../../rate/data/rateApi.dart';
import '../../models/data/eqipment_provider.dart';
import '../../models/data/piping_provider.dart';

class EditMaterialScreen extends ConsumerStatefulWidget {
  final dynamic material;
  final String category; // 'piping' or 'equipment'
  final String materialId;
  final String? siteId;
  final String? teamId;

  const EditMaterialScreen({
    Key? key,
    required this.material,
    required this.category,
    required this.materialId,
    this.siteId,
    this.teamId,
  }) : super(key: key);

  @override
  ConsumerState<EditMaterialScreen> createState() => _EditMaterialScreenState();
}

class _EditMaterialScreenState extends ConsumerState<EditMaterialScreen> {
  late final GlobalKey<FormState> _formKey;
  late Map<String, dynamic> _formData;
  bool _isLoading = false;
  late final ImagePicker _imagePicker;

// Add in _EditMaterialScreenState class
  List<String> _allUOM = [];
  bool _isLoadingUOM = false;

  // Controllers for the main fields
  final _materialNameController = TextEditingController();
  final _uomController = TextEditingController();
  final _qtyController = TextEditingController();
  final _sizeController = TextEditingController();
  final _mocController = TextEditingController();
  final _floorController = TextEditingController();

// Call this in initState
  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _formData = _initializeFormData();
    _imagePicker = ImagePicker();
    _initializeControllers();
    _fetchUOM(); // Fetch UOM on init
  }

// Add method to fetch UOM
  Future<void> _fetchUOM() async {
  // Already loaded

    setState(() => _isLoadingUOM = true);
    try {
      final uomList = await RateApiClient().getRateUOM();
      setState(() {
        _allUOM = uomList.map<String>((item) => item['name'].toString()).toList();
      });
    } catch (e) {
      print('Error fetching UOM: $e');
    } finally {
      setState(() => _isLoadingUOM = false);
    }
  }


  Map<String, dynamic> _initializeFormData() {
    final material = widget.material;

    return {
      'materialName': _getFieldValue(material, 'materialName'),
      'qty': _getFieldValue(material, 'qty') ?? '0',
      'uom': _getFieldValue(material, 'uom'),
      'size': _getFieldValue(material, 'size'),
      'moc': _getFieldValue(material, 'moc'),
      'floor': _getFieldValue(material, 'floor'),
    };
  }

  void _initializeControllers() {
    _materialNameController.text = _formData['materialName']?.toString() ?? '';

    // Handle UOM - check if it's already in the list, if not add it
    final currentUOM = _formData['uom']?.toString() ?? '';
    _uomController.text = currentUOM;

    // If current UOM is not empty and not in the list, add it
    if (currentUOM.isNotEmpty && !_allUOM.contains(currentUOM)) {
      _allUOM.add(currentUOM);
    }

    _qtyController.text = _formData['qty']?.toString() ?? '0';
    _sizeController.text = _formData['size']?.toString() ?? '';
    _mocController.text = _formData['moc']?.toString() ?? '';
    _floorController.text = _formData['floor']?.toString() ?? '';
  }

  String? _getFieldValue(dynamic material, String field) {
    try {
      if (material == null) return null;

      if (material is Map<String, dynamic>) {
        return material[field]?.toString();
      } else {
        final value = _getProperty(material, field);
        return value?.toString();
      }
    } catch (e) {
      return null;
    }
  }

  dynamic _getProperty(dynamic obj, String property) {
    try {
      if (obj is Map) {
        return obj[property];
      }

      switch (property) {
        case 'materialName':
          return obj.materialName;
        case 'qty':
          return obj.qty;
        case 'uom':
          return obj.uom;
        case 'size':
          return obj.size;
        case 'moc':
          return obj.moc;
        case 'floor':
          return obj.floor;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      final t = v.trim();
      if (t.isEmpty) return 0.0;
      return double.tryParse(t) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _saveMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Update form data from controllers
    _formData = {
      'materialName': _materialNameController.text.trim(),
      'qty': _toDouble(_qtyController.text),
      'uom': _uomController.text.trim(),
      'size': _sizeController.text.trim(),
      'moc': _mocController.text.trim(),
      'floor': _floorController.text.trim(),
    };

    try {
      if (widget.category == 'piping') {
        final notifier = ref.read(pipingMaterialsProvider.notifier);
        notifier.updatePipingMaterialField(
          widget.materialId,
          _formData,
        );
      } else {
        final notifier = ref.read(equipmentMaterialsProvider.notifier);
        notifier.updateEquipmentMaterialField(
          widget.materialId,
          _formData,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.category == 'piping' ? 'Piping' : 'Equipment'} material updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update material: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _formData['image'] = pickedFile.path;
      });
    }
  }

  void _removeImage() {
    if (mounted) {
      setState(() {
        _formData['image'] = '';
      });
    }
  }

  Widget _buildImageSection() {
    final imageUrl = _formData['image']?.toString() ?? '';
    final hasImage = imageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Material Image',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (hasImage)
          Column(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: imageUrl.startsWith('http')
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        ),
                  )
                      : Image.file(
                    File(imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      label: const Text('Change Image', style: TextStyle(color: Colors.blue)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Remove', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          UploadBox(
            title: 'Upload Image',
            subtitle: 'Supported formats: JPG, PNG',
            buttonText: 'Choose Image',
            onPressed: _pickImage,
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPiping = widget.category == 'piping';

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(
        title: 'Edit ${isPiping ? 'Piping' : 'Equipment'} Material',
      ),
      body: CornerClippedScreenSimple(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Material Name Field
                CustomTextField(
                  controller: _materialNameController,
                  label: "Material Name",
                  TextSize: 18,
                  isRequired: true,
                  hint: "Enter material name",
                ),
                const SizedBox(height: 20),



                // UOM Field
                _buildUOMField(),
                const SizedBox(height: 20),


                // Image Section
                _buildImageSection(),

                // Action Buttons
                _buildActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUOMField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unit of Measurement',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        if (_isLoadingUOM)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Loading UOM...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          )
        else if (_allUOM.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'No UOM available',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  onPressed: _fetchUOM,
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                ),
              ],
            ),
          )
        else
          SearchableDropdown(
            data: _allUOM,
            onSelect: (value) {
              setState(() {
                _uomController.text = value;
              });
            },
            placeholder: "Select UOM",
            value: _uomController.text,
            containerDecoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            inputDecoration: InputDecoration(
              hintText: "Select UOM",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ),
            textStyle: TextStyle(
              fontSize: 16,
              color: _uomController.text.isEmpty
                  ? Colors.grey.shade600
                  : Colors.black87,
            ),
          ),

        // Validation message
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveMaterial,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              'Save Changes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Back',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Navigation extension for easy navigation
extension EditMaterialNavigation on BuildContext {
  void navigateToEditMaterial({
    required dynamic material,
    required String category,
    required String materialId,
    String? siteId,
    String? teamId,
  }) {
    Navigator.push(
      this,
      MaterialPageRoute(
        builder: (context) => EditMaterialScreen(
          material: material,
          category: category,
          materialId: materialId,
          siteId: siteId,
          teamId: teamId,
        ),
      ),
    );
  }
}