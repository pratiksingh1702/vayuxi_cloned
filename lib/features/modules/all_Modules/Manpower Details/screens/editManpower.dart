import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/screens/widgets/popup.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../../../../../core/utlis/widgets/custom_dropdown.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../core/utlis/widgets/fields/phone_number_field.dart';
import '../../../../../core/utlis/widgets/fields/searchableDropdown.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../attendance/offline/repo/att_sync.dart';

import '../../site_Details/repository/siteModel.dart';
import '../model/manpower_model.dart';
import '../service/manPowerProvider.dart';
import 'dart:math';
import '../../site_Details/providers/siteProvider.dart';

class EditManpowerScreen extends ConsumerStatefulWidget {
  final ManpowerModel manpower;
  const EditManpowerScreen({super.key, required this.manpower});

  @override
  ConsumerState<EditManpowerScreen> createState() => _EditManpowerScreenState();
}

class _EditManpowerScreenState extends ConsumerState<EditManpowerScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _designationController;
  late TextEditingController _phoneController;
  late TextEditingController _panController;
  late TextEditingController _bankController;
  late TextEditingController _ifscController;
  late TextEditingController _epfController;
  late TextEditingController _uanController;
  late TextEditingController _esicController;
  late TextEditingController _salaryController;
  late TextEditingController _remarksController;
  late TextEditingController _emailController;
  late TextEditingController _otpController;
  late TextEditingController _aadhaarController;
  late TextEditingController _basicSalaryController;
  late TextEditingController _hraController;
  late TextEditingController _daController;
  late TextEditingController _specialAllowanceController;
  late TextEditingController _travelAllowanceController;
  late TextEditingController _medicalAllowanceController;

  bool _isPfApplicable = true;
  DateTime? _dob;
  DateTime? _doj;
  String _payBasic = "monthly";
  bool _enableLoginCredentials = false;
  String _generatedOtp = "";
  String? _selectedTotalHour;

  // ✅ Pre-filled selected sites
  List<SiteModel> _selectedSites = [];
  // Track whether sites have been loaded from the provider yet
  bool _sitesInitialized = false;

  final List<String> _totalHourOptions =
      List.generate(16, (index) => (index + 1).toString());

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

  @override
  void initState() {
    super.initState();
    final m = widget.manpower;

    _fullNameController = TextEditingController(text: m.fullName);
    _designationController = TextEditingController(text: m.designation);
    _phoneController = TextEditingController(text: m.phoneNumber ?? "");
    _panController = TextEditingController(text: m.panNumber ?? "");
    _bankController = TextEditingController(text: m.bankAccountNumber ?? "");
    _ifscController = TextEditingController(text: m.ifscCode ?? "");
    _epfController = TextEditingController(text: m.epfNumber ?? "");
    _uanController = TextEditingController(text: m.uanNumber ?? "");
    _esicController = TextEditingController(text: m.esicNumber ?? "");
    _salaryController = TextEditingController(text: m.salary?.toString() ?? "");
    _remarksController = TextEditingController(text: m.remarks ?? "");
    _aadhaarController = TextEditingController(text: m.aadharNumber ?? "");
    _basicSalaryController =
        TextEditingController(text: m.basicSalary?.toString() ?? "");
    _hraController = TextEditingController(text: m.hra?.toString() ?? "");
    _daController =
        TextEditingController(text: m.dearnessAllowance?.toString() ?? "");
    _specialAllowanceController =
        TextEditingController(text: m.specialAllowance?.toString() ?? "");
    _travelAllowanceController =
        TextEditingController(text: m.travelAllowance?.toString() ?? "");
    _medicalAllowanceController =
        TextEditingController(text: m.medicalAllowance?.toString() ?? "");

    _payBasic = m.payBasics ?? "monthly";
    _selectedTotalHour = m.totalHour?.toString();
    _isPfApplicable = m.pfApplicable ?? true;

    _emailController = TextEditingController(text: m.loginEmail ?? "");
    _otpController =
        TextEditingController(text: "Regenerate to use new password");
    _enableLoginCredentials = (m.loginEmail?.isNotEmpty ?? false);
    if (_enableLoginCredentials &&
        (m.loginPassword == null || m.loginPassword!.isEmpty)) {
      _generateOtp();
    }

    if (m.dateOfBirth != null) _dob = DateTime.tryParse(m.dateOfBirth!);
    if (m.dateOfJoining != null) _doj = DateTime.tryParse(m.dateOfJoining!);

    // ✅ Pre-fill sites once the provider has loaded
    Future.microtask(() => _initSelectedSites());
  }

  /// Match the manpower's sites list against the loaded SiteModel list
  /// so we can show chips for sites that are already assigned.
  void _initSelectedSites() {
    if (!mounted) return;
    final allSites = ref.read(siteProvider).sites;
    final manpowerSiteIds = widget.manpower.sites; // List<String>

    final matched =
        allSites.where((s) => manpowerSiteIds.contains(s.id)).toList();

    if (mounted) {
      setState(() {
        _selectedSites = matched;
        _sitesInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _designationController.dispose();
    _phoneController.dispose();
    _panController.dispose();
    _bankController.dispose();
    _ifscController.dispose();
    _epfController.dispose();
    _uanController.dispose();
    _esicController.dispose();
    _salaryController.dispose();
    _remarksController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _aadhaarController.dispose();
    _basicSalaryController.dispose();
    _hraController.dispose();
    _daController.dispose();
    _specialAllowanceController.dispose();
    _travelAllowanceController.dispose();
    _medicalAllowanceController.dispose();
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
        lastDate: DateTime.now());
    if (picked != null) {
      setState(() {
        if (isDOB)
          _dob = picked;
        else
          _doj = picked;
      });
    }
  }

  Future<void> _updateManpower() async {
    if (!_formKey.currentState!.validate()) return;

    final manpowerType = ref.read(typeProvider);
    if (manpowerType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No manpower type selected")),
      );
      return;
    }

    final siteIds = _selectedSites.map((s) => s.id).toList();

    final data = <String, dynamic>{
      "fullName": _fullNameController.text,
      "designation": _designationController.text,
      "phoneNumber": _phoneController.text,
      "aadharNumber": _aadhaarController.text,
      "panNumber": _panController.text,
      "bankAccountNumber": _bankController.text,
      "ifscCode": _ifscController.text,
      "epfNumber": _epfController.text,
      "uanNumber": _uanController.text,
      "esicNumber": _esicController.text,
      "totalHour": _selectedTotalHour,
      "dateOfBirth": _dob?.toIso8601String(),
      "dateOfJoining": _doj?.toIso8601String(),
      "payBasics": _payBasic,
      "salary": double.tryParse(_salaryController.text) ?? 0,
      "basicSalary": double.tryParse(_basicSalaryController.text) ?? 0,
      "hra": double.tryParse(_hraController.text) ?? 0,
      "dearnessAllowance": double.tryParse(_daController.text) ?? 0,
      "specialAllowance":
          double.tryParse(_specialAllowanceController.text) ?? 0,
      "travelAllowance": double.tryParse(_travelAllowanceController.text) ?? 0,
      "medicalAllowance":
          double.tryParse(_medicalAllowanceController.text) ?? 0,
      "pfApplicable": _isPfApplicable,
      "remarks": _remarksController.text,
      // ✅ Always send updated sites
      if (siteIds.isNotEmpty) "sites": siteIds,
    };

    if (_enableLoginCredentials && _emailController.text.isNotEmpty) {
      data["loginEmail"] = _emailController.text;
      if (_otpController.text.isNotEmpty) {
        data["loginPassword"] = _otpController.text;
      }
      data["isLoginEnabled"] = true;
    } else {
      data["isLoginEnabled"] = false;
      data["loginEmail"] = null;
      data["loginPassword"] = null;
    }

    try {
      debugPrint("Sending totalHour: $_selectedTotalHour");
      final updatedManpower = await ref
          .read(manpowerProvider.notifier)
          .updateManpower(widget.manpower.id!, data, manpowerType);

      final type = ref.read(typeProvider);
      ref.invalidate(manpowerSyncControllerProvider((type: type!)));

      // Invalidate site-scoped sync for every assigned site
      for (final siteId in siteIds) {
        ref.invalidate(
            manpowerSyncBySiteControllerProvider((siteId: siteId, type: type)));
      }

      if (updatedManpower == null) {
        throw Exception("Failed to update manpower");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Manpower updated successfully")),
      );

      if (_enableLoginCredentials &&
          _emailController.text.isNotEmpty &&
          _otpController.text.isNotEmpty) {
        final employeeCode = updatedManpower.employeeCode ??
            widget.manpower.employeeCode ??
            "N/A";
        await showDialog(
          context: context,
          builder: (context) => LoginCredentialsPopup(
            employeeCode: employeeCode,
            password: _otpController.text,
          ),
        );
      }

      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SITE MULTI-SELECTOR  (v6 DropdownSearch API)
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

          // ── bottom-sheet popup + search ──
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
            // ✅ v6: 4-arg itemBuilder
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

          // ── field border ──
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

          // ✅ v6: dropdownBuilder — chips inside the field
          dropdownBuilder: (context, selectedItems) {
            if (selectedItems.isEmpty) {
              return const SizedBox.shrink();
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
    // ✅ Watch siteProvider so chips update if sites load after initState
    final siteState = ref.watch(siteProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Lazy-init: once sites are available and we haven't matched yet, do it now
    if (!_sitesInitialized && siteState.sites.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initSelectedSites());
    }

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(title: "Edit Employee Details"),
          ];
        },
        body: BottomButtonWrapper(
          customButtons: [
            CustomButton(
              button: RoundedButton(
                text: "Save & Submit",
                color: colorScheme.primary,
                textColor: colorScheme.onPrimary,
                onPressed: _updateManpower,
              ),
            )
          ],
          child: SingleChildScrollView(
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
                  SearchableDropdown(
                    data: _designationOptions,
                    value: _designationController.text,
                    onSelect: (value) {
                      setState(() => _designationController.text = value);
                    },
                  ),

                  // ── Phone ──
                  const SizedBox(height: 16),
                  PhoneInputField(controller: _phoneController),

                  // ── ✅ Site Selector (pre-filled) ──
                  const SizedBox(height: 16),
                  _buildSiteSelector(siteState.sites),

                  // ── Login Credentials Toggle ──
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.outlineVariant, width: 1.5),
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
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Switch(
                              value: _enableLoginCredentials,
                              onChanged: (value) {
                                setState(() {
                                  _enableLoginCredentials = value;
                                  if (value) {
                                    if (_emailController.text.isEmpty) {
                                      final name = _fullNameController.text
                                          .toLowerCase()
                                          .replaceAll(' ', '');
                                      _emailController.text =
                                          "$name${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}@gmail.com";
                                    }
                                    if (_otpController.text.isEmpty) {
                                      _generateOtp();
                                    }
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
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text("Regenerate"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "OTP will be used as password. Leave empty to keep current password.",
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Aadhar ──
                  CustomTextField(
                    label: "Aadhar Number",
                    controller: _aadhaarController,
                    keyboardType: TextInputType.number,
                  ),

                  // ── PAN ──
                  CustomTextField(
                    label: "PAN Number",
                    controller: _panController,
                    isRequired: false,
                  ),

                  // ── Bank ──
                  CustomTextField(
                    label: "Bank Account Number",
                    controller: _bankController,
                    isRequired: false,
                    keyboardType: TextInputType.number,
                  ),

                  // ── IFSC ──
                  CustomTextField(
                    label: "IFSC Code",
                    controller: _ifscController,
                    isRequired: false,
                  ),

                  // ── EPF ──
                  CustomTextField(
                    label: "EPF Number",
                    controller: _epfController,
                    isRequired: false,
                    keyboardType: TextInputType.number,
                  ),

                  // ── UAN ──
                  CustomTextField(
                    label: "UAN Number",
                    controller: _uanController,
                    isRequired: false,
                    keyboardType: TextInputType.number,
                  ),

                  // ── ESIC ──
                  CustomTextField(
                    label: "ESIC Number",
                    controller: _esicController,
                    isRequired: false,
                    keyboardType: TextInputType.number,
                  ),

                  // ── Dates ──
                  Row(
                    children: [
                      Expanded(
                          child: _buildDatePicker("Date of Birth", _dob, true)),
                      const SizedBox(width: 8),
                      Expanded(
                          child:
                              _buildDatePicker("Date of Joining", _doj, false)),
                    ],
                  ),

                  // ── PF + Pay Basics ──
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: colorScheme.outlineVariant, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "PF Applicable",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface),
                            ),
                            Switch(
                              value: _isPfApplicable,
                              activeColor: colorScheme.primary,
                              onChanged: (val) =>
                                  setState(() => _isPfApplicable = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Pay Basics",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
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
                              offset: const Offset(0, 2),
                            ),
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
                                  value: "monthly", child: Text("Monthly")),
                              DropdownMenuItem(
                                  value: "daily", child: Text("Daily")),
                              DropdownMenuItem(
                                  value: "yearly", child: Text("Yearly")),
                              DropdownMenuItem(
                                  value: "fixed", child: Text("Fixed")),
                            ],
                            onChanged: (val) =>
                                setState(() => _payBasic = val!),
                            dropdownColor: colorScheme.surface,
                            style: TextStyle(
                              fontSize: 15,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Salary ──
                  const SizedBox(height: 10),
                  CustomTextField(
                    label: "Salary",
                    controller: _salaryController,
                    isRequired: true,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // ── Shift Hour ──
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
                  CustomTextField(
                    label: "Basic Salary",
                    controller: _basicSalaryController,
                    keyboardType: TextInputType.number,
                  ),

                  // ── HRA ──
                  CustomTextField(
                    label: "HRA",
                    controller: _hraController,
                    keyboardType: TextInputType.number,
                  ),

                  // ── DA ──
                  CustomTextField(
                    label: "Dearness Allowance (DA)",
                    controller: _daController,
                    keyboardType: TextInputType.number,
                  ),

                  // ── Special Allowance ──
                  CustomTextField(
                    label: "Special Allowance",
                    controller: _specialAllowanceController,
                    keyboardType: TextInputType.number,
                  ),

                  // ── Travel Allowance ──
                  CustomTextField(
                    label: "Travel Allowance",
                    controller: _travelAllowanceController,
                    keyboardType: TextInputType.number,
                  ),

                  // ── Medical Allowance ──
                  CustomTextField(
                    label: "Medical Allowance",
                    controller: _medicalAllowanceController,
                    keyboardType: TextInputType.number,
                  ),

                  // ── Remarks ──
                  CustomTextField(
                    label: "Remarks",
                    controller: _remarksController,
                    isRequired: false,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
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
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? "${date.day}-${date.month}-${date.year}"
                      : "Select Date",
                  style: TextStyle(
                    fontSize: 15,
                    color: date != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
