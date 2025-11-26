import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../core/widgets/user/toggle_input.dart';
import '../../auth/provider/auth_provider.dart';
import 'package:untitled2/features/profile_page/screens/widgets/loader.dart';
import 'package:untitled2/features/profile_page/screens/widgets/dropdown.dart';
import 'package:untitled2/features/profile_page/screens/widgets/button.dart';
import 'package:untitled2/features/profile_page/screens/widgets/uploadPhoto.dart';
 // your CustomTextField

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

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
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      final user = authState.user!;
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
  }

  void _loadCurrentLanguage() {
    _selectedLangLabel = 'English';
  }

  Future<void> _handleImagePick(bool isProfile) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isProfile) {
          _formValues['profilePhoto'] = pickedFile.path;
        } else {
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
      final authNotifier = ref.read(authProvider.notifier);
      final user = ref.read(authProvider).user!;

      final formData = <String, dynamic>{};

      if (_formValues['profilePhoto'].toString().startsWith('/')) {
        formData['profilePhoto'] = File(_formValues['profilePhoto']);
      }
      if (_formValues['companyLogo'].toString().startsWith('/')) {
        formData['companyLogo'] = File(_formValues['companyLogo']);
      }

      final nameParts = _formValues['fullName'].toString().trim().split(' ');
      final firstName = nameParts[0];
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      formData.addAll({
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': _formValues['phoneNumber'],
        'email': _formValues['email'],
        'aadhaarCard': _formValues['aadhaarCard'],
        'gstNumber': _formValues['gstNumber'],
        'company': _formValues['company'],
        'address': _formValues['address'],
        'other': _formValues['other'],
        'selectedServices': _formValues['selectService'],
      });

      await authNotifier.updateUser(user, formData);
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
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) return const Loader();

    return Scaffold(
      appBar: CustomAppBar(title: "Your Profile"),
      backgroundColor: AppColors.lightBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title

                  // Profile photo
                  UploadPhotoButton(
                    size: 200,
                    imagePath: _formValues['profilePhoto'],
                    onPressed: () => _handleImagePick(true),
                  ),
                  const SizedBox(height: 20),

                  // Fields
                  CustomTextField(
                    label: 'First Name',
                    hint: 'Input Text',
                    isRequired: true,
                  ),
                  CustomTextField(
                    label: 'GSTIN',
                    hint: 'Input Text',
                  ),
                  CustomTextField(
                    label: 'Address',
                    hint: 'Input Text',
                    maxLines: 2,
                  ),
                  CustomTextField(
                    label: 'Trade Name',
                    hint: 'Input Text',
                  ),
                  const SizedBox(height: 10),

                  // Services
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Service',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
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

                  // Buttons
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _submitForm,
                    child: const Text('Save & Submit',style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back',style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _handleLogout,
                    child: const Text('Log out',style: TextStyle(color: Colors.white)),
                  ),

                ],
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
