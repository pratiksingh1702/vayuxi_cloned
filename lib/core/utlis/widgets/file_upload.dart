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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFile = selectedFile != null || previewWidget != null;

    return Card(
      color: isDark ? cs.surfaceContainer : cs.surface,
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
                  Icon(Icons.cloud_upload_outlined,
                      color: cs.primary, size: 48),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
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
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: cs.surface,
                      foregroundColor: cs.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: cs.primary,
                          width: 1.5,
                        ),
                      ),
                      minimumSize: const Size(140, 40),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        color: cs.primary,
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
                leading: Icon(Icons.photo_library,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt,
                    color: Theme.of(context).colorScheme.primary),
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
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
            cropGridRowCount: 3,
            cropGridColumnCount: 3,
            cropGridColor:
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
            cropFrameColor: Theme.of(context).colorScheme.primary,
            cropGridStrokeWidth: 1,
            cropFrameStrokeWidth: 2,
            activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
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
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

// ============================================
// Preview Widget Builder
// ============================================
class UploadBoxPreview extends StatelessWidget {
  final File? file;
  final String? source; // network url OR local path OR asset
  final VoidCallback onRemove;
  final VoidCallback onEdit;
  final bool isImage;

  const UploadBoxPreview({
    super.key,
    this.file,
    this.source,
    required this.onRemove,
    required this.onEdit,
    this.isImage = true,
  }) : assert(file != null || source != null,
            'Either file or source must be provided');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        // ================= PREVIEW =================
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _buildPreview(context),
        ),

        // ================= OVERLAY =================
        if (isImage)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.scrim.withOpacity(0.25),
                  cs.surface.withOpacity(0),
                  cs.scrim.withOpacity(0.4),
                ],
              ),
            ),
          ),

        // ================= REMOVE =================
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.error,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 20, color: cs.onError),
            ),
          ),
        ),

        // ================= EDIT =================
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
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
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

  // ================= IMAGE RESOLVER =================
  Widget _buildPreview(BuildContext context) {
    if (!isImage) {
      return _filePreview(context);
    }

    if (file != null) {
      return Image.file(
        file!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (source != null && source!.startsWith('http')) {
      return Image.network(
        source!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    if (source != null) {
      return Image.file(
        File(source!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    return _fallback(context);
  }

  Widget _filePreview(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name =
        file != null ? file!.path.split('/').last : source!.split('/').last;

    return Container(
      color: cs.surfaceContainerLowest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainer,
      child: Center(
        child: Icon(Icons.broken_image, size: 40, color: cs.onSurfaceVariant),
      ),
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
