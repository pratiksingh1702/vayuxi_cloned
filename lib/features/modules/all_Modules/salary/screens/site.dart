import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/service/manPowerProvider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../pdf_helper.dart';
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

  Future<void> _handleDownloadAllPDFs() async {
    if (workData.isEmpty) {
      _showAlert("No Data", "No salary data available to generate PDFs.");
      return;
    }

    if (mounted) setState(() => isLoading = true);

    try {
      debugPrint("Generating multiple PDFs for ${workData.length} employees");
      if (mounted) {
        Navigator.pushNamed(context, "/salary-Module/salary-dow");
      }
    } catch (e) {
      if (mounted) _showAlert("Error", "Failed to generate PDFs: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleGenerateSinglePDF(Map<String, dynamic> employee, int index) async {
    if (mounted) setState(() => isLoading = true);

    try {
      final employeeSalary = workData.firstWhere(
            (data) => data["manpowerDetails"]["_id"] == employee["_id"],
        orElse: () => {},
      );

      if (employeeSalary.isEmpty) {
        _showAlert("No Data", "No salary data found for ${employee["fullName"]}");
        return;
      }
      await PDFGenerationService.generateEmployeePDF(
        employee: employee,
        salaryData: employeeSalary,
        month: employee.containsKey("month") ? employee["month"] : selectedMonth,
        year: selectedYear!,
      );


      debugPrint("Generating PDF for employee ${employee['_id']}");
      // Add your PDF generation logic here

    } catch (e) {
      print(e);
      if (mounted) _showAlert("Error", "Failed to generate PDF: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
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
                width: MediaQuery.of(context).size.width * 0.40,
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
            onTap: hasSalaryData
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
            onPressed: workData.isNotEmpty ? _handleDownloadAllPDFs : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text(
              "Download All",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFCFE8FA),
        appBar: CustomAppBar(title: widget.siteModel.siteName),
        body: Column(
          children: [
            _buildMonthYearSelector(),
            const SizedBox(height: 20),
            if (isFetchingWorkData)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(),
              ),
            Expanded(child: _buildEmployeeList()),
            if (!isLoading) _buildActionButtons(),
          ],
        ),
      ),
    );
  }
}