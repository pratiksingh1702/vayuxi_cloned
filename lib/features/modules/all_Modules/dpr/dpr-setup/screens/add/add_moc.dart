// screens/add_moc_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import '../../../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../models/moc.dart';
import '../../../providers/mocProvider.dart';
import 'package:file_picker/file_picker.dart';

class AddMOCPage extends ConsumerStatefulWidget {
  final MOC? moc;
  const AddMOCPage({super.key,this.moc});

  @override
  ConsumerState<AddMOCPage> createState() => _AddMOCPageState();
}

class _AddMOCPageState extends ConsumerState<AddMOCPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _existingImageUrl; // backend image
  File? _selectedImage;      // newly picked image
  bool _isApplied = false;



  bool _isSubmitting = false;
  @override
  void initState() {
    super.initState();

    final moc = widget.moc;
    if (moc != null) {
      _nameController.text = moc.name;

      // Handle image (URL or local)
      if (moc.imageUrl != null && moc.imageUrl!.isNotEmpty) {
        _existingImageUrl = moc.imageUrl!;
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
      cropTitle: 'Crop MOC Image',
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

      if (widget.moc == null) {
        // ================= CREATE =================
        if (_selectedImage == null) {
          throw 'Image required';
        }

        await ref.read(mocProvider.notifier).create(
          name: name,
          siteId: siteID,
          isApplied: _isApplied,
          image: _selectedImage!,
        );
      } else {
        // ================= UPDATE =================
        await ref.read(mocProvider.notifier).update(
          mocId: widget.moc!.id,
          name: name,
          isApplied: _isApplied,
          image: _selectedImage, // nullable
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
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

      appBar:CustomAppBar(title: "Add MOC"),
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
                  label: 'MOC Name',
                  hint: 'Enter MOC name (e.g., Stainless Steel, HDPE)',
                  isRequired: true,
                  TextSize: 16,
                  controller: _nameController,
                  keyboardType: TextInputType.text,
                ),
                _buildIsAppliedField(),
                const SizedBox(height: 24),
        
                // Image Upload Section

                UploadBox(
                  title: 'MOC Image',
                  subtitle: 'Tap to change image',
                  buttonText: 'Change Image',
                  onPressed: _pickImage,
                  previewWidget: (_selectedImage != null || _existingImageUrl != null)
                      ? UploadBoxPreview(
                    file: _selectedImage,
                    source: _existingImageUrl,
                    isImage: true,
                    onRemove: () {
                      setState(() {
                        _selectedImage = null;
                        _existingImageUrl = null;
                      });
                    },
                    onEdit: _pickImage,
                  )
                      : null,
                ),


        
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
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Adding MOC...'),
                    ],
                  )
                      : const Text(
                    'Save MOC',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
        
                // Cancel Button
                OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
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
                      ? 'This moc will be available for ALL sites in your company'
                      : 'This moc will only be available for the current site',
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
