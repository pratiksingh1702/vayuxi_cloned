// lib/screens/persist_dpr_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/features/modules/all_Modules/rate/data/rateApi.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../../../core/utlis/colors/colors.dart';
import '../../../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../rate/data/rate_provider.dart';
import '../../../../site_Details/providers/site_current_provider.dart';
import '../../../providers/dpr_material_provider.dart';


class PersistDPRScreen extends ConsumerStatefulWidget {
  final String? siteId;
  final String? teamId;
  final String? editDprId;
  final String? mechanicalId;
  final String? insulationId;
  final String? designation;
  final String? workId;
  final String? type;

  const PersistDPRScreen({
    super.key,
    this.siteId,
    this.teamId,
    this.editDprId,
    this.mechanicalId,
    this.insulationId,
    this.designation,
    this.workId,
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

  @override
  void initState() {
    super.initState();

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

    if (widget.editDprId != null && widget.mechanicalId != null) {
      ref.read(dprMaterialProvider.notifier).fetchMaterialById(
        mechanicalId: widget.mechanicalId!,
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

    try {
      final formData = FormData();
      widget.type!=ref.read(typeProvider);

      // Add text fields
      if (widget.type == "insulation_work") {
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
        if (widget.type == "insulation_work") {
          // Call insulation update
        } else {
          await ref.read(dprMaterialProvider.notifier).updateMaterial(
            data: formData,
            mechanicalId: widget.mechanicalId!,
          );
        }
      } else {
        // Create
        if (widget.type == "insulation_work") {
          // Call insulation create
        } else {
          await ref.read(dprMaterialProvider.notifier).postMaterial(
            data: formData,
            mechanicalId: widget.mechanicalId!,
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
      body: state.isLoading
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


              // Image Upload
              _buildImageUpload(),
              const SizedBox(height: 30),

              // Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialNameField() {
    return CustomTextField(
      controller: _materialNameController,
      keyboardType: TextInputType.text, label: "Material Name",
      TextSize:18,

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




  Widget _buildImageUpload() {
    return UploadBox(
      title: 'Upload File',
      subtitle: 'Supported formats: JPG, PNG',
      buttonText: 'Choose File',
      onPressed: () {  },

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
                : Text(
              'Save & Submit',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
            child: Text(
              'Back',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.blue,
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
