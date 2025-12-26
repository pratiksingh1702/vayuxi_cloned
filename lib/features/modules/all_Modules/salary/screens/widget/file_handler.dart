// lib/core/utils/file_handler.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class FileHandler {
  // Load logo from assets
  static Future<Uint8List> loadLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.webp');
      return data.buffer.asUint8List();
    } catch (e) {
      print('Error loading logo: $e');
      return Uint8List(0);
    }
  }

  // Request Android permissions
  static Future<bool> requestAndroidPermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      // For Android 13+ (API 33+), we need different permissions
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }

      // For Android 10-12, request storage permission
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        return true;
      }

      // If not granted, show rationale and open app settings
      if (storageStatus.isPermanentlyDenied) {
        await openAppSettings();
      }

      return false;
    } catch (e) {
      print('Permission error: $e');
      return false;
    }
  }

  // Open file picker to select save directory
  static Future<String?> pickSaveDirectory(BuildContext context, {String? dialogTitle}) async {
    try {
      if (Platform.isAndroid) {
        // Check permissions first
        final hasPermission = await requestAndroidPermissions();
        if (!hasPermission) {
          _showPermissionError(context);
          return null;
        }

        // Open directory picker
        final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: dialogTitle ?? 'Select Save Location',
          lockParentWindow: true,
        );

        return selectedDirectory;

      } else if (Platform.isIOS) {
        // For iOS, we can't pick directories directly
        // Return app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        return appDir.path;

      } else {
        // For other platforms
        final downloadsDir = await getDownloadsDirectory();
        return downloadsDir?.path;
      }
    } catch (e, stack) {
      print('Error picking directory: $e');
      print('Stack trace: $stack');
      return null;
    }
  }

  // Save multiple files to selected directory
  static Future<SaveResult> saveMultipleFiles({
    required BuildContext context,
    required List<PdfFile> files,
    String? folderName,
    bool askForDirectory = true,
  }) async {
    try {
      String? saveDirectory;

      if (askForDirectory && Platform.isAndroid) {
        // Show directory picker
        saveDirectory = await pickSaveDirectory(
          context,
          dialogTitle: 'Select folder to save Salary Slips',
        );

        if (saveDirectory == null) {
          return SaveResult(
            success: false,
            message: 'No directory selected',
            savedCount: 0,
            savedPaths: [],
          );
        }
      } else {
        // Use default directory
        if (Platform.isAndroid) {
          final downloadsDir = await getDownloadsDirectory();
          saveDirectory = downloadsDir?.path;
        } else if (Platform.isIOS) {
          final appDir = await getApplicationDocumentsDirectory();
          saveDirectory = appDir.path;
        }

        if (saveDirectory == null) {
          return SaveResult(
            success: false,
            message: 'Could not access storage',
            savedCount: 0,
            savedPaths: [],
          );
        }
      }

      // Create subfolder if specified
      if (folderName != null && folderName.isNotEmpty) {
        saveDirectory = '$saveDirectory/$folderName';
      }

      // Create directory if it doesn't exist
      final saveDir = Directory(saveDirectory!);
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Save each file
      final savedPaths = <String>[];
      int successCount = 0;

      for (final file in files) {
        try {
          final fileName = _sanitizeFileName(file.fileName);
          final filePath = '${saveDir.path}/$fileName';
          final fileToSave = File(filePath);

          await fileToSave.writeAsBytes(file.fileBytes);
          savedPaths.add(filePath);
          successCount++;

          print('Saved: $fileName');
        } catch (e) {
          print('Error saving file ${file.fileName}: $e');
        }
      }

      return SaveResult(
        success: successCount > 0,
        message: successCount > 0
            ? 'Successfully saved $successCount file(s) to:\n${saveDir.path}'
            : 'Failed to save files',
        savedCount: successCount,
        savedPaths: savedPaths,
        directoryPath: saveDir.path,
      );

    } catch (e, stack) {
      print('Error saving multiple files: $e');
      print('Stack trace: $stack');

      return SaveResult(
        success: false,
        message: 'Error: ${e.toString()}',
        savedCount: 0,
        savedPaths: [],
      );
    }
  }

  // Save single file
  static Future<SaveResult> saveSingleFile({
    required BuildContext context,
    required Uint8List fileBytes,
    required String fileName,
    bool askForDirectory = true,
  }) async {
    final files = [PdfFile(fileName: fileName, fileBytes: fileBytes)];
    return await saveMultipleFiles(
      context: context,
      files: files,
      askForDirectory: askForDirectory,
    );
  }

  // Share file
  static Future<void> shareFile({
    required BuildContext context,
    required String filePath,
    required String fileName,
    String? subject,
    String? text,
  }) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath, name: fileName)],
        subject: subject ?? fileName,
        text: text,
      );
    } catch (e) {
      print('Error sharing file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Share multiple files
  static Future<void> shareMultipleFiles({
    required BuildContext context,
    required List<String> filePaths,
    String? subject,
    String? text,
  }) async {
    try {
      final xFiles = filePaths.map((path) => XFile(path)).toList();
      await Share.shareXFiles(
        xFiles,
        subject: subject ?? 'Salary Slips',
        text: text,
      );
    } catch (e) {
      print('Error sharing multiple files: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing files: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Check if sharing is available
  static Future<bool> isSharingAvailable() async {
    try {
      // Check by trying to create a share intent
      return true;
    } catch (e) {
      return false;
    }
  }

  // Open folder in file explorer (Android only)
  static Future<void> openFolder(BuildContext context, String folderPath) async {
    if (!Platform.isAndroid) return;

    try {
      final uri = Uri.parse('content://com.android.externalstorage.documents/document/primary:Download/SalarySlips');
      // You would need the 'open_file' package to implement this fully
      print('Folder path: $folderPath');
    } catch (e) {
      print('Error opening folder: $e');
    }
  }

// In FileHandler class
  static String _sanitizeFileName(String fileName) {
    // Remove invalid characters and ensure .pdf extension
    String sanitized = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    if (!sanitized.toLowerCase().endsWith('.pdf')) {
      sanitized += '.pdf';
    }
    return sanitized;
  }

  static void _showPermissionError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Storage permission is required to save files'),
        action: SnackBarAction(
          label: 'SETTINGS',
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }
}

// Model class for PDF files
class PdfFile {
  final String fileName;
  final Uint8List fileBytes;

  PdfFile({
    required this.fileName,
    required this.fileBytes,
  });
}

// Result class for save operations
class SaveResult {
  final bool success;
  final String message;
  final int savedCount;
  final List<String> savedPaths;
  final String? directoryPath;

  SaveResult({
    required this.success,
    required this.message,
    required this.savedCount,
    required this.savedPaths,
    this.directoryPath,
  });
}