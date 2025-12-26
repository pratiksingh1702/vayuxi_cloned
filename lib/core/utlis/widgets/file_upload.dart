import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class UploadBox extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;
  final File? selectedFile;
  final Widget? previewWidget;

  const UploadBox({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
    this.selectedFile,
    this.previewWidget,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = selectedFile != null || previewWidget != null;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: hasFile && previewWidget != null
            ? previewWidget!
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload_outlined,
                color: Colors.blue, size: 48),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white, // White background
                foregroundColor: Colors.blue, // Blue text
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.blue, // Blue border
                    width: 1.5, // Border thickness
                  ),
                ),
                minimumSize: const Size(140, 40),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.blue, // Blue text
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ============================================
// Helper class for Image Upload with Cropping
// ============================================
class ImageUploadHelper {
  final BuildContext context;
  final ImagePicker _picker = ImagePicker();

  ImageUploadHelper(this.context);

  /// Shows dialog to choose between Gallery and Camera
  Future<File?> pickAndCropImage({
    bool enableCropping = true,
    String cropTitle = 'Crop Image',
  }) async {
    final source = await _showImageSourceDialog();
    if (source == null) return null;

    return await _pickImageFromSource(
      source,
      enableCropping: enableCropping,
      cropTitle: cropTitle,
    );
  }

  /// Pick image from Gallery only
  Future<File?> pickFromGallery({
    bool enableCropping = true,
    String cropTitle = 'Crop Image',
  }) async {
    return await _pickImageFromSource(
      ImageSource.gallery,
      enableCropping: enableCropping,
      cropTitle: cropTitle,
    );
  }

  /// Pick image from Camera only
  Future<File?> pickFromCamera({
    bool enableCropping = true,
    String cropTitle = 'Crop Image',
  }) async {
    return await _pickImageFromSource(
      ImageSource.camera,
      enableCropping: enableCropping,
      cropTitle: cropTitle,
    );
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<File?> _pickImageFromSource(
      ImageSource source, {
        required bool enableCropping,
        required String cropTitle,
      }) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // If cropping is enabled, crop the image
        if (enableCropping) {
          final croppedFile = await _cropImage(imageFile, cropTitle);
          if (croppedFile != null) {
            imageFile = File(croppedFile.path);
          } else {
            // User cancelled cropping
            return null;
          }
        }

        return imageFile;
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: ${e.toString()}');
    }
    return null;
  }

  Future<CroppedFile?> _cropImage(File imageFile, String title) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            toolbarColor: Colors.blueAccent,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
            cropGridRowCount: 3,
            cropGridColumnCount: 3,
            cropGridColor: Colors.white.withOpacity(0.5),
            cropFrameColor: Colors.blueAccent,
            cropGridStrokeWidth: 1,
            cropFrameStrokeWidth: 2,
            activeControlsWidgetColor: Colors.blueAccent,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: title,
            minimumAspectRatio: 0.1,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
            resetAspectRatioEnabled: true,
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(
              width: 520,
              height: 520,
            ),
            viewwMode: WebViewMode.mode_1,
          ),
        ],
      );

      return croppedFile;
    } catch (e) {
      _showErrorSnackBar('Error cropping image: ${e.toString()}');
      return null;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// ============================================
// Preview Widget Builder
// ============================================
class UploadBoxPreview extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  final VoidCallback onEdit;
  final bool isImage;

  const UploadBoxPreview({
    super.key,
    required this.file,
    required this.onRemove,
    required this.onEdit,
    this.isImage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Preview Content
        if (isImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey[100],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.insert_drive_file,
                    size: 48, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text(
                  file.path.split('/').last,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),

        // Overlay
        if (isImage)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),

        // Remove button
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Edit/Change button
        Positioned(
          bottom: 15,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18),
              label: Text(isImage ? 'Change Image' : 'Change File'),
              style: ElevatedButton.styleFrom(
                elevation: 2,
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(140, 40),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================
// USAGE EXAMPLES
// ============================================

/*
// Example 1: Image Upload with Cropping
class ImageUploadExample extends StatefulWidget {
  @override
  State<ImageUploadExample> createState() => _ImageUploadExampleState();
}

class _ImageUploadExampleState extends State<ImageUploadExample> {
  File? _selectedImage;

  Future<void> _handleImageUpload() async {
    final helper = ImageUploadHelper(context);
    final file = await helper.pickAndCropImage(
      enableCropping: true,
      cropTitle: 'Crop Profile Photo',
    );

    if (file != null) {
      setState(() {
        _selectedImage = file;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: UploadBox(
          title: 'Upload Profile Photo',
          subtitle: 'Select and crop your image',
          buttonText: 'Choose Photo',
          onPressed: _handleImageUpload,
          selectedFile: _selectedImage,
          previewWidget: _selectedImage != null
              ? UploadBoxPreview(
                  file: _selectedImage!,
                  isImage: true,
                  onRemove: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  onEdit: _handleImageUpload,
                )
              : null,
        ),
      ),
    );
  }
}

// Example 2: CSV/File Upload (No Cropping)
class CsvUploadExample extends StatefulWidget {
  @override
  State<CsvUploadExample> createState() => _CsvUploadExampleState();
}

class _CsvUploadExampleState extends State<CsvUploadExample> {
  File? _selectedCsv;

  Future<void> _handleCsvUpload() async {
    // Use file_picker package for CSV
    // final result = await FilePicker.platform.pickFiles(
    //   type: FileType.custom,
    //   allowedExtensions: ['csv'],
    // );

    // if (result != null) {
    //   setState(() {
    //     _selectedCsv = File(result.files.single.path!);
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: UploadBox(
          title: 'Upload CSV File',
          subtitle: 'Select a CSV file to import',
          buttonText: 'Choose File',
          onPressed: _handleCsvUpload,
          selectedFile: _selectedCsv,
          previewWidget: _selectedCsv != null
              ? UploadBoxPreview(
                  file: _selectedCsv!,
                  isImage: false,
                  onRemove: () {
                    setState(() {
                      _selectedCsv = null;
                    });
                  },
                  onEdit: _handleCsvUpload,
                )
              : null,
        ),
      ),
    );
  }
}

// Example 3: Direct Gallery Pick (No Dialog)
Future<void> _pickFromGalleryOnly() async {
  final helper = ImageUploadHelper(context);
  final file = await helper.pickFromGallery(
    enableCropping: true,
    cropTitle: 'Crop Document',
  );

  if (file != null) {
    // Handle the file
  }
}

// Example 4: Image without Cropping
Future<void> _pickWithoutCropping() async {
  final helper = ImageUploadHelper(context);
  final file = await helper.pickAndCropImage(
    enableCropping: false, // Disable cropping
  );

  if (file != null) {
    // Handle the file
  }
}
*/