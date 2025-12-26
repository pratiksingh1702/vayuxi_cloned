import 'dart:io';
import 'package:excel/excel.dart';

import 'package:path_provider/path_provider.dart';

Future<void> exportToExcel(List<Map<String, dynamic>> manpowerList) async {
  try {
    // 📌 Create Excel

    final excel = Excel.createExcel();
    final sheet = excel['Manpower'];

    // Header row
    sheet.appendRow([
      TextCellValue('Full Name'),
      TextCellValue('Employee Code'),
      TextCellValue('Designation'),
      TextCellValue('Salary'),
    ]);

    // Data rows
    for (var m in manpowerList) {
      print(m['salary']);
      sheet.appendRow([
        TextCellValue(m['fullName'] ?? ''),
        TextCellValue(m['employeeCode'] ?? ''),
        TextCellValue(m['designation'] ?? ''),
        TextCellValue(m['salary']?.toString() ?? ''),
      ]);
    }

    // 📌 Path to Downloads folder
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else {
      downloadsDir = await getDownloadsDirectory(); // macOS, Windows
    }

    if (downloadsDir == null) {
      print("❌ Could not find Downloads folder");
      return;
    }

    final filePath = '${downloadsDir.path}/manpower_list.xlsx';

    // 📌 Write file
    final fileBytes = excel.encode();
    if (fileBytes == null) throw Exception("Excel encoding failed");

    final file = File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);

    print("✅ File saved at $filePath");


  } catch (e) {
    print("❌ Error exporting: $e");
  }
}
