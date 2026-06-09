import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/screens/widgets/popup.dart';
import '../../../../../core/utlis/common_functions.dart';
import '../../../../../core/utlis/widgets/custom_dropdown.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../core/utlis/widgets/fields/phone_number_field.dart';
import '../../../../../core/utlis/widgets/fields/searchableDropdown.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../typeProvider/type_provider.dart';

import '../../../../tour/domain/tour_controller.dart';
import '../../attendance/offline/repo/att_sync.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../../site_Details/providers/siteProvider.dart';
import '../../site_Details/repository/siteModel.dart';
import '../service/manPowerProvider.dart';

import 'dart:math';

class NewManpowerScreen extends ConsumerStatefulWidget {
  const NewManpowerScreen({super.key});

  @override
  ConsumerState<NewManpowerScreen> createState() => _NewManpowerScreenState();
}

class _NewManpowerScreenState extends ConsumerState<NewManpowerScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fullNameController = TextEditingController();
  final _designationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _bankController = TextEditingController();
  final _ifscController = TextEditingController();
  final _epfController = TextEditingController();
  final _uanController = TextEditingController();
  final _esicController = TextEditingController();
  final _salaryController = TextEditingController();
  final _basicSalaryController = TextEditingController();
  final _remarksController = TextEditingController();
  final _daController = TextEditingController();
  final _specialAllowanceController = TextEditingController();
  final _travelAllowanceController = TextEditingController();
  final _medicalAllowanceController = TextEditingController();
  final _hra = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isPfApplicable = true;
  String? _selectedTotalHour;
  bool loading = false;

  // ✅ Selected sites for this manpower
  List<SiteModel> _selectedSites = [];

  final List<String> _designationOptions = [
    "Foreman",
    "Supervisors",
    "Safety Steward",
    "Fitter",
    "Welder",
    "Structural - Fitter/Fabricator",
    "Tack welder",
    "Gas cutter",
    "Grinder",
    "Crane Operator",
    "Man Lift Operator",
    "Farana Operator",
    "Rigger",
    "Helper",
    "Chipper",
    "Khalasi",
    "Labour",
    "Carpenter",
    "Bar bender /Fitter/Steel Fixer",
    "Mason",
    "Welder - Reinforcement",
    "Piping/Mech -Fabricator /Fitter",
    "Welder-Structural / Tank",
    "Welder - Piping / Mech",
    "Plasma / Saw Cutter",
    "Millwright Fitter",
    "Driller/Survey helper",
    "Radiographer",
    "P&M Operator",
    "Site Manager / Site-Incharge",
    "Construction Manager",
    "Planning Manager",
    "QA/QC Engineers/Assistant",
    "Field  Engrs.",
    "Safety personnel",
    "Log./Admn/IT/Secy/Time Keeper",
    "Accts. Personnel",
    "Document controller",
    "Stores Personnel/Material",
    "Technician/Field Surveyor/Mechanic",
    "Electriican/Asst.Electrician",
    "Driver",
    "Discipline Managers/ Leads",
    "Planning Engineers",
  ];
  final List<String> _totalHourOptions =
      List.generate(16, (index) => (index + 1).toString());

  DateTime? _dob;
  DateTime? _doj;
  String _payBasic = "monthly";
  String? _selectedDesignation;
  bool _enableLoginCredentials = false;
  String _generatedOtp = "";

  @override
  void initState() {
    super.initState();
    // Pre-select current site if available
    Future.microtask(() {
      final currentSiteId = ref.read(selectedSiteIdProvider);
      if (currentSiteId != null && currentSiteId.isNotEmpty) {
        final siteState = ref.read(siteProvider);
        final currentSite =
            siteState.sites.where((s) => s.id == currentSiteId).firstOrNull;
        if (currentSite != null && mounted) {
          setState(() => _selectedSites = [currentSite]);
        }
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _designationController.dispose();
    _phoneController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _bankController.dispose();
    _ifscController.dispose();
    _epfController.dispose();
    _uanController.dispose();
    _esicController.dispose();
    _salaryController.dispose();
    _basicSalaryController.dispose();
    _remarksController.dispose();
    _daController.dispose();
    _specialAllowanceController.dispose();
    _travelAllowanceController.dispose();
    _medicalAllowanceController.dispose();
    _hra.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _generateOtp() {
    final random = Random();
    _generatedOtp = (100000 + random.nextInt(900000)).toString();
    _otpController.text = _generatedOtp;
  }

  Future<void> _pickDate(BuildContext context, bool isDOB) async {
    final currentDate = isDOB ? _dob : _doj; // ✅ YOU MISSED THIS
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isDOB)
          _dob = picked;
        else
          _doj = picked;
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _fullNameController.clear();
    _designationController.clear();
    _phoneController.clear();
    _aadhaarController.clear();
    _panController.clear();
    _bankController.clear();
    _ifscController.clear();
    _epfController.clear();
    _uanController.clear();
    _esicController.clear();
    _salaryController.clear();
    _basicSalaryController.clear();
    _remarksController.clear();
    _emailController.clear();
    _otpController.clear();
    _dob = null;
    _doj = null;
    _payBasic = "monthly";
    _selectedDesignation = null;
    _enableLoginCredentials = false;
    _generatedOtp = "";
    _selectedSites = [];
    setState(() {});
  }

  Future<void> _saveManpower() async {
    setState(() => loading = true);

    final manpowerType = ref.read(typeProvider);
    if (manpowerType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No manpower type selected")),
      );
      setState(() => loading = false);
      return;
    }

    if (_fullNameController.text.trim().isEmpty) {
      _showSnack("Full name is required");
      setState(() => loading = false);
      return;
    }

    final designation =
        _selectedDesignation?.trim() ?? _designationController.text.trim();
    if (designation.isEmpty) {
      _showSnack("Designation is required");
      setState(() => loading = false);
      return;
    }

    final salary = double.tryParse(_salaryController.text);
    if (salary == null || salary <= 0) {
      _showSnack("Salary must be greater than 0");
      setState(() => loading = false);
      return;
    }

    // Build sites list — fallback to current site if nothing selected
    List<String> siteIds = _selectedSites.map((s) => s.id).toList();
    if (siteIds.isEmpty) {
      final currentSiteId = ref.read(selectedSiteIdProvider);
      if (currentSiteId != null && currentSiteId.isNotEmpty) {
        siteIds = [currentSiteId];
      }
    }

    final data = <String, dynamic>{
      "fullName": _fullNameController.text,
      "designation": _selectedDesignation ?? _designationController.text,
      "phoneNumber": _phoneController.text,
      "aadharNumber": _aadhaarController.text,
      "panNumber": _panController.text,
      "bankAccountNumber": _bankController.text,
      "ifscCode": _ifscController.text,
      "epfNumber": _epfController.text,
      "uanNumber": _uanController.text,
      "esicNumber": _esicController.text,
      "dateOfBirth": _dob?.toIso8601String(),
      "dateOfJoining": _doj?.toIso8601String(),
      "payBasics": _payBasic,
      "salary": double.tryParse(_salaryController.text) ?? 0,
      "basicSalary": double.tryParse(_basicSalaryController.text) ?? 0,
      "hra": double.tryParse(_hra.text) ?? 0,
      "totalHour": _selectedTotalHour,
      "dearnessAllowance": double.tryParse(_daController.text) ?? 0,
      "specialAllowance":
          double.tryParse(_specialAllowanceController.text) ?? 0,
      "travelAllowance": double.tryParse(_travelAllowanceController.text) ?? 0,
      "medicalAllowance":
          double.tryParse(_medicalAllowanceController.text) ?? 0,
      "pfApplicable": _isPfApplicable,
      "remarks": _remarksController.text,
      if (siteIds.isNotEmpty) "sites": siteIds,
    };

    if (_enableLoginCredentials && _emailController.text.isNotEmpty) {
      data["loginEmail"] = _emailController.text;
      data["loginPassword"] = _otpController.text;
      data["isLoginEnabled"] = true;
    } else {
      data["isLoginEnabled"] = false;
    }

    try {
      final createdManpower = await ref
          .read(manpowerProvider.notifier)
          .addManpower(manpowerType, data);

      await ref.read(tourPersistenceProvider).markManpowerDone();
      final type = ref.read(typeProvider);
      ref.invalidate(manpowerSyncControllerProvider((type: type!)));

      final repo = ref.read(attendanceRepositoryProvider);
      await repo.syncManpowerFromApi(type);

      for (final siteId in siteIds) {
        ref.invalidate(manpowerSyncBySiteControllerProvider(
          (siteId: siteId, type: type),
        ));
      }

      AppToast.success("✅ Manpower added successfully");

      if (_enableLoginCredentials && _emailController.text.isNotEmpty) {
        final employeeCode = createdManpower?.employeeCode ?? "N/A";
        await showDialog(
          context: context,
          builder: (context) => LoginCredentialsPopup(
            employeeCode: employeeCode,
            password: _otpController.text,
          ),
        );
      }

      context.pop();
      context.push("/manpower");
    } catch (e, s) {
      print(s);
      print("Error 😑😑😑😑😑😑😑: $e");
      final message = extractBackendError(e);
      AppToast.error(message);
    } finally {
      setState(() => loading = false);
    }
  }

  void _showSnack(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: colorScheme.error),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SITE MULTI-SELECTOR
  // Uses dropdown_search v6 API — matches AddTeamScreen exactly.
  // Chips are rendered via a custom dropdownBuilder; the popup
  // rows use itemBuilder(context, item, isDisabled, isSelected).
  // ─────────────────────────────────────────────────────────────

  Widget _buildSiteSelector(List<SiteModel> allSites) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Assign to Sites",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        DropdownSearch<SiteModel>.multiSelection(
          // ── data ──
          items: (String filter, LoadProps? props) => allSites
              .where((s) => (s.siteName ?? '')
                  .toLowerCase()
                  .contains(filter.toLowerCase()))
              .toList(),
          selectedItems: _selectedSites,
          itemAsString: (s) => s.siteName ?? s.id,
          compareFn: (a, b) => a.id == b.id,

          onChanged: (values) => setState(() => _selectedSites = values),

          // ── popup: bottom sheet + search box ──
          popupProps: PopupPropsMultiSelection.modalBottomSheet(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search sites...',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            title: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                "Select Sites",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            // ✅ v6 API: 4-arg itemBuilder (context, item, isDisabled, isSelected)
            itemBuilder: (context, item, isDisabled, isSelected) {
              return ListTile(
                dense: true,
                leading: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                title: Text(
                  item.siteName ?? item.id,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDisabled
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            },
          ),

          // ── field decoration ──
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              hintText:
                  _selectedSites.isEmpty ? "Select sites (optional)" : null,
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outlineVariant, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outlineVariant, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
            ),
          ),

          // ✅ v6 API: dropdownBuilder renders what shows INSIDE the field
          // We show chips when items are selected, hint otherwise.
          dropdownBuilder: (context, selectedItems) {
            if (selectedItems.isEmpty) {
              return const SizedBox.shrink(); // hint from decoration handles it
            }
            return Wrap(
              spacing: 6,
              runSpacing: 4,
              children: selectedItems.map((site) {
                return Chip(
                  label: Text(
                    site.siteName ?? site.id,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  backgroundColor: colorScheme.primary,
                  deleteIconColor: colorScheme.onPrimary,
                  onDeleted: () {
                    setState(() {
                      _selectedSites =
                          _selectedSites.where((s) => s.id != site.id).toList();
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            );
          },
        ),

        // Site count hint below the field
        if (_selectedSites.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              "${_selectedSites.length} site${_selectedSites.length == 1 ? '' : 's'} selected",
              style:
                  TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final siteState = ref.watch(siteProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: "New Employee Details"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Full Name ──
              CustomTextField(
                label: "Full Name",
                controller: _fullNameController,
                isRequired: true,
              ),

              // ── Designation ──
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Designation",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 6),
                  SearchableDropdown(
                    data: _designationOptions,
                    onSelect: (value) =>
                        setState(() => _selectedDesignation = value),
                    placeholder: "Search Designation",
                    value: _selectedDesignation,
                    containerDecoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.outlineVariant, width: 1),
                    ),
                    inputDecoration: InputDecoration(
                      hintText: "Search Designation",
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                  ),
                ],
              ),

              // ── Phone ──
              const SizedBox(height: 16),
              PhoneInputField(controller: _phoneController),

              // ── ✅ Site Selector ──
              const SizedBox(height: 16),
              _buildSiteSelector(siteState.sites),

              // ── Login Credentials Toggle ──
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: colorScheme.outlineVariant, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Enable Login Credentials",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface),
                        ),
                        Switch(
                          value: _enableLoginCredentials,
                          onChanged: (value) {
                            setState(() {
                              _enableLoginCredentials = value;
                              if (value) {
                                _generateOtp();
                              } else {
                                _emailController.clear();
                                _otpController.clear();
                                _generatedOtp = "";
                              }
                            });
                          },
                          activeColor: colorScheme.primary,
                        ),
                      ],
                    ),
                    if (_enableLoginCredentials) ...[
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: "Login Email",
                        controller: _emailController,
                        isRequired: true,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: "OTP Password",
                              controller: _otpController,
                              isRequired: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _generateOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Regenerate"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "OTP will be used as initial password",
                        style: TextStyle(
                            fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Aadhar ──
              const SizedBox(height: 16),
              CustomTextField(
                label: "Aadhar Number",
                controller: _aadhaarController,
                isRequired: false,
                keyboardType: TextInputType.number,
              ),

              // ── PAN ──
              const SizedBox(height: 16),
              CustomTextField(
                label: "PAN Number",
                controller: _panController,
                isRequired: false,
              ),

              // ── Bank ──
              const SizedBox(height: 16),
              CustomTextField(
                label: "Bank Account Number",
                controller: _bankController,
                isRequired: false,
                keyboardType: TextInputType.number,
              ),

              // ── IFSC ──
              const SizedBox(height: 16),
              CustomTextField(
                label: "IFSC Code",
                controller: _ifscController,
                isRequired: false,
              ),

              // ── EPF ──
              const SizedBox(height: 16),
              CustomTextField(
                label: "EPF Number",
                controller: _epfController,
                isRequired: false,
                keyboardType: TextInputType.number,
              ),

              // ── UAN ──
              const SizedBox(height: 16),
              CustomTextField(
                label: "UAN Number",
                controller: _uanController,
                isRequired: false,
                keyboardType: TextInputType.number,
              ),

              // ── ESIC ──
              const SizedBox(height: 16),
              CustomTextField(
                label: "ESIC Number",
                controller: _esicController,
                isRequired: false,
                keyboardType: TextInputType.number,
              ),

              // ── Dates ──
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildDatePicker("Date of Birth", _dob, true)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildDatePicker("Date of Joining", _doj, false)),
                ],
              ),

              // ── PF Toggle ──
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: colorScheme.outlineVariant, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("PF Applicable",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface)),
                    Switch(
                      value: _isPfApplicable,
                      activeColor: colorScheme.primary,
                      onChanged: (val) => setState(() => _isPfApplicable = val),
                    ),
                  ],
                ),
              ),

              // ── Pay Basics ──
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pay Basics",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.outlineVariant, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _payBasic,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: InputBorder.none,
                        ),
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: colorScheme.onSurfaceVariant),
                        items: const [
                          DropdownMenuItem(
                              value: "daily", child: Text("Daily")),
                          DropdownMenuItem(
                              value: "monthly", child: Text("Monthly")),
                          DropdownMenuItem(
                              value: "yearly", child: Text("Yearly")),
                          DropdownMenuItem(
                              value: "fixed", child: Text("Fixed")),
                        ],
                        onChanged: (val) => setState(() => _payBasic = val!),
                        dropdownColor: colorScheme.surface,
                        style: TextStyle(
                            fontSize: 15,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Salary ──
              const SizedBox(height: 16),
              CustomTextField(
                label: "Salary",
                controller: _salaryController,
                isRequired: true,
                keyboardType: TextInputType.number,
              ),

              // ── Shift Hour ──
              const SizedBox(height: 20),
              CustomDropdownField<String>(
                label: "Shift Hour",
                value: _selectedTotalHour,
                hint: "Select Total Working Hours",
                items: _totalHourOptions
                    .map((hour) => DropdownMenuItem<String>(
                        value: hour, child: Text(hour)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedTotalHour = value),
              ),

              // ── Basic Salary ──
              const SizedBox(height: 16),
              CustomTextField(
                label: "Basic Salary",
                controller: _basicSalaryController,
                keyboardType: TextInputType.number,
              ),

              // ── DA ──
              const SizedBox(height: 12),
              CustomTextField(
                label: "Dearness Allowance (DA)",
                controller: _daController,
                keyboardType: TextInputType.number,
              ),

              // ── HRA ──
              const SizedBox(height: 12),
              CustomTextField(
                label: "Home Rent Allowance (HRA)",
                controller: _hra,
                keyboardType: TextInputType.number,
              ),

              // ── Special Allowance ──
              const SizedBox(height: 12),
              CustomTextField(
                label: "Special Allowance",
                controller: _specialAllowanceController,
                keyboardType: TextInputType.number,
              ),

              // ── Travel Allowance ──
              const SizedBox(height: 12),
              CustomTextField(
                label: "Travel Allowance",
                controller: _travelAllowanceController,
                keyboardType: TextInputType.number,
              ),

              // ── Medical Allowance ──
              const SizedBox(height: 12),
              CustomTextField(
                label: "Medical Allowance",
                controller: _medicalAllowanceController,
                keyboardType: TextInputType.number,
              ),

              // ── Remarks ──
              const SizedBox(height: 16),
              CustomTextField(
                label: "Remarks",
                controller: _remarksController,
                isRequired: false,
                maxLines: 3,
              ),

              // ── Buttons ──
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: loading ? null : _saveManpower,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: loading
                          ? CircularProgressIndicator(
                              color: colorScheme.onPrimary)
                          : const Text("Save"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Reset"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.surface,
                        foregroundColor: colorScheme.onSurface,
                        side: BorderSide(color: colorScheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Back"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, bool isDOB) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pickDate(context, isDOB),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? "${date.day}-${date.month}-${date.year}"
                      : "Input Text",
                  style: TextStyle(
                      fontSize: 15,
                      color: date != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500),
                ),
                Icon(Icons.calendar_today_rounded,
                    color: colorScheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
