import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/service/manPowerProvider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../service-provider/salaryClient.dart';

class SiteSalaryScreen extends ConsumerStatefulWidget {
  final SiteModel siteModel;

  const SiteSalaryScreen({
    super.key,
    required this.siteModel,
  });

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
        content: const Text("Storage permission is required to save salary slip files."),
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

    final units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"];
    final teens = ["Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    final tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];

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

  // Generate individual employee PDF
  Future<Uint8List> _generateEmployeePDF(Map<String, dynamic> employee, Map<String, dynamic> salaryData) async {
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

    final manpower = salaryData['manpowerDetails'] ?? {};
    final company = salaryData['companyDetails'] ?? {};
    final earnings = salaryData['earnings'] ?? {};
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
    final italicStyle = pw.TextStyle(font: italicFont, fontSize: 13, fontStyle: pw.FontStyle.italic);

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
                  pw.Container(
                    height: 60,
                    width: 60,
                    color: PdfColors.grey.shade(300),
                    child: pw.Center(
                      child: pw.Text('LOGO', style: boldStyle),
                    ),
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
                        child: pw.Text('Amount Total:', style: boldStyle, textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('$currencySymbol${totalEarnings.toStringAsFixed(2)}', style: boldStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Amount Total:', style: boldStyle, textAlign: pw.TextAlign.right),
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
                        child: pw.Text('MONTHLY CTC:', style: boldStyle, textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('$currencySymbol${monthlyCTC.toStringAsFixed(2)}', style: boldStyle),
                      ),
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
                      pw.Container(),
                      pw.Container(),
                      pw.Container(),
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

    return pdf.save();
  }

  // Helper methods for PDF generation
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

  // Download individual employee PDF
  Future<void> _handleGenerateSinglePDF(Map<String, dynamic> employee, int index) async {
    if (mounted) setState(() => isDownloading = true);

    try {
      final employeeSalary = workData.firstWhere(
            (data) => data["manpowerDetails"]["_id"] == employee["_id"],
        orElse: () => {},
      );

      if (employeeSalary.isEmpty) {
        _showAlert("No Data", "No salary data found for ${employee["fullName"]}");
        return;
      }

      if (await _requestPermissions()) {
        final pdfBytes = await _generateEmployeePDF(employee, employeeSalary);

        final monthName = monthMap.keys.elementAt(selectedMonth! - 1);
        final String? savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Salary Slip',
          fileName: 'Salary_${employee["fullName"]}_${monthName}_$selectedYear.pdf',
          lockParentWindow: true,
          bytes: pdfBytes,
        );

        if (savePath != null) {
          _showAlert("Success", "Salary slip saved for ${employee["fullName"]}");
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

  // Download all PDFs
  Future<void> _handleDownloadAllPDFs() async {
    if (workData.isEmpty) {
      _showAlert("No Data", "No salary data available to generate PDFs.");
      return;
    }

    if (mounted) setState(() => isDownloading = true);

    try {
      if (await _requestPermissions()) {
        int successCount = 0;

        for (var employee in manpowerDataList) {
          final employeeSalary = workData.firstWhere(
                (data) => data["manpowerDetails"]["_id"] == employee["_id"],
            orElse: () => {},
          );

          if (employeeSalary.isNotEmpty) {
            try {
              final pdfBytes = await _generateEmployeePDF(employee, employeeSalary);
              final monthName = monthMap.keys.elementAt(selectedMonth! - 1);
              final fileName = 'Salary_${employee["fullName"]}_${monthName}_$selectedYear.pdf';

              final String? savePath = await FilePicker.platform.saveFile(
                dialogTitle: 'Save Salary Slip - ${employee["fullName"]}',
                fileName: fileName,
                lockParentWindow: true,
                bytes: pdfBytes,
              );

              if (savePath != null) {
                successCount++;
              }
            } catch (e) {
              debugPrint("Error generating PDF for ${employee["fullName"]}: $e");
            }
          }
        }

        _showAlert("Complete", "Successfully generated $successCount out of ${workData.length} PDFs");
      }
    } catch (e) {
      _showAlert("Error", "Failed to generate PDFs: $e");
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
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
                .map((item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            ))
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
        final hasSalaryData = workData.any((data) =>
        data["manpowerDetails"]["_id"] == employee["_id"]);

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
              child: Icon(
                Icons.person,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              employee["fullName"] ?? "Unknown",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              employee["designation"] ?? "No Designation",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: workData.isNotEmpty && !isDownloading ? _handleDownloadAllPDFs : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size.fromHeight(50),
            ),
            child: isDownloading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Text(
              "Download All",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: isDownloading ? null : () {
              Navigator.pushNamed(context, "/salary-Module/siteList");
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text("Back"),
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
      body: CornerClippedScreenSimple(
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
            if (!isLoading) _buildActionButtons(),
          ],
        ),
      ),
    );
  }
}