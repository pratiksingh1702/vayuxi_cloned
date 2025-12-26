// lib/core/utils/pdf_generator.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

class SalarySlipData {
  final String name;
  final String employeeCode;
  final String designation;
  final String department;
  final String dob;
  final String doj;
  final String aadhar;
  final String uan;
  final String epf;
  final String esic;
  final int presentDays;
  final String month;
  final String year;
  final List<Earning> earnings;
  final List<Deduction> deductions;
  final double netPay;
  final String amountInWords;

  SalarySlipData({
    required this.name,
    required this.employeeCode,
    required this.designation,
    required this.department,
    required this.dob,
    required this.doj,
    required this.aadhar,
    required this.uan,
    required this.epf,
    required this.esic,
    required this.presentDays,
    required this.month,
    required this.year,
    required this.earnings,
    required this.deductions,
    required this.netPay,
    required this.amountInWords,
  });
}

class Earning {
  final String label;
  final double amount;

  Earning({required this.label, required this.amount});
}

class Deduction {
  final String label;
  final double amount;

  Deduction({required this.label, required this.amount});
}

class PDFGenerator {
  // Load fonts once
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static pw.Font? _italicFont;

  static Future<void> _loadFonts() async {
    if (_regularFont == null) {
      _regularFont = pw.Font.ttf(
        await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"),
      );
    }
    if (_boldFont == null) {
      _boldFont = pw.Font.ttf(
        await rootBundle.load("assets/fonts/NotoSans-Bold.ttf"),
      );
    }
    if (_italicFont == null) {
      _italicFont = pw.Font.ttf(
        await rootBundle.load("assets/fonts/NotoSans-Italic.ttf"),
      );
    }
  }

  // Convert number to words (simplified version)
  static String numberToWords(int num) {
    if (num == 0) return "Zero";
    if (num < 0) return "Minus ${numberToWords(-num)}";

    final units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"];
    final teens = ["Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    final tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];

    if (num < 10) return units[num];
    if (num < 20) return teens[num - 10];
    if (num < 100) {
      String words = tens[num ~/ 10];
      if (num % 10 != 0) words += " ${units[num % 10]}";
      return words;
    }
    if (num < 1000) {
      String words = "${units[num ~/ 100]} Hundred";
      if (num % 100 != 0) words += " ${numberToWords(num % 100)}";
      return words;
    }
    if (num < 100000) {
      String words = "${numberToWords(num ~/ 1000)} Thousand";
      if (num % 1000 != 0) words += " ${numberToWords(num % 1000)}";
      return words;
    }
    if (num < 10000000) {
      String words = "${numberToWords(num ~/ 100000)} Lakh";
      if (num % 100000 != 0) words += " ${numberToWords(num % 100000)}";
      return words;
    }
    return "Number too large";
  }

// In PDFGenerator class
  static String sanitizeFilename(String name) {
    // Add .pdf extension if not present
    String sanitized = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (!sanitized.toLowerCase().endsWith('.pdf')) {
      sanitized += '.pdf';
    }
    return sanitized;
  }

  // Generate PDF for single salary slip
  static Future<File> generateSalarySlipPDF({
    required Map<String, dynamic> jsonData,
    required String companyName,
    required Uint8List logoBytes,
  }) async {
    // Load fonts first
    await _loadFonts();

    // Parse data
    final data = _parseSalaryData(jsonData);

    // Calculate totals
    final totalEarnings = data.earnings.fold(0.0, (sum, item) => sum + item.amount);
    final totalDeductions = data.deductions.fold(0.0, (sum, item) => sum + item.amount);
    final pfAmount = jsonData['deductions']?['pf'] ?? 0;
    final monthlyCTC = totalEarnings + (pfAmount is num ? pfAmount.toDouble() : 0.0);

    // Create PDF theme
    final theme = pw.ThemeData.withFont(
      base: _regularFont!,
      bold: _boldFont!,
      italic: _italicFont!,
    );

    final pdf = pw.Document(theme: theme);

    // Create PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logo
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.SizedBox(
                    width: 100,
                    child: logoBytes.isNotEmpty
                        ? pw.Image(
                      pw.MemoryImage(logoBytes),
                      height: 60,
                    )
                        : pw.Container(),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          companyName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue.shade(900),
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          "B-101, KRISHNA KUNJ B, RAMJANWADI, VAPI, VALSAD, GUJARAT, 396191",
                          style: pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Employee details table
              pw.Table.fromTextArray(
                context: context,
                border: pw.TableBorder.all(width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 9),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(2),
                },
                data: [
                  ['Pay Slip:', jsonData['month']?.toString() ?? '', 'Pay Slip for Month:', '${data.month}-${data.year}', 'D.O.B.:', data.dob],
                  ['Emp Code:', data.employeeCode, 'Employee Name:', data.name, 'Designation:', data.designation],
                  ['Aadhar No:', data.aadhar, 'Department:', data.department, 'DOJ:', data.doj],
                  ['ESIC No:', data.esic, 'UAN No:', data.uan, 'Total Days:', _calculateTotalDays(jsonData)],
                  ['EPF ID:', data.epf, 'Emp PAN No:', jsonData['manpowerDetails']?['panNumber']?.toString() ?? 'N/A', 'Days Present:', data.presentDays.toString()],
                ],
              ),

              pw.SizedBox(height: 20),

              // Salary details table
              pw.Table(
                border: pw.TableBorder.all(width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header
                  pw.TableRow(
                    children: [
                      _buildTableCell("EARNING", isHeader: true, fontSize: 9),
                      _buildTableCell("Amount", isHeader: true, fontSize: 9),
                      _buildTableCell("Deduction & Recoveries", isHeader: true, fontSize: 9),
                      _buildTableCell("Amount", isHeader: true, fontSize: 9),
                    ],
                  ),

                  // Earnings and deductions
                  ..._buildSalaryRows(data.earnings, data.deductions, fontSize: 9),

                  // Totals
                  pw.TableRow(
                    children: [
                      _buildTableCell("Amount Total:", alignRight: true, isBold: true, fontSize: 9),
                      _buildTableCell("₹${totalEarnings.toStringAsFixed(2)}", isBold: true, fontSize: 9),
                      _buildTableCell("Amount Total:", alignRight: true, isBold: true, fontSize: 9),
                      _buildTableCell("₹${totalDeductions.toStringAsFixed(2)}", isBold: true, fontSize: 9),
                    ],
                  ),

                  pw.TableRow(
                    children: [
                      _buildTableCell("MONTHLY CTC:", alignRight: true, isBold: true, fontSize: 9),
                      _buildTableCell("₹${monthlyCTC.toStringAsFixed(2)}", isBold: true, fontSize: 9),
                      _buildTableCell("Net Pay:", alignRight: true, isBold: true, fontSize: 9),
                      _buildTableCell("₹${data.netPay.toStringAsFixed(2)}", isBold: true, fontSize: 9),
                    ],
                  ),

                  // Net pay in words
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          "Net Pay: ${data.amountInWords}",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontStyle: pw.FontStyle.italic,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Footer
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("From,"),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      companyName.toUpperCase(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF to file
    final dir = await getApplicationDocumentsDirectory();
    final fileName = sanitizeFilename("SalarySlip_${data.name}_${data.month}_${data.year}.pdf");
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static String _calculateTotalDays(Map<String, dynamic> jsonData) {
    final presentDays = jsonData['presentDays'] ?? 0;
    final absentDays = jsonData['absentDays'] ?? 0;
    return (presentDays + absentDays).toString();
  }

  static pw.Widget _buildTableCell(
      String text, {
        bool isHeader = false,
        bool isBold = false,
        bool alignRight = false,
        double fontSize = 10,
      }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  static List<pw.TableRow> _buildSalaryRows(List<Earning> earnings, List<Deduction> deductions, {double fontSize = 10}) {
    final rows = <pw.TableRow>[];
    final maxLength = earnings.length > deductions.length ? earnings.length : deductions.length;

    for (int i = 0; i < maxLength; i++) {
      final earning = i < earnings.length ? earnings[i] : Earning(label: "", amount: 0);
      final deduction = i < deductions.length ? deductions[i] : Deduction(label: "", amount: 0);

      rows.add(
        pw.TableRow(
          children: [
            _buildTableCell(earning.label, fontSize: fontSize),
            _buildTableCell("₹${earning.amount.toStringAsFixed(2)}", fontSize: fontSize),
            _buildTableCell(deduction.label, fontSize: fontSize),
            _buildTableCell("₹${deduction.amount.toStringAsFixed(2)}", fontSize: fontSize),
          ],
        ),
      );
    }

    return rows;
  }

  static SalarySlipData _parseSalaryData(Map<String, dynamic> jsonData) {
    final manpower = jsonData['manpowerDetails'] ?? {};
    final earnings = jsonData['earnings'] ?? {};
    final deductions = jsonData['deductions'] ?? {};

    // Debug logging
    print('Parsing salary data for: ${manpower['fullName']}');
    print('Earnings keys: ${earnings.keys.toList()}');
    print('Deductions keys: ${deductions.keys.toList()}');

    // Parse earnings - match with React Native structure
    final parsedEarnings = [
      Earning(label: "Basic", amount: _toDouble(earnings['basic'])),
      Earning(label: "H.R.A", amount: _toDouble(earnings['hra'])),
      Earning(label: "OT", amount: _toDouble(earnings['ot'])),
      Earning(label: "DA", amount: _toDouble(earnings['da'])),
      // Add other earnings if they exist
      if (_toDouble(earnings['specialAllowance']) > 0)
        Earning(label: "Special Allowance", amount: _toDouble(earnings['specialAllowance'])),
      if (_toDouble(earnings['travelAllowance']) > 0)
        Earning(label: "Travel Allowance", amount: _toDouble(earnings['travelAllowance'])),
      if (_toDouble(earnings['medicalAllowance']) > 0)
        Earning(label: "Medical Allowance", amount: _toDouble(earnings['medicalAllowance'])),
    ];

    // Parse deductions - match with React Native structure
    final parsedDeductions = [
      Deduction(label: "PF", amount: _toDouble(deductions['pf'])),
      Deduction(label: "ESI", amount: _toDouble(deductions['esi'])),
      Deduction(label: "P TAX", amount: _toDouble(deductions['ptax'])),
      Deduction(label: "LWF", amount: _toDouble(deductions['lwf'])),
      // Note: React Native uses "ADVANCE" but your data shows "advance"
      Deduction(label: "ADVANCE", amount: _toDouble(deductions['advance'] ?? deductions['advan'])),
    ];

    // Use finalSalary from API or calculate
    final netPay = jsonData['finalSalary'] != null
        ? _toDouble(jsonData['finalSalary'])
        : (parsedEarnings.fold(0.0, (sum, item) => sum + item.amount) -
        parsedDeductions.fold(0.0, (sum, item) => sum + item.amount));

    // Get month and year from data or use current
    final month = jsonData['month']?.toString() ?? '';
    final year = jsonData['year']?.toString() ?? '';

    // Format amount in words
    final amountWords = numberToWords(netPay.toInt());
    final amountInWords = "Rupees $amountWords Only";

    return SalarySlipData(
      name: manpower['fullName']?.toString() ?? "Unknown",
      employeeCode: manpower['employeeCode']?.toString() ?? "",
      designation: manpower['designation']?.toString() ?? "",
      department: manpower['type']?.toString() ?? "N/A",
      dob: manpower['dateOfBirth'] != null
          ? _formatDate(DateTime.parse(manpower['dateOfBirth']))
          : "",
      doj: manpower['dateOfJoining'] != null
          ? _formatDate(DateTime.parse(manpower['dateOfJoining']))
          : "",
      aadhar: manpower['aadhaarCard']?.toString() ?? manpower['aaddharNumber']?.toString() ?? "",
      uan: manpower['uanNumber']?.toString() ?? "",
      epf: manpower['epfNumber']?.toString() ?? "",
      esic: manpower['esicNumber']?.toString() ?? "",
      presentDays: jsonData['presentDays']?.toInt() ?? 0,
      month: month,
      year: year,
      earnings: parsedEarnings,
      deductions: parsedDeductions,
      netPay: netPay,
      amountInWords: amountInWords,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}