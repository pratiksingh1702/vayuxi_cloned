// lib/core/utils/pdf_generator.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
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
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static pw.Font? _italicFont;

  static Future<void> _loadFonts() async {
    if (_regularFont == null) {
      _regularFont = pw.Font.ttf(
          await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"));
      _boldFont =
          pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans-Bold.ttf"));
      _italicFont = pw.Font.ttf(
          await rootBundle.load("assets/fonts/NotoSans-Italic.ttf"));
    }
  }

  static Future<pw.MemoryImage?> _loadCompanyLogo(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return null;
    }
    try {
      final response = await http
          .get(Uri.parse(imageUrl), headers: {
        'User-Agent': 'Mozilla/5.0',
      })
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (e) {
      // Logo load failed silently
    }
    return null;
  }

  static Future<File> generateSalarySlipPDF({
    required Map<String, dynamic> jsonData,
    required String companyName,
    required Uint8List logoBytes,
    required String companyAddress,
    String? companyLogoUrl,
    int? selectedMonth,
  }) async {
    await _loadFonts();

    // Try URL logo first, fall back to bytes
    final pw.MemoryImage? companyLogo = companyLogoUrl != null
        ? await _loadCompanyLogo(companyLogoUrl)
        : (logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null);

    final manpower = jsonData['manpowerDetails'] as Map<String, dynamic>? ?? {};
    final company = jsonData['companyDetails'] as Map<String, dynamic>? ?? {};
    final earnings = jsonData['earnings'] as Map<String, dynamic>? ?? {};
    final deductions = jsonData['deductions'] as Map<String, dynamic>? ?? {};

    // Month name map matching site_salary_screen.dart
    const monthMap = {
      "January": 1, "February": 2, "March": 3, "April": 4,
      "May": 5, "June": 6, "July": 7, "August": 8,
      "September": 9, "October": 10, "November": 11, "December": 12,
    };

    final monthName = selectedMonth != null
        ? monthMap.keys.elementAt(selectedMonth - 1)
        : (jsonData['month']?.toString() ?? '');
    final yearStr = jsonData['year']?.toString() ?? '';

    final totalEarnings = _totalEarnings(earnings);
    final totalDeductions = _totalDeductions(deductions);
    final monthlyCTC = totalEarnings + (deductions['pf'] ?? 0).toDouble();
    final netPay = totalEarnings - totalDeductions;
    const currency = "₹";

    final regularFont = _regularFont!;
    final boldFont = _boldFont!;
    final italicFont = _italicFont!;

    // Styles — identical to site_salary_screen.dart
    final headerStyle = pw.TextStyle(
      font: boldFont,
      fontSize: 20,
      color: PdfColors.blue900,
    );
    final normalStyle = pw.TextStyle(font: regularFont, fontSize: 11);
    final boldStyle = pw.TextStyle(font: boldFont, fontSize: 11);
    final tableHeaderStyle = pw.TextStyle(font: boldFont, fontSize: 11);
    final italicStyle = pw.TextStyle(
        font: italicFont, fontSize: 13, fontStyle: pw.FontStyle.italic);

    final amountInWords = netPay >= 0
        ? "Rupees ${_numberToWords(netPay.toInt())} Only"
        : "Negative Rupees ${_numberToWords(netPay.abs().toInt())} Only";

    final resolvedCompanyName =
    (company['name'] ?? companyName).toString();

    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              companyLogo != null
                  ? pw.Container(
                height: 60,
                width: 60,
                child: pw.Image(companyLogo, fit: pw.BoxFit.contain),
              )
                  : pw.Container(
                height: 60,
                width: 60,
                alignment: pw.Alignment.center,
                decoration:
                pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Text('LOGO', style: boldStyle),
              ),
              pw.Expanded(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      resolvedCompanyName.toUpperCase(),
                      style: headerStyle,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      companyAddress,
                      style: pw.TextStyle(font: regularFont, fontSize: 12),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // ── EMPLOYEE INFO TABLE (no border — matches second file) ──────────
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.6),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1.4),
              5: const pw.FlexColumnWidth(1.8),
            },
            children: [
              _infoRow(
                'Pay Slip:', '12',
                'Pay Slip for Month:', '$monthName $yearStr',
                'D.O.B.:', _formatDate(manpower['dateOfBirth']),
                regularFont, boldFont,
              ),
              _infoRow(
                'Emp Code:', manpower['employeeCode']?.toString() ?? '',
                'Employee Name:', manpower['fullName']?.toString() ?? '',
                'Designation:', manpower['designation']?.toString() ?? '',
                regularFont, boldFont,
              ),
              _infoRow(
                'Aadhar No:', manpower['aaddharNumber']?.toString() ?? '',
                'Department:', manpower['type']?.toString() ?? 'N/A',
                'DOJ:', _formatDate(manpower['dateOfJoining']),
                regularFont, boldFont,
              ),
              _infoRow(
                'ESIC No:', manpower['esicNumber']?.toString() ?? '',
                'UAN No:', manpower['uanNumber']?.toString() ?? '',
                'Total Days:',
                '${((jsonData['presentDays'] ?? 0) as num).toInt() + ((jsonData['absentDays'] ?? 0) as num).toInt()}',
                regularFont, boldFont,
              ),
              _infoRow(
                'EPF No:', manpower['epfNumber']?.toString() ?? '',
                'Emp PAN No:', manpower['panNumber']?.toString() ?? 'N/A',
                'Days Present:',
                '${((jsonData['presentDays'] ?? 0) as num).toInt()}',
                regularFont, boldFont,
              ),
            ],
          ),

          pw.SizedBox(height: 15),

          // ── SALARY TABLE ─────────────────────────────────────────────────
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(children: [
                    _pdfCell('EARNING', tableHeaderStyle),
                    _pdfCell('Amount', tableHeaderStyle),
                    _pdfCell('Deduction & Recoveries', tableHeaderStyle),
                    _pdfCell('Amount', tableHeaderStyle),
                  ]),
                  ..._buildSalaryRows(earnings, deductions, regularFont, currency),
                  pw.TableRow(children: [
                    _pdfCellRight('Amount Total:', boldStyle),
                    _pdfCell(
                        '$currency${totalEarnings.toStringAsFixed(2)}',
                        boldStyle),
                    _pdfCellRight('Amount Total:', boldStyle),
                    _pdfCell(
                        '$currency${totalDeductions.toStringAsFixed(2)}',
                        boldStyle),
                  ]),
                  pw.TableRow(children: [
                    _pdfCellRight('MONTHLY CTC:', boldStyle),
                    _pdfCell(
                        '$currency${monthlyCTC.toStringAsFixed(2)}',
                        boldStyle),
                    _pdfCellRight('Net Pay:', boldStyle),
                    _pdfCell(
                        '$currency${netPay.toStringAsFixed(2)}', boldStyle),
                  ]),
                ],
              ),

              // Net pay in words — left+right+bottom border only (no top)
              pw.Table(
                border: const pw.TableBorder(
                  left: pw.BorderSide(width: 1),
                  right: pw.BorderSide(width: 1),
                  bottom: pw.BorderSide(width: 1),
                ),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Net Pay: $amountInWords',
                        style: italicStyle,
                      ),
                    ),
                  ]),
                ],
              ),
            ],
          ),

          // ── SIGNATURE ────────────────────────────────────────────────────
          pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('From,', style: normalStyle),
                pw.SizedBox(height: 4),
                pw.Text(
                  resolvedCompanyName.toUpperCase(),
                  style: boldStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    ));

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        "${dir.path}/Salary_${manpower['fullName'] ?? 'Employee'}_${monthName}_$yearStr.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Same PDF design as [generateSalarySlipPDF] but returns raw [Uint8List].
  /// Pass directly to FilePicker.platform.saveFile(bytes: ...) — no storage
  /// permission required, works identically on Android & iOS.
  static Future<Uint8List> generateSalarySlipBytes({
    required Map<String, dynamic> jsonData,
    required String companyName,
    required String companyAddress,
    String? companyLogoUrl,
    int? selectedMonth,
  }) async {
    await _loadFonts();

    final pw.MemoryImage? companyLogo = await _loadCompanyLogo(companyLogoUrl);

    final manpower   = jsonData['manpowerDetails'] as Map<String, dynamic>? ?? {};
    final company    = jsonData['companyDetails']  as Map<String, dynamic>? ?? {};
    final earnings   = jsonData['earnings']        as Map<String, dynamic>? ?? {};
    final deductions = jsonData['deductions']      as Map<String, dynamic>? ?? {};

    const monthMap = {
      "January": 1, "February": 2, "March": 3,  "April": 4,
      "May": 5,     "June": 6,     "July": 7,    "August": 8,
      "September": 9, "October": 10, "November": 11, "December": 12,
    };

    final monthName = selectedMonth != null
        ? monthMap.keys.elementAt(selectedMonth - 1)
        : (jsonData['month']?.toString() ?? '');
    final yearStr = jsonData['year']?.toString() ?? '';

    final totalEarnings   = _totalEarnings(earnings);
    final totalDeductions = _totalDeductions(deductions);
    final monthlyCTC = totalEarnings + _toDouble(deductions['pf']);
    final netPay     = totalEarnings - totalDeductions;
    const currency   = "₹";

    final regularFont      = _regularFont!;
    final boldFont         = _boldFont!;
    final italicFont       = _italicFont!;
    final headerStyle      = pw.TextStyle(font: boldFont, fontSize: 20, color: PdfColors.blue900);
    final normalStyle      = pw.TextStyle(font: regularFont, fontSize: 11);
    final boldStyle        = pw.TextStyle(font: boldFont, fontSize: 11);
    final tableHeaderStyle = pw.TextStyle(font: boldFont, fontSize: 11);
    final italicStyle      = pw.TextStyle(font: italicFont, fontSize: 13, fontStyle: pw.FontStyle.italic);

    final amountInWords = netPay >= 0
        ? "Rupees ${_numberToWords(netPay.toInt())} Only"
        : "Negative Rupees ${_numberToWords(netPay.abs().toInt())} Only";

    final resolvedCompanyName = (company['name'] ?? companyName).toString();

    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── HEADER ──────────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              companyLogo != null
                  ? pw.Container(height: 60, width: 60,
                  child: pw.Image(companyLogo, fit: pw.BoxFit.contain))
                  : pw.Container(
                  height: 60, width: 60,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Text('LOGO', style: boldStyle)),
              pw.Expanded(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(resolvedCompanyName.toUpperCase(),
                        style: headerStyle, textAlign: pw.TextAlign.center),
                    pw.SizedBox(height: 4),
                    pw.Text(companyAddress,
                        style: pw.TextStyle(font: regularFont, fontSize: 12),
                        textAlign: pw.TextAlign.center),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // ── EMPLOYEE INFO TABLE (no borders) ────────────────────────────
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.6),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1.4),
              5: const pw.FlexColumnWidth(1.8),
            },
            children: [
              _infoRow('Pay Slip:', '12',
                  'Pay Slip for Month:', '$monthName $yearStr',
                  'D.O.B.:', _formatDate(manpower['dateOfBirth']),
                  regularFont, boldFont),
              _infoRow('Emp Code:', manpower['employeeCode']?.toString() ?? '',
                  'Employee Name:', manpower['fullName']?.toString() ?? '',
                  'Designation:', manpower['designation']?.toString() ?? '',
                  regularFont, boldFont),
              _infoRow('Aadhar No:', manpower['aaddharNumber']?.toString() ?? '',
                  'Department:', manpower['type']?.toString() ?? 'N/A',
                  'DOJ:', _formatDate(manpower['dateOfJoining']),
                  regularFont, boldFont),
              _infoRow('ESIC No:', manpower['esicNumber']?.toString() ?? '',
                  'UAN No:', manpower['uanNumber']?.toString() ?? '',
                  'Total Days:',
                  '${(_toDouble(jsonData['presentDays']) + _toDouble(jsonData['absentDays'])).toInt()}',
                  regularFont, boldFont),
              _infoRow('EPF No:', manpower['epfNumber']?.toString() ?? '',
                  'Emp PAN No:', manpower['panNumber']?.toString() ?? 'N/A',
                  'Days Present:', '${_toDouble(jsonData['presentDays']).toInt()}',
                  regularFont, boldFont),
            ],
          ),

          pw.SizedBox(height: 15),

          // ── SALARY TABLE ────────────────────────────────────────────────
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(children: [
                    _pdfCell('EARNING', tableHeaderStyle),
                    _pdfCell('Amount', tableHeaderStyle),
                    _pdfCell('Deduction & Recoveries', tableHeaderStyle),
                    _pdfCell('Amount', tableHeaderStyle),
                  ]),
                  ..._buildSalaryRows(earnings, deductions, regularFont, currency),
                  pw.TableRow(children: [
                    _pdfCellRight('Amount Total:', boldStyle),
                    _pdfCell('$currency${totalEarnings.toStringAsFixed(2)}', boldStyle),
                    _pdfCellRight('Amount Total:', boldStyle),
                    _pdfCell('$currency${totalDeductions.toStringAsFixed(2)}', boldStyle),
                  ]),
                  pw.TableRow(children: [
                    _pdfCellRight('MONTHLY CTC:', boldStyle),
                    _pdfCell('$currency${monthlyCTC.toStringAsFixed(2)}', boldStyle),
                    _pdfCellRight('Net Pay:', boldStyle),
                    _pdfCell('$currency${netPay.toStringAsFixed(2)}', boldStyle),
                  ]),
                ],
              ),
              // Net pay in words — left+right+bottom border only (no top)
              pw.Table(
                border: const pw.TableBorder(
                  left: pw.BorderSide(width: 1),
                  right: pw.BorderSide(width: 1),
                  bottom: pw.BorderSide(width: 1),
                ),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Net Pay: $amountInWords', style: italicStyle),
                    ),
                  ]),
                ],
              ),
            ],
          ),

          // ── SIGNATURE ──────────────────────────────────────────────────
          pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('From,', style: normalStyle),
                pw.SizedBox(height: 4),
                pw.Text(resolvedCompanyName.toUpperCase(), style: boldStyle),
              ],
            ),
          ),
        ],
      ),
    ));

    return pdf.save();
  }

  // ── SALARY ROW BUILDER — identical to site_salary_screen.dart ─────────────
  static List<pw.TableRow> _buildSalaryRows(
      Map<String, dynamic> earnings,
      Map<String, dynamic> deductions,
      pw.Font regularFont,
      String currency,
      ) {
    final earningItems = [
      {'label': 'Basic', 'amount': earnings['basic'] ?? 0},
      {'label': 'H.R.A', 'amount': earnings['hra'] ?? 0},
      {'label': 'OT', 'amount': earnings['ot'] ?? 0},
      {'label': 'DA', 'amount': earnings['da'] ?? 0},
    ];

    final deductionItems = [
      {'label': 'PF', 'amount': deductions['pf'] ?? 0},
      {'label': 'ESI', 'amount': deductions['esi'] ?? 0},
      {'label': 'P TAX', 'amount': deductions['ptax'] ?? 0},
      {'label': 'LWF', 'amount': deductions['lwf'] ?? 0},
      {'label': 'ADVANCE', 'amount': deductions['advance'] ?? 0},
    ];

    final maxRows = earningItems.length > deductionItems.length
        ? earningItems.length
        : deductionItems.length;

    return List.generate(maxRows, (i) {
      final earn = i < earningItems.length
          ? earningItems[i]
          : {'label': '', 'amount': 0};
      final ded = i < deductionItems.length
          ? deductionItems[i]
          : {'label': '', 'amount': 0};

      final earnStyle = pw.TextStyle(font: regularFont, fontSize: 10);
      final dedStyle = pw.TextStyle(font: regularFont, fontSize: 10);

      return pw.TableRow(children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text(earn['label'] as String, style: earnStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text(
            '$currency${(earn['amount'] as num).toStringAsFixed(2)}',
            style: earnStyle,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text(ded['label'] as String, style: dedStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text(
            '$currency${(ded['amount'] as num).toStringAsFixed(2)}',
            style: dedStyle,
          ),
        ),
      ]);
    });
  }

  // ── PDF CELL HELPERS — identical to site_salary_screen.dart ───────────────
  static pw.Widget _pdfCell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: style),
    );
  }

  static pw.Widget _pdfCellRight(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.right),
    );
  }

  // ── INFO ROW — no border, matches site_salary_screen.dart ─────────────────
  static pw.TableRow _infoRow(
      String l1, String v1,
      String l2, String v2,
      String l3, String v3,
      pw.Font regular,
      pw.Font bold,
      ) {
    pw.Widget cell(String t, pw.Font f) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Text(t, style: pw.TextStyle(font: f, fontSize: 8)),
    );
    return pw.TableRow(children: [
      cell(l1, bold),   cell(v1, regular),
      cell(l2, bold),   cell(v2, regular),
      cell(l3, bold),   cell(v3, regular),
    ]);
  }

  // ── UTILITIES ─────────────────────────────────────────────────────────────
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      try { return double.parse(value); } catch (_) { return 0.0; }
    }
    return 0.0;
  }

  static String _formatDate(dynamic s) {
    if (s == null) return '';
    try {
      final d = DateTime.parse(s.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return s.toString();
    }
  }

  static double _totalEarnings(Map<String, dynamic> e) =>
      _toDouble(e['basic']) +
          _toDouble(e['hra']) +
          _toDouble(e['da']) +
          _toDouble(e['specialAllowance']) +
          _toDouble(e['travelAllowance']) +
          _toDouble(e['medicalAllowance']) +
          _toDouble(e['ot']);

  static double _totalDeductions(Map<String, dynamic> d) =>
      _toDouble(d['pf']) +
          _toDouble(d['esi']) +
          _toDouble(d['ptax']) +
          _toDouble(d['lwf']) +
          _toDouble(d['advance']);

  static String _numberToWords(int num) {
    if (num == 0) return "Zero";
    final isNeg = num < 0;
    if (isNeg) num = -num;

    const units = [
      "", "One", "Two", "Three", "Four", "Five",
      "Six", "Seven", "Eight", "Nine"
    ];
    const teens = [
      "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen",
      "Sixteen", "Seventeen", "Eighteen", "Nineteen"
    ];
    const tens = [
      "", "", "Twenty", "Thirty", "Forty", "Fifty",
      "Sixty", "Seventy", "Eighty", "Ninety"
    ];

    String convert(int n) {
      if (n < 10) return units[n];
      if (n < 20) return teens[n - 10];
      if (n < 100) {
        final rem = n % 10 == 0 ? '' : ' ${units[n % 10]}';
        return '${tens[n ~/ 10]}$rem';
      }
      if (n < 1000) {
        final rem = n % 100 == 0 ? '' : ' ${convert(n % 100)}';
        return '${units[n ~/ 100]} Hundred$rem';
      }
      if (n < 100000) {
        final rem = n % 1000 == 0 ? '' : ' ${convert(n % 1000)}';
        return '${convert(n ~/ 1000)} Thousand$rem';
      }
      return "Number too large";
    }

    final result = convert(num);
    return isNeg ? "Negative $result" : result;
  }

  // Keep public alias for backward compatibility
  static String numberToWords(int num) => _numberToWords(num);
}