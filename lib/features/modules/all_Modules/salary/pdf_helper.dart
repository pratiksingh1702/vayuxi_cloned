// pdf_generation_service.dart
import 'package:flutter/cupertino.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PDFGenerationService {
  static Future<void> generateEmployeePDF({
    required Map<String, dynamic> employee,
    required Map<String, dynamic> salaryData,
    required int month,
    required String year,
  }) async {
    try {
      final pdf = pw.Document();

      // Helper function to safely convert values to double
      double safeToDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      // Helper function to safely get nested map values
      dynamic safeGet(Map<String, dynamic> map, String key) {
        return map[key] ?? 0;
      }

      final earnings = Map<String, dynamic>.from(safeGet(salaryData, 'earnings') ?? {});
      final deductions = Map<String, dynamic>.from(safeGet(salaryData, 'deductions') ?? {});

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'SALARY SLIP',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Employee Details
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Employee Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Name: ${employee['fullName'] ?? 'N/A'}'),
                                pw.Text('Designation: ${employee['designation'] ?? 'N/A'}'),
                                pw.Text('Employee Code: ${employee['employeeCode'] ?? 'N/A'}'),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Month: $month'),
                                pw.Text('Year: $year'),
                                pw.Text('Present Days: ${safeGet(salaryData, 'presentDays') ?? 0}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Earnings Section
                pw.Text('EARNINGS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Column(
                    children: [
                      _buildSalaryRow('Basic Salary', safeToDouble(earnings['basic'])),
                      _buildSalaryRow('HRA', safeToDouble(earnings['hra'])),
                      _buildSalaryRow('DA', safeToDouble(earnings['da'])),
                      _buildSalaryRow('Special Allowance', safeToDouble(earnings['specialAllowance'])),
                      _buildSalaryRow('Travel Allowance', safeToDouble(earnings['travelAllowance'])),
                      _buildSalaryRow('Medical Allowance', safeToDouble(earnings['medicalAllowance'])),
                      _buildSalaryRow('Overtime', safeToDouble(earnings['ot'])),
                      pw.Divider(),
                      _buildSalaryRow('Total Earnings', _calculateTotalEarnings(earnings), isTotal: true),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Deductions Section
                pw.Text('DEDUCTIONS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Column(
                    children: [
                      _buildSalaryRow('PF', safeToDouble(deductions['pf'])),
                      _buildSalaryRow('ESI', safeToDouble(deductions['esi'])),
                      _buildSalaryRow('Professional Tax', safeToDouble(deductions['ptax'])),
                      _buildSalaryRow('LWF', safeToDouble(deductions['lwf'])),
                      _buildSalaryRow('Advance', safeToDouble(deductions['advance'])),
                      pw.Divider(),
                      _buildSalaryRow('Total Deductions', _calculateTotalDeductions(deductions), isTotal: true),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Net Salary
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                    color: PdfColors.grey100,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'NET SALARY',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      pw.Text(
                        '₹${safeToDouble(salaryData['finalSalary']).toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save or share the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      debugPrint("PDF Generation Error: $e");
      rethrow;
    }
  }

  static pw.Widget _buildSalaryRow(String label, double amount, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: isTotal
                ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                : null,
          ),
          pw.Text(
            '₹${amount.toStringAsFixed(2)}',
            style: isTotal
                ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                : null,
          ),
        ],
      ),
    );
  }

  static double _calculateTotalEarnings(Map<String, dynamic> earnings) {
    return safeToDouble(earnings['basic']) +
        safeToDouble(earnings['hra']) +
        safeToDouble(earnings['da']) +
        safeToDouble(earnings['specialAllowance']) +
        safeToDouble(earnings['travelAllowance']) +
        safeToDouble(earnings['medicalAllowance']) +
        safeToDouble(earnings['ot']);
  }

  static double _calculateTotalDeductions(Map<String, dynamic> deductions) {
    return safeToDouble(deductions['pf']) +
        safeToDouble(deductions['esi']) +
        safeToDouble(deductions['ptax']) +
        safeToDouble(deductions['lwf']) +
        safeToDouble(deductions['advance']);
  }

  static double safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static dynamic safeGet(Map<String, dynamic>? map, String key) {
    if (map == null) return 0;
    return map[key] ?? 0;
  }

  static Future<void> generateAllPDFs({
    required List<Map<String, dynamic>> employees,
    required List<dynamic> salaryData,
    required int month,
    required String year,
  }) async {
    for (final employee in employees) {
      final employeeSalary = salaryData.firstWhere(
            (data) => data["manpowerDetails"]["_id"] == employee["_id"],
        orElse: () => {},
      );

      if (employeeSalary.isNotEmpty && employeeSalary is Map<String, dynamic>) {
        await generateEmployeePDF(
          employee: employee,
          salaryData: employeeSalary,
          month: month,
          year: year,
        );

        // Small delay between PDF generations
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }
}