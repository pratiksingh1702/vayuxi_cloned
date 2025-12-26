import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/screens/widgets/popup.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../core/utlis/widgets/fields/phone_number_field.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../model/manpower_model.dart';
import '../service/manPowerProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

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

  // New controllers for login credentials
  late TextEditingController _emailController;
  late TextEditingController _otpController;

  DateTime? _dob;
  DateTime? _doj;
  String _payBasic = "monthly";

  // New state variables
  bool _enableLoginCredentials = false;
  String _generatedOtp = "";

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
    _salaryController = TextEditingController(text: m.salary.toString());
    _remarksController = TextEditingController(text: m.remarks ?? "");
    _payBasic = m.payBasics ?? "monthly";

    // Initialize login credential controllers
    _emailController = TextEditingController(text: m.loginEmail ?? "");
    _otpController = TextEditingController(text: "Regenerate to use new password");

    _enableLoginCredentials = (m.isLoginEnabled ?? false) || (m.loginEmail?.isNotEmpty ?? false);

    // Generate OTP if login is enabled but no password exists
    if (_enableLoginCredentials && (m.loginPassword == null || m.loginPassword!.isEmpty)) {
      _generateOtp();
    }// Enable login credentials if email exists
    _enableLoginCredentials = (m.loginEmail?.isNotEmpty ?? false);

    // Generate OTP if login is enabled but no password exists
    if (_enableLoginCredentials && (m.loginPassword == null || m.loginPassword!.isEmpty)) {
      _generateOtp();
    }

    if (m.dateOfBirth != null) _dob = DateTime.tryParse(m.dateOfBirth!);
    if (m.dateOfJoining != null) _doj = DateTime.tryParse(m.dateOfJoining!);
  }

  // Generate random 6-digit OTP
  void _generateOtp() {
    final random = Random();
    _generatedOtp = (100000 + random.nextInt(900000)).toString();
    _otpController.text = _generatedOtp;
  }

  Future<void> _pickDate(BuildContext context, bool isDOB) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDOB ? (_dob ?? DateTime(1990)) : (_doj ?? DateTime.now()),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDOB) _dob = picked;
        else _doj = picked;
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

    final data = {
      "fullName": _fullNameController.text,
      "designation": _designationController.text,
      "phoneNumber": _phoneController.text,
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
      "remarks": _remarksController.text,
    };

    // Add login credentials if enabled
    if (_enableLoginCredentials && _emailController.text.isNotEmpty) {
      data["loginEmail"] = _emailController.text;
      // Only update password if OTP is newly generated or changed
      if (_otpController.text.isNotEmpty) {
        data["loginPassword"] = _otpController.text;
      }
      data["isLoginEnabled"] = true;
      if (_otpController.text.isNotEmpty) {
        data["loginPassword"] = _otpController.text;
      }
    }else {
      data["isLoginEnabled"] = false;  // Add this flag
      // Optionally clear login credentials when disabled
      data["loginEmail"] = null;
      data["loginPassword"] = null;
    }

    try {
      // Call updateManpower which now returns the updated object
      final updatedManpower = await ref.read(manpowerProvider.notifier).updateManpower(
          widget.manpower.id!, data, manpowerType
      );

      if (updatedManpower == null) {
        throw Exception("Failed to update manpower");
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Manpower updated successfully")),
      );

      // Show login credentials popup if enabled and password was updated
      if (_enableLoginCredentials &&
          _emailController.text.isNotEmpty &&
          _otpController.text.isNotEmpty) {
        // Use employee code from updated object or existing one
        final employeeCode = updatedManpower.employeeCode ?? widget.manpower.employeeCode ?? "N/A";

        await showDialog(
          context: context,
          builder: (context) => LoginCredentialsPopup(
            employeeCode: employeeCode,
            password: _otpController.text,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                color: Colors.green,
                textColor: Colors.white,
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
                  CustomTextField(
                    label: "Full Name",
                    controller: _fullNameController,
                    isRequired: true,
                  ),
                  CustomTextField(
                    label: "Designation",
                    controller: _designationController,
                    isRequired: true,
                  ),
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
                                    if (_emailController.text.isEmpty) {
                                      // Suggest email based on name
                                      final name = _fullNameController.text
                                          .toLowerCase()
                                          .replaceAll(' ', '');
                                      _emailController.text = "$name${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}@gmail.com";
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
                            "OTP will be used as password. Leave empty to keep current password.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  CustomTextField(
                    label: "PAN Number",
                    controller: _panController,
                    isRequired: false,
                  ),
                  CustomTextField(
                    label: "Bank Account Number",
                    controller: _bankController,
                    isRequired: false,
                    keyboardType: TextInputType.number,
                  ),
                  CustomTextField(
                    label: "IFSC Code",
                    controller: _ifscController,
                    isRequired: false,
                  ),
                  CustomTextField(
                    label: "EPF Number",
                    controller: _epfController,
                    isRequired: false,
                    keyboardType: TextInputType.number,
                  ),
                  CustomTextField(
                    label: "UAN Number",
                    controller: _uanController,
                    isRequired: false,
                    keyboardType: TextInputType.number,
                  ),
                  CustomTextField(
                    label: "ESIC Number",
                    controller: _esicController,
                    isRequired: false,
                    keyboardType: TextInputType.number,
                  ),

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

                  const SizedBox(height: 10),
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
                                value: "monthly",
                                child: Text("Monthly"),
                              ),
                              DropdownMenuItem(
                                value: "daily",
                                child: Text("Daily"),
                              ),
                              DropdownMenuItem(
                                value: "yearly",
                                child: Text("Yearly"),
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

                  const SizedBox(height: 10),
                  CustomTextField(
                    label: "Salary",
                    controller: _salaryController,
                    isRequired: true,
                    keyboardType: TextInputType.number,
                  ),
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