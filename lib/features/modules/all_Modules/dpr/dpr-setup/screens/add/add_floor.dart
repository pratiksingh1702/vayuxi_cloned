// screens/add_floor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../../../core/utlis/widgets/file_upload.dart';
import '../../../models/floorModel.dart';
import '../../../providers/floorProvider.dart';
import 'package:file_picker/file_picker.dart';

class AddFloorPage extends ConsumerStatefulWidget {
  const AddFloorPage({super.key});

  @override
  ConsumerState<AddFloorPage> createState() => _AddFloorPageState();
}

class _AddFloorPageState extends ConsumerState<AddFloorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _imagePathController = TextEditingController();

  bool _isSubmitting = false;
  String? _selectedImagePath;
  bool _isUsingMockData = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Listen to mock data state
    _isUsingMockData = ref.read(floorProvider).useMockData;

    // Set up listeners to auto-generate code from name
    _nameController.addListener(_autoGenerateCode);
  }

  void _autoGenerateCode() {
    if (_nameController.text.isNotEmpty && _codeController.text.isEmpty) {
      final generatedCode = _generateFloorCode(_nameController.text);
      _codeController.text = generatedCode;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _imagePathController.dispose();
    super.dispose();
  }

  void _handleImageSelection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Floor Image'),
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
            ListTile(
              leading: const Icon(Icons.image_search),
              title: const Text('Use Default Floor Image'),
              onTap: () {
                Navigator.pop(context);
                _useDefaultImage();
              },
            ),
          ],
        ),
      ),
    );
  }



// ... existing code ...

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
    setState(() {
      _selectedImagePath = 'assets/floor/captured_floor.png';
      _imagePathController.text = 'assets/floor/captured_floor.png';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Floor photo captured from camera'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _useDefaultImage() {
    setState(() {
      _selectedImagePath = 'assets/floor/default_floor.png';
      _imagePathController.text = 'assets/floor/default_floor.png';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default floor image selected'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showManualPathDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Floor Image Path'),
        content: TextField(
          controller: _imagePathController,
          decoration: const InputDecoration(
            hintText: 'e.g., assets/floor/example.png',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            setState(() {
              _selectedImagePath = value.trim();
            });
            Navigator.pop(context);
          },
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

  String _generateFloorCode(String name) {
    // Generate code from name (convert to lowercase, remove spaces and special characters)
    return name.trim().toLowerCase().replaceAll(RegExp(r'[^\w]'), '_');
  }

  String _generateFloorId(String name) {
    // Generate unique ID with timestamp to avoid conflicts
    final baseId = name.trim().toLowerCase().replaceAll(RegExp(r'[^\w]'), '_');
    return '${baseId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedImagePath == null || _selectedImagePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a floor image'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final floorName = _nameController.text.trim();
      final floorCode = _codeController.text.trim().isNotEmpty
          ? _codeController.text.trim()
          : _generateFloorCode(floorName);
      final floorId = _generateFloorId(floorName);
      final imagePath = _imagePathController.text.trim();

      // Check if Floor with same code already exists
      final existingFloorByCode = ref.read(floorProvider.notifier).getFloorByCode(floorCode);
      if (existingFloorByCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Floor with code "$floorCode" already exists!'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Check if we're using mock data and need to switch to user data mode
      final currentState = ref.read(floorProvider);
      if (currentState.useMockData) {
        // Show dialog to switch to user data mode
        final shouldSwitch = await _showSwitchToUserDataDialog();
        if (!shouldSwitch) {
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }

      final newFloor = Floor(
        id: floorId,
        name: floorName,
        code: floorCode,
        image: imagePath,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(floorProvider.notifier).addFloor(newFloor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newFloor.name} floor added successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pop(newFloor);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding floor: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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

  Future<bool> _showSwitchToUserDataDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch to User Data Mode'),
        content: const Text(
          'You are currently using mock data. To add custom floors, '
              'the app will switch to user data mode. Your custom floors will be '
              'saved to your device. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Switch & Continue'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _clearForm() {
    _nameController.clear();
    _codeController.clear();
    _imagePathController.clear();
    setState(() {
      _selectedImagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final floorState = ref.watch(floorProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(
        title: "Add Floor",

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Data Mode Info Card
                if (floorState.useMockData)
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'In mock data mode. Your floors will be saved to device storage.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          
                const SizedBox(height: 16),
          
                // Name Field
                CustomTextField(
                  label: 'Floor Name',
                  hint: 'Enter floor name (e.g., Ground, First, Terrace)',
                  isRequired: true,
                  TextSize: 16,
                  controller: _nameController,
                  keyboardType: TextInputType.text,
          
                ),
                const SizedBox(height: 16),
          
                // Code Field
                CustomTextField(
                  label: 'Floor Code',
                  hint: 'Enter unique code (e.g., ground, first, terrace)',
                  isRequired: true,
                  TextSize: 16,
                  controller: _codeController,
                  keyboardType: TextInputType.text,
          
                ),
                const SizedBox(height: 24),
          
                // Image Upload Section
                Text(
                  'Floor Image *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
          
                UploadBox(
                  title: _selectedImagePath != null ? 'Floor Image Selected' : 'Upload Floor Image',
                  subtitle: _selectedImagePath != null
                      ? _selectedImagePath!
                      : 'Select an image for this floor',
                  buttonText: _selectedImagePath != null ? 'Change Image' : 'Select Image',
                  onPressed: _handleImageSelection,
                ),
          
                if (_selectedImagePath != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Selected: $_selectedImagePath',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
          
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
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
                            Text('Adding Floor...'),
                          ],
                        )
                            : const Text(
                          'Save Floor',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: _isSubmitting ? null : _clearForm,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        padding: const EdgeInsets.all(16),
                      ),
                      icon: const Icon(Icons.clear_all, color: Colors.grey),
                      tooltip: 'Clear Form',
                    ),
                  ],
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
}