import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../../../../../core/local/isar_db.dart';
import '../../../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../site_Details/providers/site_current_provider.dart';
import '../../../models/floorModel.dart';
import '../../../offline/mech/repo/rate_Repo.dart';
import '../../../providers/floorProvider.dart';
import '../../../providers/rate_variant_provider.dart';

class AddFloorPage extends ConsumerStatefulWidget {
  final Floor? floor;
  const AddFloorPage({super.key, this.floor});

  @override
  ConsumerState<AddFloorPage> createState() => _AddFloorPageState();
}

class _AddFloorPageState extends ConsumerState<AddFloorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _existingimage; // backend image
  File? _selectedImage;      // newly picked image
  bool _isSubmitting = false;
  bool _isApplied = false;

  @override
  void initState() {
    super.initState();

    final floor = widget.floor;
    if (floor != null) {
      _nameController.text = floor.name;

      // Handle image (URL or local)
      if (floor.image != null && floor.image!.isNotEmpty) {
        _existingimage = floor.image!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final helper = ImageUploadHelper(context);

    final file = await helper.pickAndCropImage(
      enableCropping: true,
      cropTitle: 'Crop Floor Image',
    );

    if (file != null) {
      setState(() {
        _selectedImage = file;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final siteID = ref.read(selectedSiteIdProvider)!;
      final name = _nameController.text.trim();

      if (widget.floor == null) {
        // ================= CREATE =================
        if (_selectedImage == null) {
          throw 'Image required';
        }
        final rateFileMeta = ref.read(rateFileMetaProvider(siteID));





        final rateUploadId = rateFileMeta['rateFileId'];
        final existingNames =
        ref.read(floorListDetectedProvider(siteID));
        // Inside CREATE block:
        final existingFloors = ref.read(floorWithImagesProvider(siteID));

        await ref.read(floorProvider.notifier).create(
          name: name,
          rateUploadId: rateUploadId,
          existingFloorNames: existingNames,
          existingFloorsWithImages: existingFloors,
          image: _selectedImage!,
      // 🔥
        );
        final repo = RateRepository(AppIsarDB.isar);
        await repo.syncRateFile(siteID);

        ref.invalidate(rateFileAnalysisProvider(siteID));
      } else {
        // ================= UPDATE =================
        final siteID = ref.read(selectedSiteIdProvider)!;
        final rateFileMeta = ref.read(rateFileMetaProvider(siteID));
        final rateUploadId = rateFileMeta['rateFileId'];

        final existingNames =
        ref.read(floorListDetectedProvider(siteID));

        final existingFloors =
        ref.read(floorWithImagesProvider(siteID));

        final updatedNames = existingNames.map((e) {
          return e == widget.floor!.name ? name : e;
        }).toList();

        final updatedFloors = existingFloors.map((e) {
          if (e.name == widget.floor!.name) {
            return Floor(
              id: e.id,
              name: name,
              image: _selectedImage != null
                  ? _selectedImage!.path
             : e.image,
              isApplied: false, isDeleted: false, createdAt:DateTime.now(),updatedAt:DateTime.now(),
            );
          }
          return e;
        }).toList();

        await ref.read(floorProvider.notifier).create(
          name: "",
          rateUploadId: rateUploadId,
          existingFloorNames: updatedNames,
          existingFloorsWithImages: updatedFloors,
          image: null,
        );

        ref.invalidate(rateFileAnalysisProvider(siteID));
      }

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(
        title: widget.floor == null ? "Add Floor" : "Edit Floor",
      ),
      backgroundColor: AppColors.lightBlue,
      body: CornerClippedScreenSimple(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name Field
                CustomTextField(
                  label: 'Floor Name',
                  hint: 'Enter floor name (e.g., Ground, First, Terrace)',
                  isRequired: true,
                  TextSize: 16,
                  controller: _nameController,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 24),
                _buildIsAppliedField(),

                // Image Upload Section
                UploadBox(
                  title: 'Floor Image',
                  subtitle: 'Tap to change image',
                  buttonText: 'Change Image',
                  onPressed: _pickImage,
                  previewWidget: (_selectedImage != null || _existingimage != null)
                      ? UploadBoxPreview(
                    file: _selectedImage,
                    source: _existingimage,
                    isImage: true,
                    onRemove: () {
                      setState(() {
                        _selectedImage = null;
                        _existingimage = null;
                      });
                    },
                    onEdit: _pickImage,
                  )
                      : null,
                ),

                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(widget.floor == null
                          ? 'Adding Floor...'
                          : 'Updating Floor...'),
                    ],
                  )
                      : Text(
                    widget.floor == null ? 'Save Floor' : 'Update Floor',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel Button
                OutlinedButton(
                  onPressed: _isSubmitting ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
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
                      ? 'This floor will be available for ALL sites in your company'
                      : 'This floor will only be available for the current site',
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
}