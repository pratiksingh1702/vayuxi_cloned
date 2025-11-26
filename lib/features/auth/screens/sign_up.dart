import 'package:flutter/material.dart';
import '../../../core/utlis/widgets/buttons.dart';
import '../../../core/utlis/widgets/custom_appBar.dart';
import '../../../core/utlis/widgets/fields/phone_number_field.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final gstinController = TextEditingController();
  final aadhaarController = TextEditingController();
  final companyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Register at VAYUXI"),
      backgroundColor: const Color(0xFFE9F3FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // --- Toggle Buttons for Login/Register ---
                Row(
                  children: [
                    RoundedButton(
                      text: "Login",
                      color: Colors.blue,
                      textColor: Colors.blue,
                      isOutlined: true,
                      onPressed: () {
                        // Navigate to Login Screen
                      },
                    ),
                    const SizedBox(width: 10),
                    RoundedButton(
                      text: "Register",
                      color: Colors.blue,
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // --- First & Last Name ---
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                          "First Name*", firstNameController),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField("Last Name*", lastNameController),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // --- Phone Number ---
                PhoneInputField(
                  controller: phoneController,
                  countryCode: "+91",
                ),
                const SizedBox(height: 20),

                // --- Email ---
                _buildTextField("E-Mail ID*", emailController),

                const SizedBox(height: 15),

                // --- Verify Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Verify",
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- GSTIN ---
                _buildTextField("GSTIN", gstinController),

                const SizedBox(height: 20),

                // --- Aadhaar ---
                _buildTextField("Aadhar Number", aadhaarController),

                const SizedBox(height: 20),

                // --- Company Name ---
                _buildTextField("Company Name", companyController),

                const SizedBox(height: 25),

                // --- Register Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {}
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- Footer ---
                const Text(
                  "By continuing, you're agreeing to our Terms of Service and Privacy Policy.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                const Text(
                  "© 2025 VAYUXI. All rights reserved.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isDense = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            hintText: "Input Text",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }
}
