// lib/core/utils/file_handler.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:share_plus/share_plus.dart';

class FileHandler {
  /// Load logo from assets
  static Future<Uint8List> loadLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.webp');
      return data.buffer.asUint8List();
    } catch (e) {
      debugPrint("Logo load error: $e");
      return Uint8List(0);
    }
  }

  /// Pick directory using Android Storage Access Framework
  static Future<String?> pickSaveDirectory(BuildContext context,
      {String dialogTitle = "Select Save Location"}) async {
    try {
      final String? directory =
          await FilePicker.platform.getDirectoryPath(dialogTitle: dialogTitle);

      return directory;
    } catch (e) {
      debugPrint("Directory picker error: $e");
      return null;
    }
  }

  /// Save multiple files
  static Future<SaveResult> saveMultipleFiles({
    required BuildContext context,
    required List<PdfFile> files,
    String? folderName,
  }) async {
    try {
      final selectedDirectory = await pickSaveDirectory(
        context,
        dialogTitle: "Select folder to save files",
      );

      if (selectedDirectory == null) {
        return SaveResult(
          success: false,
          message: "No directory selected",
          savedCount: 0,
          savedPaths: [],
        );
      }

      String saveDirectory = selectedDirectory;

      /// create subfolder if needed
      if (folderName != null && folderName.isNotEmpty) {
        saveDirectory = "$selectedDirectory/$folderName";
      }

      final saveDir = Directory(saveDirectory);

      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      int successCount = 0;
      final List<String> savedPaths = [];

      for (final file in files) {
        try {
          final fileName = _sanitizeFileName(file.fileName);
          final filePath = "${saveDir.path}/$fileName";

          final outputFile = File(filePath);

          await outputFile.writeAsBytes(file.fileBytes);

          /// update Android media index
          if (Platform.isAndroid) {
            await MediaScanner.loadMedia(path: filePath);
          }

          savedPaths.add(filePath);
          successCount++;

          debugPrint("Saved file: $filePath");
        } catch (e) {
          debugPrint("Error saving ${file.fileName}: $e");
        }
      }

      return SaveResult(
        success: successCount > 0,
        message: successCount > 0
            ? "Saved $successCount file(s) to:\n$saveDirectory"
            : "Failed to save files",
        savedCount: successCount,
        savedPaths: savedPaths,
        directoryPath: saveDirectory,
      );
    } catch (e) {
      debugPrint("Save error: $e");

      return SaveResult(
        success: false,
        message: e.toString(),
        savedCount: 0,
        savedPaths: [],
      );
    }
  }

  /// Save single file
  static Future<SaveResult> saveSingleFile({
    required BuildContext context,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    return saveMultipleFiles(
      context: context,
      files: [PdfFile(fileName: fileName, fileBytes: fileBytes)],
    );
  }

  /// Share single file
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
      debugPrint("Share error: $e");
      final colorScheme = Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error sharing file: $e"),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  /// Share multiple files
  static Future<void> shareMultipleFiles({
    required BuildContext context,
    required List<String> filePaths,
    String? subject,
    String? text,
  }) async {
    try {
      final files = filePaths.map((e) => XFile(e)).toList();

      await Share.shareXFiles(
        files,
        subject: subject ?? "Files",
        text: text,
      );
    } catch (e) {
      debugPrint("Share multiple error: $e");
      final colorScheme = Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error sharing files: $e"),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  /// Sanitize file name
  static String _sanitizeFileName(String fileName) {
    String sanitized = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), "_");

    if (!sanitized.toLowerCase().endsWith(".pdf")) {
      sanitized += ".pdf";
    }

    return sanitized;
  }
}

/// Model for files
class PdfFile {
  final String fileName;
  final Uint8List fileBytes;

  PdfFile({
    required this.fileName,
    required this.fileBytes,
  });
}

/// Save result model
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
