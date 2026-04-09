// lib/features/modules/all_Modules/salary/screens/salary_slip_screen.dart
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/features/modules/all_Modules/salary/screens/salary_Detail.dart';

import 'package:untitled2/features/modules/all_Modules/salary/screens/widget/pdf_generator.dart';
import 'package:untitled2/features/modules/all_Modules/salary/service-provider/salaryModel/salary_model.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../core/utlis/widgets/fields/searchableDropdown.dart';
import '../../Manpower Details/service/manPowerProvider.dart';
import '../service-provider/salaryClient.dart';
import '../../../../profile_page/provider/userProvider.dart';

class SalarySlipScreen extends ConsumerStatefulWidget {
  const SalarySlipScreen({super.key});

  @override
  ConsumerState<SalarySlipScreen> createState() => _SalarySlipScreenState();
}

class _SalarySlipScreenState extends ConsumerState<SalarySlipScreen> {
  // ── STATE ──────────────────────────────────────────────────────────────────
  dynamic selectedEmployee;
  int? selectedMonth;
  String? selectedYear;

  bool showLoader = false;
  bool readyToShowButton = false;
  bool isDownloading = false;
  bool isViewingDetails = false;

  List<String> yearOptions = [];

  static const Map<String, int> monthMap = {
    "January": 1, "February": 2, "March": 3, "April": 4,
    "May": 5, "June": 6, "July": 7, "August": 8,
    "September": 9, "October": 10, "November": 11, "December": 12,
  };

  // ── INIT ───────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _generateYearOptions(2020);
    Future.microtask(() {
      final type = ref.read(typeProvider);
      ref.read(manpowerProvider.notifier).fetchManpower(type!);
    });
  }

  void _generateYearOptions(int startYear) {
    final currentYear = DateTime.now().year;
    setState(() {
      yearOptions = List.generate(
        currentYear - startYear + 1,
        (i) => (currentYear - i).toString(),
      );
    });
  }

  // ── SELECTION HANDLERS ─────────────────────────────────────────────────────
  void handleSelectByCode(String code, List manpowerList) {
    try {
      final found = manpowerList.firstWhere((emp) => emp.employeeCode == code);
      setState(() => selectedEmployee = found);
    } catch (_) {
      setState(() => selectedEmployee = null);
    }
    _checkReady(selectedEmployee, selectedMonth, selectedYear);
  }

  void handleSelectByName(String name, List manpowerList) {
    try {
      final found = manpowerList.firstWhere((emp) => emp.fullName == name);
      setState(() => selectedEmployee = found);
    } catch (_) {
      setState(() => selectedEmployee = null);
    }
    _checkReady(selectedEmployee, selectedMonth, selectedYear);
  }

  void handleMonthSelect(int month) {
    setState(() => selectedMonth = month);
    _checkReady(selectedEmployee, month, selectedYear);
  }

  void handleYearSelect(String year) {
    setState(() => selectedYear = year);
    _checkReady(selectedEmployee, selectedMonth, year);
  }

  void _checkReady(dynamic employee, int? month, String? year) {
    if (employee != null && month != null && year != null) {
      setState(() {
        showLoader = true;
        readyToShowButton = false;
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            showLoader = false;
            readyToShowButton = true;
          });
        }
      });
    }
  }

  // ── SALARY DATA ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> _getSalaryData() async {
    try {
      final res = await SalaryAPI.postSalary(
        data: {"id": selectedEmployee.id},
        type: selectedEmployee.type ?? "site",
        month: selectedMonth!,
        year: selectedYear!,
      );
      return res;
    } catch (e) {
      debugPrint("Error getting salary data: $e");
      return null;
    }
  }

  // ── VIEW DETAILS ───────────────────────────────────────────────────────────
  Future<void> _viewDetails() async {
    if (selectedEmployee == null ||
        selectedMonth == null ||
        selectedYear == null) return;

    setState(() => isViewingDetails = true);

    try {
      final salaryData = await _getSalaryData();
      if (salaryData == null) throw Exception("Salary data not available");

      final model = SalaryModel.fromJson(salaryData);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SalaryDetailScreen.single(model: model),
        ),
      );
    } catch (e) {
      debugPrint("Error viewing details: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading details: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isViewingDetails = false);
    }
  }

  // ── PDF DOWNLOAD ───────────────────────────────────────────────────────────
  Future<void> _downloadAndSavePDF() async {
    if (selectedEmployee == null ||
        selectedMonth == null ||
        selectedYear == null) return;

    setState(() => isDownloading = true);

    try {
      final salaryData = await _getSalaryData();
      if (salaryData == null) throw Exception("Salary data not available");

      await ref.read(userNotifierProvider.notifier).getCurrentUser();
      final user = ref.read(currentUserProvider);

      final pdfBytes = await PDFGenerator.generateSalarySlipBytes(
        jsonData: salaryData,
        companyName: user?.company?.name ?? '',
        companyAddress: user?.address ?? '',
        companyLogoUrl: user?.company?.logo,
        selectedMonth: selectedMonth,
      );

      final monthName = monthMap.keys.elementAt(selectedMonth! - 1);
      final fileName =
          'SalarySlip_${selectedEmployee.fullName}_${monthName}_$selectedYear.pdf';

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Salary Slip',
        fileName: fileName,
        lockParentWindow: true,
        bytes: pdfBytes,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(savePath != null
              ? "Salary slip saved successfully!"
              : "Save cancelled."),
          backgroundColor:
              savePath != null ? Colors.green : null,
        ),
      );
    } catch (e) {
      debugPrint("Error generating salary slip: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error generating salary slip: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final manpowerState = ref.watch(manpowerProvider);
    final isBusy = isDownloading || isViewingDetails;

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
                    // Full Name
                    const Text("Full Name",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 6),
                    SearchableDropdown(
                      data: manpowerState.manpowerList
                          .map((emp) => emp.fullName!)
                          .toList(),
                      onSelect: (val) =>
                          handleSelectByName(val, manpowerState.manpowerList),
                      value: selectedEmployee?.fullName,
                      placeholder: "Select Employee",
                      allowAddNew: false,
                      containerDecoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      inputDecoration: const InputDecoration(
                        hintText: "Select Employee",
                        hintStyle: TextStyle(color: Colors.grey),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        border: InputBorder.none,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Employee Code
                    const Text("Employee Code",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 6),
                    SearchableDropdown(
                      data: manpowerState.manpowerList
                          .map((emp) => emp.employeeCode!)
                          .toList(),
                      onSelect: (val) =>
                          handleSelectByCode(val, manpowerState.manpowerList),
                      value: selectedEmployee?.employeeCode,
                      placeholder: "Select Code",
                      allowAddNew: false,
                      containerDecoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      inputDecoration: const InputDecoration(
                        hintText: "Select Code",
                        hintStyle: TextStyle(color: Colors.grey),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        border: InputBorder.none,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Month & Year
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Month",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: selectedMonth != null
                                    ? monthMap.keys
                                        .elementAt(selectedMonth! - 1)
                                    : null,
                                items: monthMap.keys
                                    .map((m) => DropdownMenuItem(
                                        value: m, child: Text(m)))
                                    .toList(),
                                onChanged: (val) =>
                                    handleMonthSelect(monthMap[val]!),
                                decoration: InputDecoration(
                                  hintText: "Select Month",
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
                              const Text("Year",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: selectedYear,
                                items: yearOptions
                                    .map((y) => DropdownMenuItem(
                                        value: y, child: Text(y)))
                                    .toList(),
                                onChanged: (val) =>
                                    handleYearSelect(val!),
                                decoration: InputDecoration(
                                  hintText: "Select Year",
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

                    const SizedBox(height: 30),

                    if (showLoader)
                      const Center(
                          child:
                              CircularProgressIndicator(color: Colors.blue))
                    else if (readyToShowButton)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── View Details ───────────────────────────────
                          ElevatedButton.icon(
                            onPressed: isBusy ? null : _viewDetails,
                            icon: isViewingDetails
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.visibility_rounded,
                                    size: 18, color: Colors.white),
                            label: Text(
                              isViewingDetails
                                  ? 'Loading...'
                                  : 'View Salary Details',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              disabledBackgroundColor:
                                  Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              elevation: 0,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── Download PDF ───────────────────────────────
                          ElevatedButton.icon(
                            onPressed:
                                isBusy ? null : _downloadAndSavePDF,
                            icon: isDownloading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.download_rounded,
                                    size: 18, color: Colors.white),
                            label: Text(
                              isDownloading
                                  ? 'Saving...'
                                  : 'Download Salary Slip',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              disabledBackgroundColor:
                                  Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              elevation: 0,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Back ───────────────────────────────────────
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.black54, width: 1),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
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