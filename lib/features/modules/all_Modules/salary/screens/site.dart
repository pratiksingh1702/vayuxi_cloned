// =============================================================================
// IMPORTS
// =============================================================================
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:media_scanner/media_scanner.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/service/manPowerProvider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../profile_page/provider/userProvider.dart';
import '../service-provider/salaryClient.dart';

// =============================================================================
// SCREEN WIDGET
// =============================================================================

class SiteSalaryScreen extends ConsumerStatefulWidget {
  final SiteModel siteModel;

  const SiteSalaryScreen({super.key, required this.siteModel});

  @override
  ConsumerState<SiteSalaryScreen> createState() => _SiteSalaryScreenState();
}

class _SiteSalaryScreenState extends ConsumerState<SiteSalaryScreen> {
  // =============================================================================
  // STATE VARIABLES
  // =============================================================================

  int? selectedMonth;
  String? selectedYear;
  List<String> yearOptions = [];

  List<Map<String, dynamic>> manpowerDataList = [];
  List<dynamic> workData = [];

  bool isLoading = false;
  bool isFetchingWorkData = false;
  bool isDownloading = false;

  static const Map<String, int> _monthMap = {
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

  // =============================================================================
  // INITIALIZATION
  // =============================================================================

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
          (i) => (currentYear - i).toString(),
    );
  }

  // =============================================================================
  // DATA FETCHING
  // =============================================================================

  Future<void> _fetchManpower() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final type = ref.read(typeProvider);
      if (type == null) return;

      await ref.read(manpowerProvider.notifier).fetchManpower(type);
      final state = ref.read(manpowerProvider);

      if (mounted) {
        setState(() {
          manpowerDataList = state.manpowerList.map((emp) => {
            "_id": emp.id,
            "fullName": emp.fullName ?? "No Name",
            "designation": emp.designation ?? "No Designation",
            "employeeCode": emp.employeeCode,
          }).toList();
        });
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

    if (!mounted) return;
    setState(() => isFetchingWorkData = true);

    try {
      final type = ref.read(typeProvider);
      if (type == null) return;

      final response = await SalaryAPI.fetchSalaryBySite(
        type: type,
        id: widget.siteModel.id,
        month: selectedMonth.toString(),
        year: selectedYear!,
      );

      if (mounted) setState(() => workData = response);
    } catch (e) {
      debugPrint("Error fetching work data: $e");
      if (mounted) _showAlert("Error", "Failed to load salary data");
    } finally {
      if (mounted) setState(() => isFetchingWorkData = false);
    }
  }

  // =============================================================================
  // PDF GENERATION
  // =============================================================================

  Future<pw.MemoryImage?> _loadCompanyLogo(String? imageUrl) async {
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
      debugPrint("Logo load failed: $e");
    }
    return null;
  }

  Future<Uint8List> _generateEmployeePDF(
      Map<String, dynamic> employee,
      Map<String, dynamic> salaryData,
      String? companyName,
      String? companyLogoUrl,
      String userAddress,
      ) async {
    final regularFont =
    pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans-Regular.ttf"));
    final boldFont =
    pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans-Bold.ttf"));
    final italicFont =
    pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSans-Italic.ttf"));

    final companyLogo = await _loadCompanyLogo(companyLogoUrl);

    final manpower = salaryData['manpowerDetails'] as Map<String, dynamic>? ?? {};
    final company = salaryData['companyDetails'] as Map<String, dynamic>? ?? {};
    final earnings = salaryData['earnings'] as Map<String, dynamic>? ?? {};
    final deductions = salaryData['deductions'] as Map<String, dynamic>? ?? {};

    final monthName = _monthMap.keys.elementAt((selectedMonth ?? 1) - 1);
    final totalEarnings = _totalEarnings(earnings);
    final totalDeductions = _totalDeductions(deductions);
    final monthlyCTC = totalEarnings + (deductions['pf'] ?? 0).toDouble();
    final netPay = totalEarnings - totalDeductions;
    const currency = "₹";

    final headerStyle =
    pw.TextStyle(font: boldFont, fontSize: 20, color: PdfColors.blue);
    final normalStyle = pw.TextStyle(font: regularFont, fontSize: 11);
    final boldStyle = pw.TextStyle(font: boldFont, fontSize: 11);
    final tableHeaderStyle = pw.TextStyle(font: boldFont, fontSize: 11);
    final italicStyle = pw.TextStyle(
        font: italicFont, fontSize: 13, fontStyle: pw.FontStyle.italic);

    final amountInWords = netPay >= 0
        ? "Rupees ${_numberToWords(netPay.toInt())} Only"
        : "Negative Rupees ${_numberToWords(netPay.abs().toInt())} Only";

    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
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
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Text('LOGO', style: boldStyle),
              ),
              pw.Expanded(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      (company['name'] ?? companyName ?? 'MY COMPANY').toUpperCase(),

                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 20,
                        color: PdfColors.blue900, // change company name color here
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      userAddress,
                      style: pw.TextStyle(font: regularFont, fontSize: 12),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // Employee Info Table
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
              _infoRow('Pay Slip:', '12', 'Pay Slip for Month:',
                  '$monthName $selectedYear', 'D.O.B.:',
                  _formatDate(manpower['dateOfBirth']), regularFont, boldFont),
              _infoRow('Emp Code:', manpower['employeeCode'] ?? '',
                  'Employee Name:', manpower['fullName'] ?? '',
                  'Designation:', manpower['designation'] ?? '',
                  regularFont, boldFont),
              _infoRow('Aadhar No:', manpower['aaddharNumber'] ?? '',
                  'Department:', manpower['type'] ?? 'N/A',
                  'DOJ:', _formatDate(manpower['dateOfJoining']),
                  regularFont, boldFont),
              _infoRow('ESIC No:', manpower['esicNumber'] ?? '',
                  'UAN No:', manpower['uanNumber'] ?? '',
                  'Total Days:',
                  '${(salaryData['presentDays'] ?? 0) + (salaryData['absentDays'] ?? 0)}',
                  regularFont, boldFont),
              _infoRow('EPF No:', manpower['epfNumber'] ?? '',
                  'Emp PAN No:', manpower['panNumber'] ?? 'N/A',
                  'Days Present:', '${salaryData['presentDays'] ?? 0}',
                  regularFont, boldFont),
            ],
          ),

          pw.SizedBox(height: 15),

          // Salary Table
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
                      child: pw.Text('Net Pay: $amountInWords',
                          style: italicStyle),
                    ),
                  ]),
                ],
              ),
            ],
          ),

          // Signature
          pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('From,', style: normalStyle),
                pw.SizedBox(height: 4),
                pw.Text(
                  (company['name'] ?? companyName ?? 'MY COMPANY').toUpperCase(),
                  style: boldStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    ));

    return pdf.save();
  }

  List<pw.TableRow> _buildSalaryRows(
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

    final maxRows =
    earningItems.length > deductionItems.length ? earningItems.length : deductionItems.length;

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
          child: pw.Text('$currency${(earn['amount'] as num).toStringAsFixed(2)}',
              style: earnStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text(ded['label'] as String, style: dedStyle),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text('$currency${(ded['amount'] as num).toStringAsFixed(2)}',
              style: dedStyle),
        ),
      ]);
    });
  }

  // PDF helper widgets
  pw.Widget _pdfCell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: style),
    );
  }

  pw.Widget _pdfCellRight(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.right),
    );
  }

  pw.TableRow _infoRow(
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
      cell(l1, bold), cell(v1, regular),
      cell(l2, bold), cell(v2, regular),
      cell(l3, bold), cell(v3, regular),
    ]);
  }

  // =============================================================================
  // STORAGE HANDLING
  // =============================================================================

  /// SAF-based single PDF save — no storage permissions needed
  Future<void> _handleGenerateSinglePDF(Map<String, dynamic> employee) async {
    if (selectedMonth == null || selectedYear == null) {
      _showAlert("Selection Required", "Please select month and year first.");
      return;
    }

    setState(() => isDownloading = true);

    try {
      final employeeSalary = workData.firstWhere(
            (d) => d["manpowerDetails"]["_id"] == employee["_id"],
        orElse: () => <String, dynamic>{},
      );

      if ((employeeSalary as Map).isEmpty) {
        _showAlert("No Data", "No salary data found for ${employee["fullName"]}");
        return;
      }

      // Cache provider reads before async gap
      await ref.read(userNotifierProvider.notifier).getCurrentUser();
      final user = ref.read(currentUserProvider);

      final pdfBytes = await _generateEmployeePDF(
        employee,
        Map<String, dynamic>.from(employeeSalary),
        user?.company?.name,
        user?.company?.logo,
        user?.address ?? '',
      );

      final monthName = _monthMap.keys.elementAt(selectedMonth! - 1);
      final fileName =
          'Salary_${employee["fullName"]}_${monthName}_$selectedYear.pdf';

      // Use SAF saveFile dialog — no permission needed
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Salary Slip',
        fileName: fileName,
        lockParentWindow: true,
        bytes: pdfBytes,
      );

      if (!mounted) return;
      if (savePath != null) {
        await MediaScanner.loadMedia(path: savePath);
        _showAlert("Success", "Salary slip saved for ${employee["fullName"]}");
      } else {
        _showAlert("Cancelled", "Save cancelled.");
      }
    } catch (e) {
      debugPrint("Single PDF error: $e");
      if (mounted) _showAlert("Error", "Failed to generate PDF: $e");
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  /// SAF-based bulk PDF save — asks user to pick folder once, then saves all in parallel
  Future<void> _handleDownloadAllPDFs() async {
    if (workData.isEmpty) {
      _showAlert("No Data", "No salary data available.");
      return;
    }

    // Filter employees that have salary data
    final available = manpowerDataList.where((emp) {
      return workData.any((d) => d["manpowerDetails"]["_id"] == emp["_id"]);
    }).toList();

    if (available.isEmpty) {
      _showAlert("No Data", "No salary slips available for the selected period.");
      return;
    }

    // Ask user to select a folder (SAF — no permission required)
    final selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Select folder to save salary slips",
    );

    if (selectedDirectory == null) {
      _showAlert("Cancelled", "No folder selected.");
      return;
    }

    if (!mounted) return;
    setState(() => isDownloading = true);

    // Cache provider reads before loops
    await ref.read(userNotifierProvider.notifier).getCurrentUser();
    final user = ref.read(currentUserProvider);
    final companyName = user?.company?.name;
    final companyLogo = user?.company?.logo;
    final userAddress = user?.address ?? '';

    int successCount = 0;
    int failedCount = 0;
    final failedNames = <String>[];

    _showProgressDialog(available.length, () => successCount, () => failedCount,
            () => failedNames, selectedDirectory);

    // Parallel PDF generation
    await Future.wait(available.map((employee) async {
      try {
        final salaryRaw = workData.firstWhere(
              (d) => d["manpowerDetails"]["_id"] == employee["_id"],
          orElse: () => <String, dynamic>{},
        );
        final salaryData = Map<String, dynamic>.from(salaryRaw as Map);

        final pdfBytes = await _generateEmployeePDF(
          employee,
          salaryData,
          companyName,
          companyLogo,
          userAddress,
        );

        final monthName = _monthMap.keys.elementAt(selectedMonth! - 1);
        final fileName =
            'Salary_${employee["fullName"]}_${monthName}_$selectedYear.pdf';
        final filePath = '$selectedDirectory/$fileName';

        await File(filePath).writeAsBytes(pdfBytes);
        await MediaScanner.loadMedia(path: filePath);

        successCount++;
      } catch (e) {
        debugPrint("PDF error for ${employee["fullName"]}: $e");
        failedCount++;
        failedNames.add(employee["fullName"] ?? "Unknown");
      }
    }));

    if (mounted) setState(() => isDownloading = false);
  }

  void _showProgressDialog(
      int total,
      int Function() getSuccess,
      int Function() getFailed,
      List<String> Function() getFailedNames,
      String directory,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BulkDownloadDialog(
        total: total,
        getSuccess: getSuccess,
        getFailed: getFailed,
        getFailedNames: getFailedNames,
        directory: directory,
      ),
    );
  }

  // =============================================================================
  // HELPERS
  // =============================================================================

  double _totalEarnings(Map<String, dynamic> e) =>
      (e['basic'] ?? 0).toDouble() +
          (e['hra'] ?? 0).toDouble() +
          (e['da'] ?? 0).toDouble() +
          (e['specialAllowance'] ?? 0).toDouble() +
          (e['travelAllowance'] ?? 0).toDouble() +
          (e['medicalAllowance'] ?? 0).toDouble() +
          (e['ot'] ?? 0).toDouble();

  double _totalDeductions(Map<String, dynamic> d) =>
      (d['pf'] ?? 0).toDouble() +
          (d['esi'] ?? 0).toDouble() +
          (d['ptax'] ?? 0).toDouble() +
          (d['lwf'] ?? 0).toDouble() +
          (d['advance'] ?? 0).toDouble();

  String _formatDate(String? s) {
    if (s == null) return '';
    try {
      final d = DateTime.parse(s);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return s;
    }
  }

  String _numberToWords(int num) {
    if (num == 0) return "Zero";
    final isNeg = num < 0;
    if (isNeg) num = -num;

    const units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"];
    const teens = ["Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen",
      "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    const tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty",
      "Sixty", "Seventy", "Eighty", "Ninety"];

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

  void _showAlert(String title, String message) {
    if (!mounted) return;
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

  // =============================================================================
  // UI COMPONENTS
  // =============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: widget.siteModel.siteName),
      body: BottomButtonWrapper(
        customButtons: [
          if (!isLoading)
            CustomButton(
              button: RoundedButton(
                text: isDownloading ? 'Saving...' : 'Save All',
                color:  workData.isNotEmpty && !isDownloading ? const Color(0xFF1B6DCE) : Colors.grey,
                textColor: Colors.white,
                onPressed: workData.isNotEmpty && !isDownloading
                    ? _handleDownloadAllPDFs
                    : () {},
                isOutlined: false,
              ),
            ),
        ],
        child: Column(
          children: [
            _MonthYearSelector(
              selectedMonth: selectedMonth,
              selectedYear: selectedYear,
              yearOptions: yearOptions,
              monthMap: _monthMap,
              onMonthChanged: (val) {
                setState(() => selectedMonth = _monthMap[val]!);
                _fetchWorkData();
              },
              onYearChanged: (val) {
                setState(() => selectedYear = val);
                _fetchWorkData();
              },
            ),
            const SizedBox(height: 8),
            if (isFetchingWorkData || isDownloading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 8),
            Expanded(child: _buildEmployeeList()),
          ],
        ),
      ),
    );
  }
  Widget _buildEmployeeList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    /// ✅ FILTER employees with salary ONLY
    final filteredList = manpowerDataList.where((emp) {
      return workData.any((d) => d["manpowerDetails"]["_id"] == emp["_id"]);
    }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          "No salary data available",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: filteredList.length,
      itemBuilder: (_, index) {
        final emp = filteredList[index];

        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.person,
                  color: Theme.of(context).primaryColor),
            ),
            title: Text(
              emp["fullName"] ?? "Unknown",
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              emp["designation"] ?? "No Designation",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            trailing: const _PdfIndicator(hasSalaryData: true),
            onTap: !isDownloading
                ? () => _handleGenerateSinglePDF(emp)
                : null,
          ),
        );
      },
    );
  }}

// =============================================================================
// SUPPORTING WIDGETS (kept in same file as drop-in replacement)
// =============================================================================

class _MonthYearSelector extends StatelessWidget {
  final int? selectedMonth;
  final String? selectedYear;
  final List<String> yearOptions;
  final Map<String, int> monthMap;
  final ValueChanged<String?> onMonthChanged;
  final ValueChanged<String?> onYearChanged;

  const _MonthYearSelector({
    required this.selectedMonth,
    required this.selectedYear,
    required this.yearOptions,
    required this.monthMap,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final monthValue =
    selectedMonth != null ? monthMap.keys.elementAt(selectedMonth! - 1) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Dropdown(
            title: "Month",
            value: monthValue,
            items: monthMap.keys.toList(),
            onChanged: onMonthChanged,
            width: width * 0.50,
          ),
          _Dropdown(
            title: "Year",
            value: selectedYear,
            items: yearOptions,
            onChanged: onYearChanged,
            width: width * 0.40,
          ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String title;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final double width;

  const _Dropdown({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700])),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: "Select $title",
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfIndicator extends StatelessWidget {
  final bool hasSalaryData;

  const _PdfIndicator({required this.hasSalaryData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasSalaryData ? Colors.red.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf,
              color: hasSalaryData ? Colors.red : Colors.grey, size: 20),
          const SizedBox(width: 4),
          Text("PDF",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: hasSalaryData ? Colors.red : Colors.grey)),
        ],
      ),
    );
  }
}

/// Progress dialog that auto-refreshes using a StreamBuilder polling pattern
class _BulkDownloadDialog extends StatefulWidget {
  final int total;
  final int Function() getSuccess;
  final int Function() getFailed;
  final List<String> Function() getFailedNames;
  final String directory;

  const _BulkDownloadDialog({
    required this.total,
    required this.getSuccess,
    required this.getFailed,
    required this.getFailedNames,
    required this.directory,
  });

  @override
  State<_BulkDownloadDialog> createState() => _BulkDownloadDialogState();
}

class _BulkDownloadDialogState extends State<_BulkDownloadDialog> {
  late final Stream<void> _ticker;

  @override
  void initState() {
    super.initState();
    _ticker =
        Stream.periodic(const Duration(milliseconds: 200)).asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: _ticker,
      builder: (_, __) {
        final success = widget.getSuccess();
        final failed = widget.getFailed();
        final failedNames = widget.getFailedNames();
        final done = success + failed;
        final isComplete = done >= widget.total;
        final hasError = failed > 0;
        final isSuccess = isComplete && !hasError;
        final progress = widget.total > 0 ? done / widget.total : 0.0;

        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: isSuccess
                        ? Colors.green
                        : isComplete
                        ? Colors.red
                        : Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSuccess
                      ? Icons.check_circle
                      : isComplete
                      ? Icons.error
                      : Icons.download,
                  color: isSuccess
                ? Colors.green
                    : isComplete
                ? Colors.red
                  : Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                isSuccess
                ? 'Download Complete!'
                    : isComplete
                    ? 'Download Completed with Errors'
                        : 'Downloading Salary Slips',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$done of ${widget.total}',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isSuccess
                            ? Colors.green
                            : isComplete
                            ? Colors.red
                            : Colors.blue),
                  ),
                  Text('$success success, $failed failed',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isSuccess
                          ? Colors.green
                          : isComplete
                          ? Colors.red
                          : Colors.blue),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 16),
              if (!isComplete)
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              if (isComplete) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
        color: isSuccess
        ? Colors.green.shade50
            : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.folder_open,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.directory,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (failedNames.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Failed: ${failedNames.join(", ")}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.red[700]),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (isComplete)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        );
      },
    );
  }
}