import 'dart:io';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled2/core/utlis/sample_file/sample_file.dart';
import 'package:untitled2/core/utlis/sample_file/sample_file_model.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// ✅ Service Provider
final templatesApiServiceProvider = Provider<TemplatesApiService>((ref) {
  return TemplatesApiService();
});

/// ✅ Controller Provider (handles download + saving)
final templateDownloadControllerProvider =
AutoDisposeAsyncNotifierProvider<TemplateDownloadController, void>(
  TemplateDownloadController.new,
);

class TemplateDownloadController extends AutoDisposeAsyncNotifier<void> {
  late final TemplatesApiService _api;

  @override
  Future<void> build() async {
    _api = ref.read(templatesApiServiceProvider);
  }



  Future<String?> downloadAndSaveTemplate(TemplateModel model) async {
    state = const AsyncLoading();

    try {
      final Uint8List bytes =
      await _api.downloadTemplate(model: model.apiValue);

      if (!await FlutterFileDialog.isPickDirectorySupported()) {
        throw Exception("Directory picking not supported on this device");
      }

      final pickedDirectory =
      await FlutterFileDialog.pickDirectory();

      if (pickedDirectory == null) {
        state = const AsyncData(null);
        return null; // user cancelled
      }

      final extension = model.fileName.split('.').last.toLowerCase();

      final mimeType = extension == 'xlsx'
          ? "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
          : "text/csv";
      print("mime type = $mimeType");

      final filePath = await FlutterFileDialog.saveFileToDirectory(
        directory: pickedDirectory,
        data: bytes,
        mimeType: mimeType,          // 🔥 correct mime type
        fileName: model.fileName,    // 🔥 must include .xlsx
        replace: true,
      );

      state = const AsyncData(null);
      return filePath;

    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
