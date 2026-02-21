import 'dart:io';
import 'dart:typed_data';
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



  Future<File?> downloadAndSaveTemplate(TemplateModel model) async {
    state = const AsyncLoading();

    try {
      final Uint8List bytes = await _api.downloadTemplate(model: model.apiValue);

      // ✅ Android/iOS requires bytes here
      final String? savedPath = await FilePicker.platform.saveFile(
        dialogTitle: "Save ${model.fileName}",
        fileName: model.fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes, // ✅ THIS FIXES ANDROID/iOS
      );

      if (savedPath == null) {
        state = const AsyncData(null);
        return null;
      }

      state = const AsyncData(null);
      return File(savedPath);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }


}
