import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../core/utlis/widgets/fields/phone_number_field.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../model/manpower_model.dart';
import '../service/manPowerProvider.dart';

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
  // late TextEditingController _aadhaarController;
  late TextEditingController _panController;
  late TextEditingController _bankController;
  late TextEditingController _ifscController;
  late TextEditingController _epfController;
  late TextEditingController _uanController;
  late TextEditingController _esicController;
  late TextEditingController _salaryController;
  late TextEditingController _remarksController;

  DateTime? _dob;
  DateTime? _doj;
  String _payBasic = "monthly";

  @override
  void initState() {
    super.initState();
    final m = widget.manpower;

    _fullNameController = TextEditingController(text: m.fullName);
    _designationController = TextEditingController(text: m.designation);
    _phoneController = TextEditingController(text: m.phoneNumber ?? "");
    // _aadhaarController = TextEditingController(text: m.aadharNumber ?? "");
    _panController = TextEditingController(text: m.panNumber ?? "");
    _bankController = TextEditingController(text: m.bankAccountNumber ?? "");
    _ifscController = TextEditingController(text: m.ifscCode ?? "");
    _epfController = TextEditingController(text: m.epfNumber ?? "");
    _uanController = TextEditingController(text: m.uanNumber ?? "");
    _esicController = TextEditingController(text: m.esicNumber ?? "");
    _salaryController = TextEditingController(text: m.salary.toString());
    _remarksController = TextEditingController(text: m.remarks ?? "");
    _payBasic = m.payBasics ?? "monthly";

    if (m.dateOfBirth != null) _dob = DateTime.tryParse(m.dateOfBirth!);
    if (m.dateOfJoining != null) _doj = DateTime.tryParse(m.dateOfJoining!);
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
      // "aadharNumber": _aadhaarController.text,
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

    try {
      await ref.read(manpowerProvider.notifier).updateManpower(
          widget.manpower.id!, data, manpowerType);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Manpower updated successfully")),
      );
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
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "Edit Employee Details"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Using CustomTextField for all text fields
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
              // Using PhoneInputField for phone number
              PhoneInputField(
                controller: _phoneController,
              ),
              // CustomTextField(
              //   label: "Aadhar Number",
              //   controller: _aadhaarController,
              //   isRequired: false,
              //   keyboardType: TextInputType.number,
              // ),
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
                        decoration: InputDecoration(
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

              Row(
                children: [
                  RoundedButton(
                    text: "Back",
                    color: Colors.black,
                    textColor: Colors.black,
                    isOutlined: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  RoundedButton(
                    text: "Save & Submit",
                    color: Colors.green,
                    textColor: Colors.white,
                    onPressed: _updateManpower,
                  ),
                ],
              )

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