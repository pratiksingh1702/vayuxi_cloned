import 'dart:io';
import 'package:http/http.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:media_scanner/media_scanner.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/service/manPowerProvider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/profile_page/userModel/userModel.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../profile_page/provider/userProvider.dart';
import '../service-provider/salaryClient.dart';
import 'package:download_path_provider/download_path_provider.dart';

class SiteSalaryScreen extends ConsumerStatefulWidget {
  final SiteModel siteModel;

  const SiteSalaryScreen({super.key, required this.siteModel});

  @override
  ConsumerState<SiteSalaryScreen> createState() => _SiteScreenState();
}

class _SiteScreenState extends ConsumerState<SiteSalaryScreen> {
  int? selectedMonth;
  String? selectedYear;
  List<String> yearOptions = [];

  List<Map<String, dynamic>> manpowerDataList = [];
  List<dynamic> workData = [];

  bool isLoading = false;
  bool isFetchingWorkData = false;
  bool isDownloading = false;

  static const Map<String, int> monthMap = {
    "January": 1,
    "February": 2,
    "March": 3,
    "April": 4,
    "May": 5,
    "June": 6,
    "July": 7,
    "August": 8,
    "September": 9,
    "October": 10,
    "November": 11,
    "December": 12,
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _generateYearOptions(2020);
    final currentYear = DateTime.now().year.toString();
    if (yearOptions.contains(currentYear)) {
      selectedYear = currentYear;
    }
    Future.microtask(_fetchManpower);
  }

  void _generateYearOptions(int startYear) {
    final currentYear = DateTime.now().year;
    yearOptions = List.generate(
      currentYear - startYear + 1,
      (index) => (currentYear - index).toString(),
    );
  }

  Future<void> _fetchManpower() async {
    if (mounted) setState(() => isLoading = true);

    try {
      final type = ref.read(typeProvider);
      if (type != null) {
        await ref.read(manpowerProvider.notifier).fetchManpower(type);
        final manpowerState = ref.read(manpowerProvider);

        if (mounted) {
          setState(() {
            manpowerDataList = manpowerState.manpowerList.map((emp) {
              return {
                "_id": emp.id,
                "fullName": emp.fullName ?? "No Name",
                "designation": emp.designation ?? "No Designation",
                "employeeCode": emp.employeeCode,
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching manpower: $e");
      if (mounted) _showAlert("Error", "Failed to load employee data");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchWorkData() async {
    if (selectedMonth == null || selectedYear == null) {
      _showAlert("Selection Required", "Please select both month and year");
      return;
    }

    if (mounted) setState(() => isFetchingWorkData = true);

    try {
      final type = ref.read(typeProvider);
      if (type != null) {
        final List<dynamic> response = await SalaryAPI.fetchSalaryBySite(
          type: type,
          id: widget.siteModel.id,
          month: selectedMonth.toString(),
          year: selectedYear!,
        );

        if (mounted) {
          setState(() {
            workData = response;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching work data: $e");
      if (mounted) _showAlert("Error", "Failed to load salary data");
    } finally {
      if (mounted) setState(() => isFetchingWorkData = false);
    }
  }

  // Permission handling
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        _showPermissionDialog();
        return false;
      }
      return false;
    }
    return true;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
          "Storage permission is required to save salary slip files.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  // Number to words conversion
  String _numberToWords(int num) {
    if (num == 0) return "Zero";

    bool isNegative = false;
    if (num < 0) {
      isNegative = true;
      num = -num;
    }

    final units = [
      "",
      "One",
      "Two",
      "Three",
      "Four",
      "Five",
      "Six",
      "Seven",
      "Eight",
      "Nine",
    ];
    final teens = [
      "Ten",
      "Eleven",
      "Twelve",
      "Thirteen",
      "Fourteen",
      "Fifteen",
      "Sixteen",
      "Seventeen",
      "Eighteen",
      "Nineteen",
    ];
    final tens = [
      "",
      "",
      "Twenty",
      "Thirty",
      "Forty",
      "Fifty",
      "Sixty",
      "Seventy",
      "Eighty",
      "Ninety",
    ];

    String convert(int n) {
      if (n < 10) return units[n];
      if (n < 20) return teens[n - 10];
      if (n < 100) {
        String words = tens[n ~/ 10];
        if (n % 10 != 0) words += " " + units[n % 10];
        return words;
      }
      if (n < 1000) {
        String words = units[n ~/ 100] + " Hundred";
        if (n % 100 != 0) words += " " + convert(n % 100);
        return words;
      }
      if (n < 100000) {
        String words = convert(n ~/ 1000) + " Thousand";
        if (n % 1000 != 0) words += " " + convert(n % 1000);
        return words;
      }
      return "Number too large";
    }

    String result = convert(num);
    return isNegative ? "Negative $result" : result;
  }

  // Calculate totals
  double _calculateTotalEarnings(Map<String, dynamic> earnings) {
    return ((earnings['basic'] ?? 0).toDouble() +
        (earnings['hra'] ?? 0).toDouble() +
        (earnings['da'] ?? 0).toDouble() +
        (earnings['specialAllowance'] ?? 0).toDouble() +
        (earnings['travelAllowance'] ?? 0).toDouble() +
        (earnings['medicalAllowance'] ?? 0).toDouble() +
        (earnings['ot'] ?? 0).toDouble());
  }

  double _calculateTotalDeductions(Map<String, dynamic> deductions) {
    return ((deductions['pf'] ?? 0).toDouble() +
        (deductions['esi'] ?? 0).toDouble() +
        (deductions['ptax'] ?? 0).toDouble() +
        (deductions['lwf'] ?? 0).toDouble() +
        (deductions['advance'] ?? 0).toDouble());
  }
  Future<pw.MemoryImage?> _loadCompanyLogo(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    try {
      print('''
========== 🖼️ LOGO DEBUG START ==========
URL: $imageUrl
Valid URL: ${imageUrl.startsWith('http')}
''');

      if (!imageUrl.startsWith('http')) {
        print('❌ Not a valid HTTP URL');
        return null;
      }

      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      print('StatusCode: ${response.statusCode}');
      print('Bytes received: ${response.bodyBytes.length}');

      if (response.statusCode != 200) {
        print('❌ HTTP ${response.statusCode}');
        return null;
      }

      if (response.bodyBytes.isEmpty) {
        print('❌ Empty response body');
        return null;
      }

      // Validate it's actually an image
      final bytes = response.bodyBytes;
      if (bytes.length < 4) {
        print('❌ Too small to be a valid image');
        return null;
      }

      // Try to create the MemoryImage with better error handling
      try {
        final memoryImage = pw.MemoryImage(bytes);
        print('✅ Logo loaded successfully');
        return memoryImage;
      } catch (e) {
        print('❌ Failed to create MemoryImage: $e');
        return null;
      }
    } catch (e) {
      print('❌ Logo download failed: $e');
      return null;
    } finally {
      print('========== 🖼️ LOGO DEBUG END ==========\n');
    }
  }
  // Generate individual employee PDF
  Future<Uint8List> _generateEmployeePDF(
      Map<String, dynamic> employee,
      Map<String, dynamic> salaryData,
      String? companyName,
      String? companyLogoPath,
  ) async {
    // Load fonts
    final regularFont = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSans-Bold.ttf"),
    );
    final italicFont = pw.Font.ttf(
      await rootBundle.load("assets/fonts/NotoSans-Italic.ttf"),
    );

    final pdf = pw.Document();

    pw.MemoryImage? companyLogo;
    bool logoLoaded = false;
    if (companyLogoPath != null && companyLogoPath.isNotEmpty) {
      try {
        companyLogo = await _loadCompanyLogo(companyLogoPath);
        logoLoaded = companyLogo != null;
        print('🖼️ Logo loaded: $logoLoaded');
      } catch (e) {
        print('⚠️ Logo loading error: $e');
        companyLogo = null;
      }
    }

    final manpower = salaryData['manpowerDetails'] ?? {};
    final company = salaryData['companyDetails'] ?? {};
    final earnings = salaryData['earnings'] ?? {};
    print("================${earnings}=========");
    final deductions = salaryData['deductions'] ?? {};

    final monthName = monthMap.keys.elementAt((selectedMonth ?? 1) - 1);
    final totalEarnings = _calculateTotalEarnings(earnings);
    final totalDeductions = _calculateTotalDeductions(deductions);
    final monthlyCTC = totalEarnings + (deductions['pf'] ?? 0).toDouble();
    final netPay = totalEarnings - totalDeductions;
    final amountInWords = netPay >= 0
        ? "Rupees ${_numberToWords(netPay.toInt())} Only"
        : "Negative Rupees ${_numberToWords(netPay.abs().toInt())} Only";

    final currencySymbol = "Rs.";

    // Define styles
    final headerStyle = pw.TextStyle(
      font: boldFont,
      fontSize: 20,
      color: PdfColors.blue.shade(900),
    );

    final normalStyle = pw.TextStyle(font: regularFont, fontSize: 11);
    final boldStyle = pw.TextStyle(font: boldFont, fontSize: 11);
    final tableHeaderStyle = pw.TextStyle(font: boldFont, fontSize: 11);
    final italicStyle = pw.TextStyle(
      font: italicFont,
      fontSize: 13,
      fontStyle: pw.FontStyle.italic,
    );
    final user = ref.read(currentUserProvider);


    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (companyLogo != null)
                    pw.Container(
                      height: 60,
                      width: 60,
                      child: pw.Image(companyLogo, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.Container(
                      height: 60,
                      width: 60,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(),
                      ),
                      child: pw.Text('LOGO', style: boldStyle),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          (company['name'] ?? 'MY COMPANY').toUpperCase(),
                          style: headerStyle,
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          user?.address??"No Address",
                          style: pw.TextStyle(font: regularFont, fontSize: 12),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              // Employee Information Table
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
                    'Pay Slip for Month:', '$monthName $selectedYear',
                    'D.O.B.:', _formatDate(manpower['dateOfBirth']),
                    regularFont, boldFont,
                  ),
                  _infoRow(
                    'Emp Code:', manpower['employeeCode'] ?? '',
                    'Employee Name:', manpower['fullName'] ?? '',
                    'Designation:', manpower['designation'] ?? '',
                    regularFont, boldFont,
                  ),
                  _infoRow(
                    'Aadhar No:', manpower['aaddharNumber'] ?? '',
                    'Department:', manpower['type'] ?? 'N/A',
                    'DOJ:', _formatDate(manpower['dateOfJoining']),
                    regularFont, boldFont,
                  ),
                  _infoRow(
                    'ESIC No:', manpower['esicNumber'] ?? '',
                    'UAN No:', manpower['uanNumber'] ?? '',
                    'Total Days:',
                    '${(salaryData['presentDays'] ?? 0) + (salaryData['absentDays'] ?? 0)}',
                    regularFont, boldFont,
                  ),
                  _infoRow(
                    'EPF No:', manpower['epfNumber'] ?? '',
                    'Emp PAN No:', manpower['panNumber'] ?? 'N/A',
                    'Days Present:', '${salaryData['presentDays'] ?? 0}',
                    regularFont, boldFont,
                  ),
                ],
              ),


              pw.SizedBox(height: 15),

              // Salary Table
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Main Salary Table
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(1.5),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(1.5),
                    },
                    children: [
                      // Table Header
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('EARNING', style: tableHeaderStyle),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Amount', style: tableHeaderStyle),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Deduction & Recoveries',
                              style: tableHeaderStyle,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Amount', style: tableHeaderStyle),
                          ),
                        ],
                      ),

                      // Earnings and Deductions rows
                      ..._buildSalaryRows(
                        earnings,
                        deductions,
                        regularFont,
                        currencySymbol,
                      ),

                      // Total Earnings row
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Amount Total:',
                              style: boldStyle,
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$currencySymbol${totalEarnings.toStringAsFixed(2)}',
                              style: boldStyle,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Amount Total:',
                              style: boldStyle,
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$currencySymbol${totalDeductions.toStringAsFixed(2)}',
                              style: boldStyle,
                            ),
                          ),
                        ],
                      ),

                      // Monthly CTC and Net Pay row
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'MONTHLY CTC:',
                              style: boldStyle,
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$currencySymbol${monthlyCTC.toStringAsFixed(2)}',
                              style: boldStyle,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Net Pay:',
                              style: boldStyle,
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '$currencySymbol${netPay.toStringAsFixed(2)}',
                              style: boldStyle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Second Table for Net Pay in words (no borders)
                  pw.Table(
                    // Only show left, right, and bottom borders
                    // No top border since it attaches to the main table above
                    border: const pw.TableBorder(
                      left: pw.BorderSide(width: 1),
                      right: pw.BorderSide(width: 1),
                      bottom: pw.BorderSide(width: 1),
                    ),
                    columnWidths: {
                      // Single column that spans the full width
                      0: const pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'Net Pay: $amountInWords',
                              style: italicStyle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                ],
              ),

              // Signature section
              pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('From,', style: normalStyle),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      (company['name'] ?? 'MY COMPANY').toUpperCase(),
                      style: boldStyle,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    try {
      return pdf.save();

    } catch (e) {
      print('❌ PDF save failed: $e');
      return await _generateFallbackPDF(
        employee,
        salaryData,
        companyName,
        regularFont,
        boldFont,
        italicFont,
      );
    }
    }
  pw.TableRow _infoRow(
      String l1, String v1,
      String l2, String v2,
      String l3, String v3,
      pw.Font regular,
      pw.Font bold,
      ) {
    return pw.TableRow(
      children: [
        _cell(l1, bold),
        _cell(v1, regular),
        _cell(l2, bold),
        _cell(v2, regular),
        _cell(l3, bold),
        _cell(v3, regular),
      ],
    );
  }

  pw.Widget _cell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 8),
      ),
    );
  }

  Future<Uint8List> _generateFallbackPDF(
      Map<String, dynamic> employee,
      Map<String, dynamic> salaryData,
      String? companyName,
      pw.Font regularFont,
      pw.Font boldFont,
      pw.Font italicFont,
      ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            children: [
              pw.Text('Salary Slip - Fallback Version', style: pw.TextStyle(font: boldFont, fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.Text('Employee: ${employee["fullName"]}'),
              pw.Text('Generated without company logo due to technical issues.'),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper methods for PDF generation
  pw.TableRow _buildTableRow(
    List<String> cells,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.TableRow(
      children: cells.map((cell) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            cell,
            style: cell.contains(':')
                ? pw.TextStyle(font: boldFont, fontSize: 11)
                : pw.TextStyle(font: regularFont, fontSize: 11),
          ),
        );
      }).toList(),
    );
  }
  List<pw.TableRow> _buildSalaryRows(
      Map<String, dynamic> earnings,
      Map<String, dynamic> deductions,
      pw.Font regularFont,
      String currencySymbol,
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

    final rows = <pw.TableRow>[];

    for (int i = 0; i < maxRows; i++) {
      final earn = i < earningItems.length
          ? earningItems[i]
          : {'label': '', 'amount': 0};

      final ded = i < deductionItems.length
          ? deductionItems[i]
          : {'label': '', 'amount': 0};

      rows.add(
        pw.TableRow(
          children: [
            _Newcell(earn['label'], regularFont),
            _cellAmount(earn['amount'], currencySymbol, regularFont),
            _cell(ded['label'], regularFont),
            _cellAmount(ded['amount'], currencySymbol, regularFont),
          ],
        ),
      );
    }

    return rows;
  }
  pw.Widget _Newcell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
    );
  }

  pw.Widget _cellAmount(num amount, String currency, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: pw.Text(
        '$currency${amount.toStringAsFixed(2)}',
        style: pw.TextStyle(font: font, fontSize: 10),
      ),
    );
  }



  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Download individual employee PDF
  // Download individual employee PDF
  Future<void> _handleGenerateSinglePDF(
    Map<String, dynamic> employee,
    int index,
  ) async {
    if (mounted) setState(() => isDownloading = true);

    try {
      final employeeSalary = workData.firstWhere(
        (data) => data["manpowerDetails"]["_id"] == employee["_id"],
        orElse: () => {},
      );

      if (employeeSalary.isEmpty) {
        _showAlert(
          "No Data",
          "No salary data found for ${employee["fullName"]}",
        );
        return;
      }
      await ref.read(userNotifierProvider.notifier).getCurrentUser();
      final user = ref.read(currentUserProvider);

      final companyName = user?.company?.name;
      final companyLogo = user?.company?.logo;




      print('''
==================== 🔥 USER AFTER FETCH 🔥 ====================
${user?.toJson()}
===============================================================
''');



      print('''
==================== 🏢 COMPANY DEBUG START 🏢 ====================
User exists        : ${user != null}
Company exists     : ${user?.company != null}

Company Name       : $companyName
Name is NULL       : ${companyName == null}
Name is EMPTY      : ${companyName?.isEmpty ?? true}

Company Logo       : $companyLogo
Logo is NULL       : ${companyLogo == null}
Logo is EMPTY      : ${companyLogo?.isEmpty ?? true}

Logo looks like URL: ${companyLogo?.startsWith('http') ?? false}
===============================================================
''');

      if (await _requestPermissions()) {
        // Pass company data to PDF generation
        final pdfBytes = await _generateEmployeePDF(
          employee,
          employeeSalary,
          companyName,
          companyLogo,
        );

        final monthName = monthMap.keys.elementAt(selectedMonth! - 1);
        final String? savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Salary Slip',
          fileName:
              'Salary_${employee["fullName"]}_${monthName}_$selectedYear.pdf',
          lockParentWindow: true,
          bytes: pdfBytes,
        );

        if (savePath != null) {
          _showAlert(
            "Success",
            "Salary slip saved for ${employee["fullName"]}",
          );
       // ✅ IMPORTANT

          _showAlert(
            "Success",
            "Salary slip saved for ${employee["fullName"]}",
          );
        } else {
          _showAlert("Cancelled", "Save cancelled for ${employee["fullName"]}");
        }
      }
    } catch (e) {
      print("Error generating PDF: $e");
      _showAlert("Error", "Failed to generate PDF: $e");
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }


  Future<String> _getDownloadsPath() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception("Storage permission denied");
      }

      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        throw Exception("Downloads directory not found");
      }
      return directory.path;
    }

    if (Platform.isIOS) {
      // iOS does NOT allow global Downloads access
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }

    // Windows / macOS / Linux
    final directory = await getDownloadsDirectory();
    if (directory == null) {
      throw Exception("Unable to access Downloads directory");
    }
    return directory.path;
  }

  // Download all PDFs
// Replace the _handleDownloadAllPDFs method with this improved version

// Replace the _handleDownloadAllPDFs method with this improved version
  Future<void> _handleDownloadAllPDFs() async {
    void Function(VoidCallback fn)? dialogSetState;

    if (workData.isEmpty) {
      _showAlert("No Data", "No salary data available to generate PDFs.");
      return;
    }

    if (mounted) setState(() => isDownloading = true);

    try {
      if (await _requestPermissions()) {
        // Step 1: Calculate available PDFs first
        List<Map<String, dynamic>> availableEmployees = [];
        for (var employee in manpowerDataList) {
          final employeeSalary = workData.firstWhere(
                (data) => data["manpowerDetails"]["_id"] == employee["_id"],
            orElse: () => {},
          );
          if (employeeSalary.isNotEmpty) {
            availableEmployees.add(employee);
          }
        }

        if (availableEmployees.isEmpty) {
          _showAlert("No Data", "No salary slips available for the selected period.");
          if (mounted) setState(() => isDownloading = false);
          return;
        }

        // Step 2: Ask user to select download directory ONCE
        final directory = await DownloadPathProvider();
        print(directory.getDownloadPath());
        String? selectedDirectory = await directory.getDownloadPath();
        print(selectedDirectory);

        if (selectedDirectory == null) {
          _showAlert("Cancelled", "Download cancelled. No location selected.");
          if (mounted) setState(() => isDownloading = false);
          return;
        }

        // ✅ FIX 1: Verify directory permissions
        if (!await _verifyDirectoryPermissions(selectedDirectory)) {
          _showAlert(
            "Permission Denied",
            "The selected folder is read-only or you don't have permission to write to it. Please select a different location.",
          );
          if (mounted) setState(() => isDownloading = false);
          return;
        }

        // Step 3: Show progress dialog with real-time updates
        int totalAvailable = availableEmployees.length;
        int currentFile = 0;
        int successCount = 0;
        int failedCount = 0;
        String currentEmployeeName = "";
        List<String> failedEmployees = [];
        String? lastSuccessfulFilePath; // Track last successful download

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                dialogSetState = setDialogState;
                bool isComplete = currentFile >= totalAvailable;
                double progress = totalAvailable > 0 ? currentFile / totalAvailable : 0;

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.all(24),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isComplete
                              ? Colors.green.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isComplete ? Icons.check_circle : Icons.download,
                          color: isComplete ? Colors.green : Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isComplete ? 'Download Complete!' : 'Downloading Salary Slips',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$currentFile of $totalAvailable available',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress percentage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isComplete ? Colors.green : Colors.blue,
                            ),
                          ),
                          Text(
                            '$successCount success, $failedCount failed',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isComplete ? Colors.green : Colors.blue,
                          ),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Current file being processed
                      if (!isComplete && currentEmployeeName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade50,
                                Colors.blue.shade100,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Processing...',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentEmployeeName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue.shade900,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Completion summary
                      if (isComplete)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade50,
                                Colors.green.shade100,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'All available files downloaded!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                Icons.check_circle_outline,
                                'Successfully downloaded',
                                '$successCount files',
                                Colors.green,
                              ),
                              if (failedCount > 0) ...[
                                const SizedBox(height: 6),
                                _buildSummaryRow(
                                  Icons.error_outline,
                                  'Failed to download',
                                  '$failedCount files',
                                  Colors.red,
                                ),
                              ],
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.folder_open,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        selectedDirectory,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[700],
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Failed employees list
                      if (isComplete && failedEmployees.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            'View failed downloads (${failedEmployees.length})',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxHeight: 120),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: failedEmployees.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          size: 14,
                                          color: Colors.red[400],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            failedEmployees[index],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    if (isComplete)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );

        while (dialogSetState == null) {
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Step 4: Generate and save all available PDFs
        await ref.read(userNotifierProvider.notifier).getCurrentUser();
        final user = ref.read(currentUserProvider);

        final companyName = user?.company?.name;
        final companyLogo = user?.company?.logo;

        for (int i = 0; i < availableEmployees.length; i++) {
          final employee = availableEmployees[i];

          // Update dialog state
          if (mounted) {
            dialogSetState?.call(() {
              currentFile = i;
              currentEmployeeName = employee["fullName"] ?? "Unknown";
            });
          }

          final employeeSalary = workData.firstWhere(
                (data) => data["manpowerDetails"]["_id"] == employee["_id"],
            orElse: () => {},
          );

          try {
            final effectiveCompanyName =
                companyName ?? widget.siteModel.siteName ?? 'MY COMPANY';
            final effectiveCompanyLogo = companyLogo;

            final pdfBytes = await _generateEmployeePDF(
              employee,
              employeeSalary,
              effectiveCompanyName,
              effectiveCompanyLogo,
            );

            final monthName = monthMap.keys.elementAt(selectedMonth! - 1);
            final fileName =
                'Salary_${employee["fullName"]}_${monthName}_$selectedYear.pdf';

            // Save file to selected directory

            final filePath = '${selectedDirectory}/$fileName';
            await File(filePath).writeAsBytes(pdfBytes);
            await MediaScanner.loadMedia(path: filePath);


            successCount++;
            lastSuccessfulFilePath = filePath; // Track last successful file
          } catch (e) {
            debugPrint(
              "Error generating PDF for ${employee["fullName"]}: $e",
            );
            failedCount++;
            failedEmployees.add(employee["fullName"] ?? "Unknown");
          }

          // Update progress in dialog
          if (mounted) {
            dialogSetState?.call(() {
              currentFile = i + 1;
            });
          }
        }

        // Mark as complete
        if (mounted) {
          dialogSetState?.call(() {
            currentFile = totalAvailable;
            currentEmployeeName = "";
          });

      }}
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      print("Failed to generate PDFs: $e");
      _showAlert("Error", "Failed to generate PDFs: $e");
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

// ✅ Helper method to verify directory permissions
  Future<bool> _verifyDirectoryPermissions(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);

      // Check if directory exists
      if (!await directory.exists()) {
        return false;
      }

      // Try to create a temporary test file
      final testFilePath = '$directoryPath/.test_write_permission_${DateTime.now().millisecondsSinceEpoch}.tmp';
      final testFile = File(testFilePath);

      try {
        await testFile.writeAsString('test');
        await testFile.delete();
        return true;
      } catch (e) {
        debugPrint("Write permission test failed: $e");
        return false;
      }
    } catch (e) {
      debugPrint("Directory permission check failed: $e");
      return false;
    }
  }


// ✅ Helper method to open folder with platform-specific handling
  Future<void> _openFolder(String directoryPath, String? sampleFilePath) async {
    try {
      // Android-specific handling: Open a file instead of directory
      if (Platform.isAndroid) {
        if (sampleFilePath != null && await File(sampleFilePath).exists()) {
          // Open the PDF file directly - this will show it in the correct folder
          final fileResult = await OpenFile.open(sampleFilePath);
          if (fileResult.type == ResultType.done) {
            return; // Successfully opened file
          }
        }

        // Fallback: Try opening parent directory (usually just opens Downloads)
        await OpenFile.open(directoryPath);
        return;
      }

      // Desktop platforms: Use platform-specific commands
      if (Platform.isWindows) {
        // Windows: Use explorer to open and select the folder
        await Process.run('explorer', [directoryPath]);
        return;
      } else if (Platform.isMacOS) {
        // macOS: Use open command
        await Process.run('open', [directoryPath]);
        return;
      } else if (Platform.isLinux) {
        // Linux: Use xdg-open
        await Process.run('xdg-open', [directoryPath]);
        return;
      }

      // Generic fallback for other platforms
      await OpenFile.open(directoryPath);

    } catch (e) {
      debugPrint("Failed to open folder: $e");
      // Show a helpful message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                Platform.isAndroid
                    ? 'Files saved to:\n$directoryPath\n\nTip: Use a file manager app to browse.'
                    : 'Could not open folder automatically. Files saved to:\n$directoryPath'
            ),
            duration: const Duration(seconds: 5),
            action: Platform.isAndroid && sampleFilePath != null
                ? SnackBarAction(
              label: 'VIEW FILE',
              onPressed: () => OpenFile.open(sampleFilePath),
            )
                : null,
          ),
        );
      }
    }
  }
// ✅ Helper method to verify directory permissions

// // ✅ Helper method to open folder with fallback options
//   Future<void> _openFolder(String directoryPath, String? sampleFilePath) async {
//     print('🔍 [DEBUG] Starting _openFolder with directory: $directoryPath');
//     print('📁 [DEBUG] Sample file path: ${sampleFilePath ?? "null"}');
//
//     try {
//       // Method 1: Try opening the directory directly
//       print('1️⃣ [DEBUG] Attempting Method 1: Open directory via OpenFile plugin');
//       final result = await OpenFile.open(directoryPath);
//       print('📄 [DEBUG] OpenFile result type: ${result.type}');
//       print('📄 [DEBUG] OpenFile message: ${result.message}');
//
//
//       if (result.type == ResultType.done) {
//         print('✅ [DEBUG] Method 1 SUCCESS: Directory opened successfully');
//         return; // Successfully opened
//       } else {
//         print('❌ [DEBUG] Method 1 FAILED: Could not open directory directly');
//       }
//
//       // Method 2: If directory open failed, try opening a sample file from the directory
//       if (sampleFilePath != null) {
//         print('2️⃣ [DEBUG] Attempting Method 2: Open sample file via OpenFile plugin');
//         print('📄 [DEBUG] Checking if sample file exists: $sampleFilePath');
//
//         final fileExists = await File(sampleFilePath).exists();
//         print('📄 [DEBUG] Sample file exists: $fileExists');
//
//         if (fileExists) {
//           final fileResult = await OpenFile.open(sampleFilePath);
//           print('📄 [DEBUG] Sample file open result type: ${fileResult.type}');
//           print('📄 [DEBUG] Sample file open message: ${fileResult.message}');
//
//           if (fileResult.type == ResultType.done) {
//             print('✅ [DEBUG] Method 2 SUCCESS: Sample file opened successfully');
//             return; // Successfully opened file (which shows the folder)
//           } else {
//             print('❌ [DEBUG] Method 2 FAILED: Could not open sample file');
//           }
//         } else {
//           print('⚠️ [DEBUG] Sample file does not exist, skipping Method 2');
//         }
//       } else {
//         print('⚠️ [DEBUG] No sample file path provided, skipping Method 2');
//       }
//
//       // Method 3: Platform-specific fallback using Process.run
//       print('3️⃣ [DEBUG] Attempting Method 3: Platform-specific command');
//       print('📄 [DEBUG] Platform: ${Platform.operatingSystem}');
//
//       if (Platform.isWindows) {
//         print('💻 [DEBUG] Running Windows explorer command');
//         final processResult = await Process.run('explorer', [directoryPath]);
//         print('📄 [DEBUG] Process exit code: ${processResult.exitCode}');
//         print('📄 [DEBUG] Process stdout: ${processResult.stdout}');
//         print('📄 [DEBUG] Process stderr: ${processResult.stderr}');
//
//         if (processResult.exitCode == 0) {
//           print('✅ [DEBUG] Method 3 SUCCESS: Explorer opened folder');
//         } else {
//           print('❌ [DEBUG] Method 3 FAILED: Explorer command failed');
//         }
//
//       } else if (Platform.isMacOS) {
//         print('🍎 [DEBUG] Running macOS open command');
//         final processResult = await Process.run('open', [directoryPath]);
//         print('📄 [DEBUG] Process exit code: ${processResult.exitCode}');
//         print('📄 [DEBUG] Process stdout: ${processResult.stdout}');
//         print('📄 [DEBUG] Process stderr: ${processResult.stderr}');
//
//         if (processResult.exitCode == 0) {
//           print('✅ [DEBUG] Method 3 SUCCESS: Open command executed');
//         } else {
//           print('❌ [DEBUG] Method 3 FAILED: Open command failed');
//         }
//
//       } else if (Platform.isLinux) {
//         print('🐧 [DEBUG] Running Linux xdg-open command');
//         final processResult = await Process.run('xdg-open', [directoryPath]);
//         print('📄 [DEBUG] Process exit code: ${processResult.exitCode}');
//         print('📄 [DEBUG] Process stdout: ${processResult.stdout}');
//         print('📄 [DEBUG] Process stderr: ${processResult.stderr}');
//
//         if (processResult.exitCode == 0) {
//           print('✅ [DEBUG] Method 3 SUCCESS: xdg-open command executed');
//         } else {
//           print('❌ [DEBUG] Method 3 FAILED: xdg-open command failed');
//         }
//       } else {
//         print('⚠️ [DEBUG] Platform not supported for Method 3: ${Platform.operatingSystem}');
//       }
//
//     } catch (e) {
//       print('🚨 [DEBUG] EXCEPTION CAUGHT in _openFolder');
//       print('🚨 [DEBUG] Exception type: ${e.runtimeType}');
//       print('🚨 [DEBUG] Exception message: $e');
//       print('🚨 [DEBUG] Stack trace: ${e.toString()}');
//
//       debugPrint("Failed to open folder: $e");
//
//       // Show a message if all methods fail
//       if (mounted) {
//         print('📱 [DEBUG] Scaffold is mounted, showing SnackBar error message');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Could not open folder automatically. Files saved to:\n$directoryPath'),
//             duration: const Duration(seconds: 4),
//           ),
//         );
//       } else {
//         print('⚠️ [DEBUG] Scaffold not mounted, cannot show SnackBar');
//       }
//     }
//
//     print('🔚 [DEBUG] _openFolder function completed');
//   }
  Widget _buildSummaryRow(
      IconData icon,
      String label,
      String value,
      Color color,
      ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // UI Widgets (keep your existing UI code)
  Widget _buildMonthYearSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDropdown(
                title: "Month",
                value: selectedMonth != null
                    ? monthMap.keys.elementAt(selectedMonth! - 1)
                    : null,
                items: monthMap.keys.toList(),
                onChanged: (val) {
                  setState(() => selectedMonth = monthMap[val]!);
                  _fetchWorkData();
                },
                width: MediaQuery.of(context).size.width * 0.50,
              ),
              _buildDropdown(
                title: "Year",
                value: selectedYear,
                items: yearOptions,
                onChanged: (val) {
                  setState(() => selectedYear = val);
                  _fetchWorkData();
                },
                width: MediaQuery.of(context).size.width * 0.40,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String title,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: "Select $title",
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (manpowerDataList.isEmpty) {
      return Center(
        child: Image.asset(
          "assets/thame/site.png",
          width: 350,
          height: 350,
          fit: BoxFit.contain,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: manpowerDataList.length,
      itemBuilder: (context, index) {
        final employee = manpowerDataList[index];
        final hasSalaryData = workData.any(
          (data) => data["manpowerDetails"]["_id"] == employee["_id"],
        );

        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Theme.of(context).primaryColor),
            ),
            title: Text(
              employee["fullName"] ?? "Unknown",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              employee["designation"] ?? "No Designation",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            trailing: _buildPdfIndicator(hasSalaryData),
            onTap: hasSalaryData && !isDownloading
                ? () => _handleGenerateSinglePDF(employee, index)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildPdfIndicator(bool hasSalaryData) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasSalaryData ? Colors.red.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.picture_as_pdf,
            color: hasSalaryData ? Colors.red : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            "PDF",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: hasSalaryData ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: widget.siteModel.siteName),
      body: BottomButtonWrapper(
        customButtons: [
          if (!isLoading) CustomButton(
            button: RoundedButton(
              text: isDownloading ? 'Saving..' : 'Save All',
              color: isDownloading  ? const Color(0xFF1B6DCE) : Colors.grey,
              textColor: Colors.white,
              onPressed: workData.isNotEmpty && !isDownloading
            ? _handleDownloadAllPDFs
                : (){},
              isOutlined: false,
            ),
          ),
        ],
        child: Column(
          children: [
            _buildMonthYearSelector(),
            const SizedBox(height: 20),
            if (isFetchingWorkData)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(),
              ),
            if (isDownloading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            Expanded(child: _buildEmployeeList()),

          ],
        ),
      ),
    );
  }
}
