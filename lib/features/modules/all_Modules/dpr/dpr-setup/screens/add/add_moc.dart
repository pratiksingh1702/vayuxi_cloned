// screens/add_moc_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../../../core/utlis/widgets/file_upload.dart';
import '../../../models/moc.dart';
import '../../../providers/mocProvider.dart';
import 'package:file_picker/file_picker.dart';

class AddMOCPage extends ConsumerStatefulWidget {
  const AddMOCPage({super.key});

  @override
  ConsumerState<AddMOCPage> createState() => _AddMOCPageState();
}

class _AddMOCPageState extends ConsumerState<AddMOCPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imagePathController = TextEditingController();

  bool _isSubmitting = false;
  String? _selectedImagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _imagePathController.dispose();
    super.dispose();
  }

  void _handleImageSelection() {
    // Simulate image selection - you can integrate with image_picker for actual functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('From Gallery'),
              onTap: () {
                Navigator.pop(context);
                _simulateGalleryPick();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _simulateCameraCapture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Enter Path Manually'),
              onTap: () {
                Navigator.pop(context);
                _showManualPathDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _simulateGalleryPick() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,

      );

      if (result != null && result.files.single.path != null) {
        PlatformFile file = result.files.single;

        setState(() {
          _selectedImagePath = file.path!;
          _imagePathController.text = file.path!;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Floor image selected: ${file.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // User canceled the picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selection canceled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _simulateCameraCapture() {
    // Simulate camera capture - replace with actual image_picker implementation
    setState(() {
      _selectedImagePath = 'assets/stepper/captured_moc.png';
      _imagePathController.text = 'assets/stepper/captured_moc.png';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo captured from camera'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showManualPathDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Image Path'),
        content: TextField(
          controller: _imagePathController,
          decoration: const InputDecoration(
            hintText: 'e.g., assets/stepper/example.png',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedImagePath = _imagePathController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _generateMOCId(String name) {
    // Generate ID from name (convert to uppercase, remove spaces)
    return name.trim().toUpperCase().replaceAll(' ', '_');
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final mocName = _nameController.text.trim();
      final mocId = _generateMOCId(mocName);
      final imagePath = _imagePathController.text.trim();

      // Check if MOC with generated ID already exists
      final existingMOC = ref.read(mocProvider.notifier).getById(mocId);
      if (existingMOC != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('MOC with ID "$mocId" already exists!'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final newMOC = MOC(
        id: mocId,
        name: mocName,
        imageUrl: imagePath,

        createdAt: DateTime.now(),

      );

      await ref.read(mocProvider.notifier).add(newMOC);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newMOC.name} added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding MOC: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,

      appBar:CustomAppBar(title: "Add MOC"),
      backgroundColor: AppColors.lightBlue,
      body: Padding(
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
              const SizedBox(height: 24),

              // Image Upload Section


              UploadBox(
                title: _selectedImagePath != null ? 'Image Selected' : 'Upload MOC Image',
                subtitle: _selectedImagePath != null
                    ? _selectedImagePath!
                    : 'Select an image for this MOC material',
                buttonText: _selectedImagePath != null ? 'Change Image' : 'Select Image',
                onPressed: _handleImageSelection,
              ),

              if (_selectedImagePath != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Selected: $_selectedImagePath',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 32),

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
    );
  }
}