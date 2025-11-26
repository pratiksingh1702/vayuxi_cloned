import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../core/utlis/widgets/fields/phone_number_field.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../service/manPowerService.dart';
import '../service/manPowerProvider.dart';


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
  final _remarksController = TextEditingController();

  DateTime? _dob;
  DateTime? _doj;
  String _payBasic = "monthly";

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
    _remarksController.clear();
    _dob = null;
    _doj = null;
    _payBasic = "monthly";
  }

  Future<void> _saveManpower() async {
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
      "remarks": _remarksController.text,
    };

    try {
      await ref.read(manpowerProvider.notifier).addManpower(manpowerType, data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Manpower added successfully")),
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
      appBar: CustomAppBar(title: "New Employee Details"),
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
              CustomTextField(
                label: "Aadhar Number",
                controller: _aadhaarController,
                isRequired: false,
                keyboardType: TextInputType.number,
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