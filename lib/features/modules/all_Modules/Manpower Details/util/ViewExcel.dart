import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';

Future<void> exportToExcel(List<Map<String, dynamic>> manpowerList) async {
  try {
    final excel = Excel.createExcel();
    final sheet = excel['Manpower'];

    sheet.appendRow([
      TextCellValue('Full Name'),
      TextCellValue('Employee Code'),
      TextCellValue('Designation'),
      TextCellValue('Salary'),
    ]);

    for (var m in manpowerList) {
      sheet.appendRow([
        TextCellValue(m['fullName'] ?? ''),
        TextCellValue(m['employeeCode'] ?? ''),
        TextCellValue(m['designation'] ?? ''),
        TextCellValue(m['salary']?.toString() ?? ''),
      ]);
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) throw Exception("Excel encoding failed");

    final uint8List = Uint8List.fromList(fileBytes);

    // 🔥 Let user pick a directory instead of saving bytes
    String? selectedDir = await FilePicker.platform.getDirectoryPath();

    if (selectedDir == null) {
      print("User cancelled");
      return;
    }

    final filePath = "$selectedDir/manpower_list.xlsx";

    final file = File(filePath);
    await file.writeAsBytes(uint8List);

    print("✅ Excel saved at $filePath");

  } catch (e) {
    print("❌ Error exporting: $e");
  }
}