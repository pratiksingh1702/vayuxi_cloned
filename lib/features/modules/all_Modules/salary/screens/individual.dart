import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../Manpower Details/service/manPowerProvider.dart';
import '../service-provider/salaryClient.dart';

class SalarySlipScreen extends ConsumerStatefulWidget {
  const SalarySlipScreen({super.key});

  @override
  ConsumerState<SalarySlipScreen> createState() => _SalarySlipScreenState();
}

class _SalarySlipScreenState extends ConsumerState<SalarySlipScreen> {
  dynamic selectedEmployee;
  int? selectedMonth;
  String? selectedYear;

  bool showLoader = false;
  bool readyToShowButton = false;
  bool isDownloading = false;
  List<String> yearOptions = [];

  final Map<String, int> monthMap = const {
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
    generateYearOptions(2020);
    Future.microtask(() {
      final type = ref.read(typeProvider);
      ref.read(manpowerProvider.notifier).fetchManpower(type!);
    });
  }

  void generateYearOptions(int startYear) {
    final currentYear = DateTime.now().year;
    final years = <String>[];
    for (int y = currentYear; y >= startYear; y--) {
      years.add(y.toString());
    }
    setState(() => yearOptions = years);
  }

  void handleSelectByCode(String code, List manpowerList) {
    try {
      final found = manpowerList.firstWhere((emp) => emp.employeeCode == code);
      setState(() {
        selectedEmployee = found;
      });
    } catch (e) {
      setState(() {
        selectedEmployee = null;
      });
    }
    checkReady(selectedEmployee, selectedMonth, selectedYear);
  }

  void handleSelectByName(String name, List manpowerList) {
    try {
      final found = manpowerList.firstWhere((emp) => emp.fullName == name);
      setState(() {
        selectedEmployee = found;
      });
    } catch (e) {
      setState(() {
        selectedEmployee = null;
      });
    }
    checkReady(selectedEmployee, selectedMonth, selectedYear);
  }

  void handleMonthSelect(int month) {
    setState(() => selectedMonth = month);
    checkReady(selectedEmployee, month, selectedYear);
  }

  void handleYearSelect(String year) {
    setState(() => selectedYear = year);
    checkReady(selectedEmployee, selectedMonth, year);
  }

  void checkReady(dynamic employee, int? month, String? year) {
    if (employee != null && month != null && year != null) {
      setState(() {
        showLoader = true;
        readyToShowButton = false;
      });
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          showLoader = false;
          readyToShowButton = true;
        });
      });
    }
  }



/**/

  // Convert number to words (similar to React Native function)
  String _numberToWords(int num) {
    if (num == 0) return "Zero";

    // Handle negative numbers
    bool isNegative = false;
    if (num < 0) {
      isNegative = true;
      num = -num; // Convert to positive for processing
    }

    final units = [
      "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"
    ];

    final teens = [
      "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen",
      "Sixteen", "Seventeen", "Eighteen", "Nineteen"
    ];

    final tens = [
      "", "", "Twenty", "Thirty", "Forty", "Fifty",
      "Sixty", "Seventy", "Eighty", "Ninety"
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
// Update the _calculateTotalEarnings method to handle your salary structure
  double _calculateTotalEarnings(Map<String, dynamic> earnings) {
    // If all earnings are 0 but there's a base salary, calculate from salary
    final basic = (earnings['basic'] ?? 0).toDouble();
    final hra = (earnings['hra'] ?? 0).toDouble();
    final da = (earnings['da'] ?? 0).toDouble();
    final specialAllowance = (earnings['specialAllowance'] ?? 0).toDouble();
    final travelAllowance = (earnings['travelAllowance'] ?? 0).toDouble();
    final medicalAllowance = (earnings['medicalAllowance'] ?? 0).toDouble();
    final ot = (earnings['ot'] ?? 0).toDouble();

    final total = basic + hra + da + specialAllowance + travelAllowance + medicalAllowance + ot;

    // If total is 0 but there's a salary in the employee data, use that
    if (total == 0 && selectedEmployee?.salary != null) {
      return selectedEmployee.salary.toDouble();
    }

    return total;
  }
  double _calculateTotalDeductions(Map<String, dynamic> deductions) {
    return ((deductions['pf'] ?? 0).toDouble() +
        (deductions['esi'] ?? 0).toDouble() +
        (deductions['ptax'] ?? 0).toDouble() +
        (deductions['lwf'] ?? 0).toDouble() +
        (deductions['advance'] ?? 0).toDouble());
  }

  Future<Uint8List> _generatePDF(Map<String, dynamic> salaryData) async {
    // Load Unicode fonts that support ₹ symbol
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

    final manpower = salaryData['manpowerDetails'];
    final company = salaryData['companyDetails'];
    final earnings = salaryData['earnings'];
    final deductions = salaryData['deductions'];

    final monthName = monthMap.keys.elementAt((selectedMonth ?? 1) - 1);
    final totalEarnings = _calculateTotalEarnings(earnings);
    final totalDeductions = _calculateTotalDeductions(deductions);

    final netPay = totalEarnings - totalDeductions;

    // Handle negative net pay in amountInWords
    final amountInWords = netPay >= 0
        ? "Rupees ${_numberToWords(netPay.toInt())} Only"
        : "Negative Rupees ${_numberToWords(netPay.abs().toInt())} Only";

    // Define styles with proper fonts
    final headerStyle = pw.TextStyle(
      font: boldFont,
      fontSize: 20,
      color: PdfColors.blue.shade(900),
    );

    final normalStyle = pw.TextStyle(font: regularFont, fontSize: 11);
    final boldStyle = pw.TextStyle(font: boldFont, fontSize: 11);
    final tableHeaderStyle = pw.TextStyle(font: boldFont, fontSize: 11);
    final italicStyle = pw.TextStyle(font: italicFont, fontSize: 13, fontStyle: pw.FontStyle.italic);

    // Use "Rs." instead of "₹" if font issues persist, or use this workaround:
    final currencySymbol = "Rs."; // Fallback symbol

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
                  // Logo placeholder
                  pw.Container(
                    height: 60,
                    width: 60,
                    color: PdfColors.grey.shade(300),
                    child: pw.Center(
                      child: pw.Text('LOGO', style: boldStyle),
                    ),
                  ),

                  // Company details - centered
                  pw.Expanded(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          (company['name'] ?? '').toUpperCase(),
                          style: headerStyle,
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'B-101, KRISHNA KUNJ B, RAMJANWADI, VAPI, VALSAD, GUJARAT, 396191',
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
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.2),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.2),
                  5: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  _buildTableRow(['Pay Slip:', '', 'Pay Slip for Month:', '$monthName $selectedYear', 'D.O.B.:', _formatDate(manpower['dateOfBirth'])], regularFont, boldFont),
                  _buildTableRow(['Emp Code:', manpower['employeeCode'] ?? '', 'Employee Name:', manpower['fullName'] ?? '', 'Designation:', manpower['designation'] ?? ''], regularFont, boldFont),
                  _buildTableRow(['Aadhar No:', manpower['aaddharNumber'] ?? '', 'Department:', manpower['type'] ?? 'N/A', 'DOJ:', _formatDate(manpower['dateOfJoining'])], regularFont, boldFont),
                  _buildTableRow(['ESIC No:', manpower['esicNumber'] ?? '', 'UAN No:', manpower['uanNumber'] ?? '', 'Total Days:', '${(salaryData['presentDays'] ?? 0) + (salaryData['absentDays'] ?? 0)}'], regularFont, boldFont),
                  _buildTableRow(['EPF ID:', manpower['epfNumber'] ?? '', 'Emp PAN No:', manpower['panNumber'] ?? 'N/A', 'Days Present:', '${salaryData['presentDays'] ?? 0}'], regularFont, boldFont),
                ],
              ),

              pw.SizedBox(height: 15),

              // Salary Table
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
                        child: pw.Text('Deduction & Recoveries', style: tableHeaderStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Amount', style: tableHeaderStyle),
                      ),
                    ],
                  ),

                  // Earnings and Deductions rows
                  ..._buildSalaryRows(earnings, deductions, regularFont, currencySymbol),

                  // Total Earnings row
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Total Earning:', style: boldStyle, textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('$currencySymbol${totalEarnings.toStringAsFixed(2)}', style: boldStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Total Deduction:', style: boldStyle, textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('$currencySymbol${totalDeductions.toStringAsFixed(2)}', style: boldStyle),
                      ),
                    ],
                  ),

                  // Monthly CTC and Net Pay row
                  pw.TableRow(
                    children: [

                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Net Pay:', style: boldStyle, textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('$currencySymbol${netPay.toStringAsFixed(2)}', style: boldStyle),
                      ),
                    ],
                  ),

                  // Net Pay in words row
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
                      (company['name'] ?? '').toUpperCase(),
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

    return pdf.save();
  }

// Updated helper methods with font parameters
  pw.TableRow _buildTableRow(List<String> cells, pw.Font regularFont, pw.Font boldFont) {
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

  List<pw.TableRow> _buildSalaryRows(Map<String, dynamic> earnings, Map<String, dynamic> deductions, pw.Font regularFont, String currencySymbol) {
    final earningItems = [
      {'label': 'Basic', 'amount': earnings['basic'] ?? 0},
      {'label': 'H.R.A', 'amount': earnings['hra'] ?? 0},
      {'label': 'D.A', 'amount': earnings['da'] ?? 0},
      {'label': 'Special Allowance', 'amount': earnings['specialAllowance'] ?? 0},
      {'label': 'Travel Allowance', 'amount': earnings['travelAllowance'] ?? 0},
      {'label': 'Medical Allowance', 'amount': earnings['medicalAllowance'] ?? 0},
      {'label': 'OT', 'amount': earnings['ot'] ?? 0},
    ];

    final deductionItems = [
      {'label': 'PF', 'amount': deductions['pf'] ?? 0},
      {'label': 'ESI', 'amount': deductions['esi'] ?? 0},
      {'label': 'P TAX', 'amount': deductions['ptax'] ?? 0},
      {'label': 'LWF', 'amount': deductions['lwf'] ?? 0},
      {'label': 'ADVANCE', 'amount': deductions['advance'] ?? 0},
    ];

    // Filter out zero values
    final nonZeroEarnings = earningItems.where((item) => (item['amount'] as num) > 0).toList();
    final nonZeroDeductions = deductionItems.where((item) => (item['amount'] as num) > 0).toList();

    final maxRows = nonZeroEarnings.length > nonZeroDeductions.length ? nonZeroEarnings.length : nonZeroDeductions.length;
    final rows = <pw.TableRow>[];

    for (int i = 0; i < maxRows; i++) {
      final earn = i < nonZeroEarnings.length ? nonZeroEarnings[i] : {'label': '', 'amount': 0};
      final ded = i < nonZeroDeductions.length ? nonZeroDeductions[i] : {'label': '', 'amount': 0};

      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(earn['label'], style: pw.TextStyle(font: regularFont, fontSize: 11)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('$currencySymbol${(earn['amount'] as num).toStringAsFixed(2)}', style: pw.TextStyle(font: regularFont, fontSize: 11)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(ded['label'], style: pw.TextStyle(font: regularFont, fontSize: 11)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('$currencySymbol${(ded['amount'] as num).toStringAsFixed(2)}', style: pw.TextStyle(font: regularFont, fontSize: 11)),
            ),
          ],
        ),
      );
    }

    return rows;
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
  Future<void> _downloadAndSavePDF() async {
    if (selectedEmployee == null || selectedMonth == null || selectedYear == null) return;


      setState(() => isDownloading = true);

      try {
        final salaryData = await _getSalaryData();

        if (salaryData == null) {
          throw Exception("Salary data not available");
        }

        // Generate PDF bytes
        final pdfBytes = await _generatePDF(salaryData);

        // For Android & iOS, we need to use the bytes parameter
        final monthName = monthMap.keys.elementAt(selectedMonth! - 1);
        final String? savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Salary Slip',
          fileName: 'SalarySlip_${selectedEmployee.fullName}_${monthName}_$selectedYear.pdf',
          lockParentWindow: true,
          bytes: pdfBytes, // Add this line - provide the bytes directly
        );

        if (savePath != null) {
          // The file is already saved by FilePicker when using bytes parameter
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Salary slip saved successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // User canceled the save dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Save canceled")),
          );
        }
      } catch (e) {
        debugPrint("Error generating salary slip: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error generating salary slip: $e"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => isDownloading = false);
      }

  }
  Future<Map<String, dynamic>?> _getSalaryData() async {
    try {
      final res = await SalaryAPI.postSalary(
        data: {"id": selectedEmployee.id},
        type: selectedEmployee.type ?? "site",
        month: selectedMonth!,
        year: selectedYear!,
      );

      print("Salary API Response: $res");
      return res;
    } catch (e) {
      debugPrint("Error getting salary data: $e");
      return null;
    }
  }

  Future<void> handleSubmit() async {
    await _downloadAndSavePDF();
  }

  @override
  Widget build(BuildContext context) {
    final manpowerState = ref.watch(manpowerProvider);

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "Salary Slip"),
      body: manpowerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Your existing UI code remains the same...
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Full Name",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedEmployee?.fullName,
                    items: manpowerState.manpowerList
                        .map((emp) => DropdownMenuItem(
                      value: emp.fullName,
                      child: Text(emp.fullName!),
                    ))
                        .toList(),
                    onChanged: (val) => handleSelectByName(
                        val!, manpowerState.manpowerList),
                    decoration: InputDecoration(
                      hintText: "Placeholder",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    "Employee Code",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedEmployee?.employeeCode,
                    items: manpowerState.manpowerList
                        .map((emp) => DropdownMenuItem(
                      value: emp.employeeCode,
                      child: Text(emp.employeeCode!),
                    ))
                        .toList(),
                    onChanged: (val) => handleSelectByCode(
                        val!, manpowerState.manpowerList),
                    decoration: InputDecoration(
                      hintText: "Placeholder",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Month",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedMonth != null
                                  ? monthMap.keys
                                  .elementAt(selectedMonth! - 1)
                                  : null,
                              items: monthMap.keys
                                  .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m),
                              ))
                                  .toList(),
                              onChanged: (val) =>
                                  handleMonthSelect(monthMap[val]!),
                              decoration: InputDecoration(
                                hintText: "Input Text",
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Year",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedYear,
                              items: yearOptions
                                  .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text(y),
                              ))
                                  .toList(),
                              onChanged: (val) => handleYearSelect(val!),
                              decoration: InputDecoration(
                                hintText: "Input Text",
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              if (showLoader)
                const Center(
                    child:
                    CircularProgressIndicator(color: Colors.blue))
              else if (readyToShowButton)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Download the Salary Slip",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side:
                        const BorderSide(color: Colors.black54, width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Back"),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}