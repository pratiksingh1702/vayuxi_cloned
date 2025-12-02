import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import '../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../core/widgets/user/toggle_input.dart';
import '../../auth/provider/auth_provider.dart';
import 'package:untitled2/features/profile_page/screens/widgets/loader.dart';
import 'package:untitled2/features/profile_page/screens/widgets/dropdown.dart';
import 'package:untitled2/features/profile_page/screens/widgets/button.dart';
import 'package:untitled2/features/profile_page/screens/widgets/uploadPhoto.dart';

import '../provider/userProvider.dart';
import '../userModel/userModel.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _otherController = TextEditingController();

  final List<String> _serviceKeys = [
    'mechanical_work',
    'painting',
    'construction_work',
    'insulation_work',
    'plumbing',
    'rooting_work',
    'others',
  ];

  final Map<String, String> _langMap = {
    'English': 'en',
    'Hindi': 'hi',
    'Gujarati': 'gu',
    'HindiEnglish': 'hingu',
  };

  late Map<String, dynamic> _formValues;
  String? _selectedLangLabel;
  File? _profileImageFile;
  File? _companyLogoFile;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadUserData();
    _loadCurrentLanguage();
  }

  void _initializeForm() {
    _formValues = {
      'profilePhoto': '',
      'fullName': '',
      'phoneNumber': '',
      'email': '',
      'aadhaarCard': '',
      'gstNumber': '',
      'company': {'name': '', 'logo': ''},
      'address': '',
      'other': '',
      'companyLogo': '',
      'selectService': <String>[],
    };
  }

  void _loadUserData() {
    // Load user data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userNotifierProvider.notifier).getCurrentUser();
    });
  }

  void _loadCurrentLanguage() {
    _selectedLangLabel = 'English';
  }

  void _populateFormFields(User user) {
    // Set text controllers
    _fullNameController.text = user.fullName;
    _phoneNumberController.text = user.phoneNumber;
    _emailController.text = user.email;
    _aadhaarController.text = user.aadhaarCard ?? '';
    _gstController.text = user.gstNumber ?? '';
    _companyNameController.text = user.company?.name ?? '';
    _addressController.text = user.address ?? '';
    _otherController.text = user.other ?? '';

    // Set form values
    setState(() {
      _formValues = {
        'profilePhoto': user.profilePhoto ?? '',
        'companyLogo': user.company?.logo ?? '',
        'fullName': user.fullName,
        'phoneNumber': user.phoneNumber,
        'email': user.email,
        'aadhaarCard': user.aadhaarCard ?? '',
        'gstNumber': user.gstNumber ?? '',
        'company': {
          'name': user.company?.name ?? '',
          'logo': user.company?.logo ?? '',
        },
        'address': user.address ?? '',
        'other': user.other ?? '',
        'selectService': List<String>.from(user.selectedServices),
      };
    });
  }

  Future<void> _handleImagePick(bool isProfile) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _profileImageFile = File(pickedFile.path);
          _formValues['profilePhoto'] = pickedFile.path;
        } else {
          _companyLogoFile = File(pickedFile.path);
          _formValues['companyLogo'] = pickedFile.path;
        }
      });
    }
  }

  void _onServiceToggle(String service) {
    setState(() {
      final currentServices = List<String>.from(_formValues['selectService']);
      if (currentServices.contains(service)) {
        currentServices.remove(service);
      } else {
        currentServices.add(service);
      }
      _formValues['selectService'] = currentServices;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_formValues['selectService'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one service')),
      );
      return;
    }

    try {
      final userNotifier = ref.read(userNotifierProvider.notifier);

      // Prepare update data
      final updateData = <String, dynamic>{};

      // Handle file uploads
      if (_profileImageFile != null) {
        updateData['profilePhoto'] = _profileImageFile;
      }
      if (_companyLogoFile != null) {
        updateData['companyLogo'] = _companyLogoFile;
      }

      // Split full name into first and last name
      final nameParts = _fullNameController.text.trim().split(' ');
      final firstName = nameParts[0];
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Add other fields
      updateData.addAll({
        'firstName': firstName,
        'lastName': lastName,
        'fullName': _fullNameController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
        'email': _emailController.text.trim(),
        'aadhaarCard': _aadhaarController.text.trim(),
        'gstNumber': _gstController.text.trim(),
        'company': {
          'name': _companyNameController.text.trim(),
          'logo': _formValues['companyLogo'],
        },
        'address': _addressController.text.trim(),
        'other': _otherController.text.trim(),
        'selectedServices': _formValues['selectService'],
      });

      await userNotifier.updateUser(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  void _handleLogout() async {
    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.logout();
  }

  void _handleLogoutAll() async {
    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.logoutAll();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _aadhaarController.dispose();
    _gstController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userNotifierProvider);
    final authState = ref.watch(authProvider);

    // Populate form when user data is loaded
    if (userState.user != null && _fullNameController.text.isEmpty) {
      _populateFormFields(userState.user!);
    }

    if (userState.isLoading) return const Loader();

    return Scaffold(
      body: CornerClippedScreenSimple(
        color: Colors.transparent,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile photo
                    UploadPhotoButton(
                      size: 200,
                      imagePath: _formValues['profilePhoto'],
                      onPressed: () => _handleImagePick(true),
                    ),
                    const SizedBox(height: 20),

                    // Fields with controllers
                    CustomTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      isRequired: true,
                    ),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      isRequired: true,
                      // Email might not be editable
                    ),
                    CustomTextField(
                      controller: _phoneNumberController,
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      isRequired: true,
                    ),
                    CustomTextField(
                      controller: _gstController,
                      label: 'GSTIN',
                      hint: 'Enter GST number',
                    ),
                    CustomTextField(
                      controller: _companyNameController,
                      label: 'Company Name',
                      hint: 'Enter company name',
                    ),
                    CustomTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter your address',
                      maxLines: 2,
                    ),
                    CustomTextField(
                      controller: _aadhaarController,
                      label: 'Aadhaar Card',
                      hint: 'Enter Aadhaar number',
                    ),
                    const SizedBox(height: 10),

                    // Company Logo Upload
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Company Logo',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    UploadPhotoButton(
                      size: 100,
                      imagePath: _formValues['companyLogo'],
                      onPressed: () => _handleImagePick(false),
                      isCompanyLogo: true,
                    ),
                    const SizedBox(height: 15),

                    // Services
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select Service',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFFF8FAFD),
                      ),
                      child: Column(
                        children: _serviceKeys.map((service) {
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: _formValues['selectService'].contains(service),
                            title: Text(_getServiceLabel(service)),
                            onChanged: (_) => _onServiceToggle(service),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 15),

                    CustomTextField(
                      controller: _otherController,
                      label: 'Please Mention (if selected others)',
                      hint: 'Input Text',
                    ),

                    // Language dropdown
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 8.0, top: 8),
                        child: Text(
                          'Select Your Language',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Dropdown(
                      options: _langMap.keys.toList(),
                      value: _selectedLangLabel,
                      onSelect: (option) {
                        setState(() => _selectedLangLabel = option);
                      },
                    ),
                    const SizedBox(height: 25),

                    // Error message if any
                    if (userState.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                userState.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => ref.read(userNotifierProvider.notifier).clearError(),
                            ),
                          ],
                        ),
                      ),

                    // Buttons
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: userState.isLoading ? null : _submitForm,
                      child: userState.isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                          : const Text(
                        'Save & Submit',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Back',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _handleLogout,
                      child: const Text(
                        'Log out',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getServiceLabel(String key) {
    final labels = {
      'mechanical_work': 'Mechanical',
      'painting': 'Painting',
      'construction_work': 'Construction',
      'insulation_work': 'Insulation Work',
      'plumbing': 'Plumbing',
      'rooting_work': 'Roofing Work',
      'others': 'Others',
    };
    return labels[key] ?? key;
  }
}