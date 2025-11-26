import 'dart:io';
import 'dart:convert'; // Add this import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
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

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      PermissionStatus status;
      if (Platform.isAndroid) {
        status = await Permission.manageExternalStorage.request();
      } else {
        status = await Permission.storage.request();
      }

      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        _showPermissionDialog();
        return false;
      }
      return false;
    } else if (Platform.isIOS) {
      return true;
    }
    return true;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
            "Storage permission is required to save salary slip files. "
                "Please grant the permission in app settings."),
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

  // Generate CSV content from salary data
  String _generateCSVContent(Map<String, dynamic> salaryData) {
    final manpower = salaryData['manpowerDetails'];
    final company = salaryData['companyDetails'];
    final earnings = salaryData['earnings'];
    final deductions = salaryData['deductions'];

    final monthName = monthMap.keys.elementAt((selectedMonth ?? 1) - 1);

    // Create CSV content
    final csvContent = StringBuffer();

    // Header
    csvContent.writeln('Salary Slip,$monthName $selectedYear');
    csvContent.writeln('Company:,${company['name']}');
    csvContent.writeln();

    // Employee Details
    csvContent.writeln('Employee Details');
    csvContent.writeln('Employee Name:,${manpower['fullName']}');
    csvContent.writeln('Employee Code:,${manpower['employeeCode']}');
    csvContent.writeln('Designation:,${manpower['designation']}');
    csvContent.writeln('Department:,${manpower['type']}');
    csvContent.writeln();

    // Attendance Summary
    csvContent.writeln('Attendance Summary');
    csvContent.writeln('Present Days:,${salaryData['presentDays']}');
    csvContent.writeln('Absent Days:,${salaryData['absentDays']}');
    csvContent.writeln('Total Working Days:,${(salaryData['presentDays'] ?? 0) + (salaryData['absentDays'] ?? 0)}');
    csvContent.writeln('Total Hours:,${salaryData['totalHours']}');
    csvContent.writeln();

    // Earnings
    csvContent.writeln('Earnings,Amount (₹)');
    csvContent.writeln('Basic Salary:,${earnings['basic']}');
    csvContent.writeln('HRA:,${earnings['hra']}');
    csvContent.writeln('DA:,${earnings['da']}');
    csvContent.writeln('Special Allowance:,${earnings['specialAllowance']}');
    csvContent.writeln('Travel Allowance:,${earnings['travelAllowance']}');
    csvContent.writeln('Medical Allowance:,${earnings['medicalAllowance']}');
    csvContent.writeln('Overtime:,${earnings['ot']}');
    csvContent.writeln('Total Earnings:,${_calculateTotalEarnings(earnings)}');
    csvContent.writeln();

    // Deductions
    csvContent.writeln('Deductions,Amount (₹)');
    csvContent.writeln('Provident Fund (PF):,${deductions['pf']}');
    csvContent.writeln('ESI:,${deductions['esi']}');
    csvContent.writeln('Professional Tax:,${deductions['ptax']}');
    csvContent.writeln('Labour Welfare Fund:,${deductions['lwf']}');
    csvContent.writeln('Advance:,${deductions['advance']}');
    csvContent.writeln('Total Deductions:,${_calculateTotalDeductions(deductions)}');
    csvContent.writeln();

    // Summary
    csvContent.writeln('Summary,Amount (₹)');
    csvContent.writeln('Gross Salary:,${_calculateTotalEarnings(earnings)}');
    csvContent.writeln('Total Deductions:,${_calculateTotalDeductions(deductions)}');
    csvContent.writeln('Net Salary:,${salaryData['finalSalary']}');
    csvContent.writeln();

    // Footer
    csvContent.writeln('Generated on:,${DateTime.now().toLocal()}');
    csvContent.writeln('This is a computer generated salary slip');

    return csvContent.toString();
  }

  // Fixed calculation functions with proper type handling
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

  Future<void> _downloadAndSaveCSV() async {
    if (selectedEmployee == null || selectedMonth == null || selectedYear == null) return;

    if (await _requestPermissions()) {
      setState(() => isDownloading = true);

      try {
        // Get salary data from API
        final salaryData = await _getSalaryData();

        if (salaryData == null) {
          throw Exception("Salary data not available");
        }

        // Generate CSV content
        final csvContent = _generateCSVContent(salaryData);

        // Convert to bytes
        final csvBytes = utf8.encode(csvContent);

        // Ask user where to save the file
        final monthName = monthMap.keys.elementAt(selectedMonth! - 1);
        final String? savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Salary Slip',
          fileName: 'Salary_Slip_${selectedEmployee.fullName}_${monthName}_$selectedYear.csv',
          lockParentWindow: true,
          bytes: csvBytes
        );

        if (savePath != null) {
          // Save the file
          final File file = File(savePath);
          await file.writeAsBytes(csvBytes );

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
    await _downloadAndSaveCSV();
  }

  @override
  Widget build(BuildContext context) {
    final manpowerState = ref.watch(manpowerProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBlue, // light blue bg like design
      appBar: CustomAppBar(title: "Salary Slip"),
      body: manpowerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔹 White Card Container for inputs
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name
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
                      child: Text(emp.fullName),
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
                      child: Text(emp.employeeCode),
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

                  // 🔹 Month & Year Row
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

              // Loader or Buttons
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