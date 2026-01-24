import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import '../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../core/utlis/widgets/file_upload.dart';
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
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  File? _digitalSignatureFile;



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
      'bankName': '',
      'accountNumber': '',
      'ifscCode': '',
      'branch': '',
      'panNumber': '',
      'digitalSignature': '',

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
  Future<void> _pickDigitalSignature() async {
    final helper = ImageUploadHelper(context);
    final file = await helper.pickAndCropImage(
      enableCropping: false,
      cropTitle: 'Upload Digital Signature',
    );

    if (file != null) {
      setState(() {
        _digitalSignatureFile = file;
        _formValues['digitalSignature'] = file.path;
      });
    }
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
    _bankNameController.text = user.company?.bankName ?? '';
    _accountNumberController.text = user.company?.accountNumber ?? '';
    _ifscCodeController.text = user.company?.ifscCode ?? '';
    _branchController.text = user.company?.branch ?? '';
    _panController.text = user.company?.panNumber ?? '';

    _formValues['digitalSignature'] = user.company?.digitalSignature ?? '';
    print(user.id);


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
    final helper = ImageUploadHelper(context);
    final file = await helper.pickAndCropImage(
      enableCropping: true,
      cropTitle: isProfile ? 'Crop Profile Photo' : 'Crop Company Logo',
    );

    if (file != null) {
      setState(() {
        if (isProfile) {
          _profileImageFile = file;
          _formValues['profilePhoto'] = file.path;
        } else {
          _companyLogoFile = file;
          _formValues['companyLogo'] = file.path;
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

    if ((_formValues['selectService'] as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one service')),
      );
      return;
    }

    try {
      final userNotifier = ref.read(userNotifierProvider.notifier);

      final formData = FormData();

      // Files
      if (_profileImageFile != null) {
        formData.files.add(
          MapEntry(
            'profilePhoto',
            await MultipartFile.fromFile(
              _profileImageFile!.path,
              filename: 'profile.jpg',
            ),
          ),
        );
      }

      if (_companyLogoFile != null) {
        formData.files.add(
          MapEntry(
            'companyLogo',
            await MultipartFile.fromFile(
              _companyLogoFile!.path,
              filename: 'company.jpg',
            ),
          ),
        );
      }
      if (_digitalSignatureFile != null) {
        formData.files.add(
          MapEntry(
            'digitalSignature',
            await MultipartFile.fromFile(
              _digitalSignatureFile!.path,
              filename: 'signature.png',
            ),
          ),
        );
      }




      // Name split
      final nameParts = _fullNameController.text.trim().split(' ');
      final firstName = nameParts.first;
      final lastName =
      nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Fields (MATCH RN EXACTLY)
      formData.fields.addAll([
        MapEntry('firstName', firstName),
        MapEntry('lastName', lastName),
        MapEntry('phoneNumber', _phoneNumberController.text.trim()),
        MapEntry('email', _emailController.text.trim()),
        MapEntry('aadhaarCard', _aadhaarController.text.trim()),
        MapEntry('gstNumber', _gstController.text.trim()),
        MapEntry('company', _companyNameController.text.trim()),
        MapEntry('address', _addressController.text.trim()),
        MapEntry('other', _otherController.text.trim()),
        MapEntry('bankName', _bankNameController.text.trim()),
        MapEntry('accountNumber', _accountNumberController.text.trim()),
        MapEntry('ifscCode', _ifscCodeController.text.trim()),
        MapEntry('branch', _branchController.text.trim()),
        MapEntry('panNumber', _panController.text.trim()),
      ]);

      // selectedServices (REPEAT KEY — VERY IMPORTANT)
      for (final service in _formValues['selectService']) {
        formData.fields.add(MapEntry('selectedServices', service));
      }

      await userNotifier.updateUser(formData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _branchController.dispose();
    _panController.dispose();

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
                    GestureDetector(
                      onTap: () => _handleImagePick(true),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _profileImageFile != null
                                ? FileImage(_profileImageFile!)
                                : (_formValues['profilePhoto'] != null &&
                                _formValues['profilePhoto'].isNotEmpty)
                                ? NetworkImage(_formValues['profilePhoto'])
                                : null,
                            child: _profileImageFile == null &&
                                (_formValues['profilePhoto'] == null ||
                                    _formValues['profilePhoto'].isEmpty)
                                ? const Icon(Icons.person, size: 60)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                    GestureDetector(
                      onTap: () => _handleImagePick(false),
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: _companyLogoFile != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_companyLogoFile!, fit: BoxFit.cover),
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.business, size: 40, color: Colors.grey),
                            SizedBox(height: 6),
                            Text(
                              "Upload Logo",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const SizedBox(height: 15),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Bank Details',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),

                    CustomTextField(
                      controller: _bankNameController,
                      label: 'Bank Name',
                      hint: 'Enter bank name',
                    ),

                    CustomTextField(
                      controller: _accountNumberController,
                      label: 'Account Number',
                      hint: 'Enter account number',
                      keyboardType: TextInputType.number,
                    ),

                    CustomTextField(
                      controller: _ifscCodeController,
                      label: 'IFSC Code',
                      hint: 'Enter IFSC code',
                    ),

                    CustomTextField(
                      controller: _branchController,
                      label: 'Branch',
                      hint: 'Enter branch name',
                    ),

                    CustomTextField(
                      controller: _panController,
                      label: 'PAN Number',
                      hint: 'Enter PAN number',
                    ),
                    const SizedBox(height: 15),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Digital Signature',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: _pickDigitalSignature,
                      child: Container(
                        height: 100,
                        width: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade100,
                        ),
                        child: _digitalSignatureFile != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _digitalSignatureFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                            : _formValues['digitalSignature'] != null &&
                            _formValues['digitalSignature'].isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _formValues['digitalSignature'],
                            fit: BoxFit.cover,
                          ),
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.draw, size: 30, color: Colors.grey),
                            SizedBox(height: 6),
                            Text('Upload Signature'),
                          ],
                        ),
                      ),
                    ),




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