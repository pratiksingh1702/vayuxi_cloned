import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/screens/widgets/popup.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../core/utlis/widgets/fields/phone_number_field.dart';
import '../../../../../core/utlis/widgets/fields/searchableDropdown.dart';
import '../../../../../typeProvider/type_provider.dart';

import '../service/manPowerProvider.dart';



import 'dart:math'; // Add this import for generating random OTP

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

  bool _isPfApplicable = true;


  // New controllers for login credentials
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  // Designation options
  final List<String> _designationOptions = [
    "Manager",
    "Team Leader",
    "Team Member",
    "Director",
    "Supervisor",
    "Engineer",
    "Executive Engineer",
    "Welder",
    "Fitter",
    "Rigger",
    "Helper",
    "Legger",
    "Fabricator",
    "Foreman",
    "Site Supervisor",
    "CTO",
    "CEO",
    "Senior Manager",
    "Assistant General Manager",
    "General Manager",
    "Grinderman",
    "Cutter",
  ];

  DateTime? _dob;
  DateTime? _doj;
  String _payBasic = "monthly";
  String? _selectedDesignation;

  // New state variables for login credentials toggle
  bool _enableLoginCredentials = false;
  String _generatedOtp = "";

  // Generate random 6-digit OTP
  void _generateOtp() {
    final random = Random();
    _generatedOtp = (100000 + random.nextInt(900000)).toString();
    _otpController.text = _generatedOtp;
  }

  Future<void> _pickDate(BuildContext context, bool isDOB) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isDOB) {
          _dob = picked;
        } else {
          _doj = picked;
        }
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
  }

  Future<void> _saveManpower() async {
    // if (!_formKey.currentState!.validate()) return;

    final manpowerType = ref.read(typeProvider);
    if (manpowerType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No manpower type selected")),
      );
      return;
    }

    final data = {
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
      "Salary": double.tryParse(_salaryController.text) ?? 0,
      "basicSalary":double.tryParse(_basicSalaryController.text) ?? 0,
      "hra":_hra.text,

      // ✅ NEW FIELDS
      "dearnessAllowance": double.tryParse(_daController.text) ?? 0,
      "specialAllowance": double.tryParse(_specialAllowanceController.text) ?? 0,
      "travelAllowance": double.tryParse(_travelAllowanceController.text) ?? 0,
      "medicalAllowance": double.tryParse(_medicalAllowanceController.text) ?? 0,
      "pfApplicable": _isPfApplicable,

      "remarks": _remarksController.text,
    };


    // Add login credentials if enabled
    if (_enableLoginCredentials && _emailController.text.isNotEmpty) {
      data["loginEmail"] = _emailController.text;
      data["loginPassword"] = _otpController.text;
      data["isLoginEnabled"] = true;
    }else{
      data["isLoginEnabled"] = false;
    }

    try {
     final createdManpower= await ref.read(manpowerProvider.notifier).addManpower(manpowerType, data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Manpower added successfully")),
      );
      if (_enableLoginCredentials && _emailController.text.isNotEmpty) {
        final employeeCode = createdManpower?.employeeCode ?? "N/A";

        await showDialog(
          context: context,
          builder: (context) => LoginCredentialsPopup(
            employeeCode: employeeCode,  // Pass employee code instead of email
            password: _otpController.text,
          ),
        );
      }

      Navigator.pop(context);
      context.push("/manpower");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "New Employee Details"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name
              CustomTextField(
                label: "Full Name",
                controller: _fullNameController,
                isRequired: true,
              ),

              // Designation with SearchableDropdown
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Designation",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SearchableDropdown(
                    data: _designationOptions,
                    onSelect: (value) {
                      setState(() {
                        _selectedDesignation = value;
                      });
                    },
                    placeholder: "Search Designation",
                    value: _selectedDesignation,
                    containerDecoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF197278),
                        width: 1,
                      ),
                    ),
                    inputDecoration: const InputDecoration(
                      hintText: "Search Designation",
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                  ),
                ],
              ),

              // Phone Number
              const SizedBox(height: 16),
              PhoneInputField(
                controller: _phoneController,
              ),

              // Login Credentials Toggle
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Enable Login Credentials",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
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
                          activeColor: Colors.blue,
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
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Regenerate",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "OTP will be used as initial password",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Rest of your form fields...
              // Aadhar Number
              const SizedBox(height: 16),
              CustomTextField(
                label: "Aadhar Number",
                controller: _aadhaarController,
                isRequired: false,
                keyboardType: TextInputType.number,
              ),

              // PAN Number
              const SizedBox(height: 16),
              CustomTextField(
                label: "PAN Number",
                controller: _panController,
                isRequired: false,
              ),

              // Bank Account Number
              const SizedBox(height: 16),
              CustomTextField(
                label: "Bank Account Number",
                controller: _bankController,
                isRequired: false,
                keyboardType: TextInputType.number,
              ),

              // IFSC Code
              const SizedBox(height: 16),
              CustomTextField(
                label: "IFSC Code",
                controller: _ifscController,
                isRequired: false,
              ),

              // EPF Number
              const SizedBox(height: 16),
              CustomTextField(
                label: "EPF Number",
                controller: _epfController,
                isRequired: false,
                keyboardType: TextInputType.number,
              ),

              // UAN Number
              const SizedBox(height: 16),
              CustomTextField(
                label: "UAN Number",
                controller: _uanController,
                isRequired: false,
                keyboardType: TextInputType.number,
              ),

              // ESIC Number
              const SizedBox(height: 16),
              CustomTextField(
                label: "ESIC Number",
                controller: _esicController,
                isRequired: false,
                keyboardType: TextInputType.number,
              ),

              // Date of Birth and Date of Joining
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker("Date of Birth", _dob, true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDatePicker("Date of Joining", _doj, false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "PF Applicable",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: _isPfApplicable,
                      activeColor: Colors.blue,
                      onChanged: (val) {
                        setState(() {
                          _isPfApplicable = val;
                        });
                      },
                    ),
                  ],
                ),
              ),


              // Pay Basics Dropdown
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pay Basics",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
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
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: InputBorder.none,
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.black54),
                        items: const [
                          DropdownMenuItem(
                            value: "daily",
                            child: Text("Daily"),
                          ),
                          DropdownMenuItem(
                            value: "monthly",
                            child: Text("Monthly"),
                          ),
                          DropdownMenuItem(
                            value: "yearly",
                            child: Text("Yearly"),
                          ),
                          DropdownMenuItem(
                            value: "fixed",
                            child: Text("Fixed"),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _payBasic = val!;
                          });
                        },
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Salary
              const SizedBox(height: 16),
              CustomTextField(
                label: "Salary",
                controller: _salaryController,
                isRequired: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: "Basic Salary",
                controller: _basicSalaryController,
                isRequired: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 12),
              CustomTextField(
                label: "Dearness Allowance (DA)",
                controller: _daController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 12),
              CustomTextField(
                label: "Home Rent Allowance (HRA)",
                controller: _hra,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 12),
              CustomTextField(
                label: "Special Allowance",
                controller: _specialAllowanceController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 12),
              CustomTextField(
                label: "Travel Allowance",
                controller: _travelAllowanceController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 12),
              CustomTextField(
                label: "Medical Allowance",
                controller: _medicalAllowanceController,
                keyboardType: TextInputType.number,
              ),


              // Remarks
              const SizedBox(height: 16),
              CustomTextField(
                label: "Remarks",
                controller: _remarksController,
                isRequired: false,
                maxLines: 3,
              ),

              // Buttons
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveManpower,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("Save & Submit"),
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
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("Reset"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pickDate(context, isDOB),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.08),
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
                      : "Input Text",
                  style: TextStyle(
                    fontSize: 15,
                    color: date != null ? Colors.black87 : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF007BFF),
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