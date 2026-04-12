import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/fields/custom_textField.dart';
import 'package:untitled2/core/utlis/widgets/file_upload.dart';
import 'package:untitled2/core/utlis/widgets/premium_app_bar.dart';
import 'package:untitled2/core/utlis/widgets/shimmer.dart';
import 'package:untitled2/features/profile_page/screens/widgets/loader.dart';

import '../../auth/provider/auth_provider.dart';
import '../provider/userProvider.dart';
import '../userModel/userModel.dart';

const String kUserProfileHeroTag = 'user-profile-hero-card';

Widget _luxuryHeroShuttleBuilder(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final fromHero = fromHeroContext.widget as Hero;
  final toHero = toHeroContext.widget as Hero;
  final target = flightDirection == HeroFlightDirection.push
      ? toHero.child
      : fromHero.child;

  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeInOutCubicEmphasized,
    reverseCurve: Curves.easeInOutCubic,
  );

  return AnimatedBuilder(
    animation: curved,
    child: target,
    builder: (context, child) {
      final t = curved.value;
      return Opacity(
        opacity: 0.9 + (0.1 * t),
        child: Transform.scale(
          scale: 0.985 + (0.015 * t),
          child: child,
        ),
      );
    },
  );
}

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
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();

  File? _profileImageFile;
  File? _companyLogoFile;
  File? _digitalSignatureFile;

  late Map<String, dynamic> _formValues;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadUserData();
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
      'accountName': '',
      'accountNumber': '',
      'ifscCode': '',
      'branch': '',
      'panNumber': '',
      'digitalSignature': '',
    };
  }

  void _loadUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userNotifierProvider.notifier).getCurrentUser();
    });
  }

  Future<void> _pickDigitalSignature() async {
    final helper = ImageUploadHelper(context);
    final file = await helper.pickAndCropImage(
      enableCropping: true,
      cropTitle: 'Upload Digital Signature',
    );

    if (file == null) return;

    setState(() {
      _digitalSignatureFile = file;
      _formValues['digitalSignature'] = file.path;
    });
  }

  Future<void> _handleImagePick(bool isProfile) async {
    final helper = ImageUploadHelper(context);
    final file = await helper.pickAndCropImage(
      enableCropping: true,
      cropTitle: isProfile ? 'Crop Profile Photo' : 'Crop Company Logo',
    );

    if (file == null) return;

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

  void _populateFormFields(User user) {
    _fullNameController.text = user.fullName;
    _phoneNumberController.text = user.phoneNumber;
    _emailController.text = user.email;
    _aadhaarController.text = user.aadhaarCard ?? '';
    _gstController.text = user.gstNumber ?? '';
    _companyNameController.text = user.company?.name ?? '';
    _addressController.text = user.address ?? '';
    _otherController.text = user.other ?? '';
    _bankNameController.text = user.company?.bankName ?? '';
    _accountNameController.text = user.company?.accountName ?? '';
    _accountNumberController.text = user.company?.accountNumber ?? '';
    _ifscCodeController.text = user.company?.ifscCode ?? '';
    _branchController.text = user.company?.branch ?? '';
    _panController.text = user.company?.panNumber ?? '';

    setState(() {
      _formValues = {
        'profilePhoto': user.profilePhoto ?? '',
        'fullName': user.fullName,
        'phoneNumber': user.phoneNumber,
        'email': user.email,
        'aadhaarCard': user.aadhaarCard ?? '',
        'gstNumber': user.gstNumber ?? '',
        'company': {
          'name': user.company?.name ?? '',
          'logo': user.company?.logo ?? '',
        },
        'companyLogo': user.company?.logo ?? '',
        'address': user.address ?? '',
        'other': user.other ?? '',
        'bankName': user.company?.bankName ?? '',
        'accountName': user.company?.accountName ?? '',
        'accountNumber': user.company?.accountNumber ?? '',
        'ifscCode': user.company?.ifscCode ?? '',
        'branch': user.company?.branch ?? '',
        'panNumber': user.company?.panNumber ?? '',
        'digitalSignature': user.company?.digitalSignature ?? '',
        'selectService': List<String>.from(user.selectedServices),
      };
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userNotifier = ref.read(userNotifierProvider.notifier);
      final formData = FormData();

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

      final nameParts = _fullNameController.text.trim().split(' ');
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      formData.fields.addAll([
        MapEntry('firstName', firstName),
        MapEntry('lastName', lastName),
        MapEntry('phoneNumber', _phoneNumberController.text.trim()),
        MapEntry('email', _emailController.text.trim()),
        MapEntry('aadhaarCard', _aadhaarController.text.trim()),
        MapEntry('gstNumber', _gstController.text.trim()),
        MapEntry('company', _companyNameController.text.trim()),
        MapEntry('address', _addressController.text.trim()),
        MapEntry('accountName', _accountNameController.text.trim()),
        MapEntry('other', _otherController.text.trim()),
        MapEntry('bankName', _bankNameController.text.trim()),
        MapEntry('accountNumber', _accountNumberController.text.trim()),
        MapEntry('ifscCode', _ifscCodeController.text.trim()),
        MapEntry('branch', _branchController.text.trim()),
        MapEntry('panNumber', _panController.text.trim()),
      ]);

      await userNotifier.updateUser(formData);
      AppToast.success('Profile updated successfully');
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
      debugPrint(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
  }

  Future<void> _handleLogoutAll() async {
    await ref.read(authProvider.notifier).logoutAll();
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
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userState = ref.watch(userNotifierProvider);

    if (userState.user != null && _fullNameController.text.isEmpty) {
      _populateFormFields(userState.user!);
    }

    if (userState.isLoading) return const Loader();

    final avatarUrl = (_formValues['profilePhoto'] ?? '').toString();
    final hasNetworkAvatar = avatarUrl.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: PremiumAppBar(
        title: 'My Profile',
        showDrawerButton: false,
        subtitle: const Text('Update your professional details'),
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF3FF), Color(0xFFF8FBFF)],
        ),
        actions: [
          PremiumActionIcon(
            icon: Icons.check_rounded,
            tooltip: 'Save Profile',
            onPressed: userState.isLoading ? () {} : _submitForm,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surfaceContainerLowest,
              colorScheme.primaryContainer.withOpacity(0.25),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Hero(
                    tag: kUserProfileHeroTag,
                    transitionOnUserGestures: true,
                    createRectTween: (begin, end) =>
                        MaterialRectArcTween(begin: begin, end: end),
                    flightShuttleBuilder: _luxuryHeroShuttleBuilder,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0F2C59), Color(0xFF1B4A92)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33223E70),
                              blurRadius: 22,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _handleImagePick(true),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 38,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundColor: const Color(0xFFDDE9FF),
                                      backgroundImage: _profileImageFile != null
                                          ? FileImage(_profileImageFile!)
                                          : (hasNetworkAvatar
                                              ? NetworkImage(avatarUrl)
                                              : null) as ImageProvider?,
                                      child: _profileImageFile == null &&
                                              !hasNetworkAvatar
                                          ? const Icon(Icons.person,
                                              size: 34,
                                              color: Color(0xFF1E3F72))
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2B68C9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fullNameController.text.trim().isEmpty
                                        ? 'User Profile'
                                        : _fullNameController.text.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _emailController.text.trim().isEmpty
                                        ? 'Update your details below'
                                        : _emailController.text.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.86),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ProfileSectionCard(
                    title: 'Personal Details',
                    icon: Icons.badge_rounded,
                    children: [
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
                      ),
                      CustomTextField(
                        controller: _phoneNumberController,
                        label: 'Phone Number',
                        hint: 'Enter your phone number',
                        isRequired: true,
                      ),
                      CustomTextField(
                        controller: _aadhaarController,
                        label: 'Aadhaar Card',
                        hint: 'Enter Aadhaar number',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProfileSectionCard(
                    title: 'Company Details',
                    icon: Icons.apartment_rounded,
                    children: [
                      CustomTextField(
                        controller: _companyNameController,
                        label: 'Company Name',
                        hint: 'Enter company name',
                      ),
                      CustomTextField(
                        controller: _gstController,
                        label: 'GST Number',
                        hint: 'Enter GST number',
                      ),
                      CustomTextField(
                        controller: _addressController,
                        label: 'Address',
                        hint: 'Enter your address',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 6),
                      _UploadTile(
                        title: 'Company Logo',
                        subtitle: 'Upload your brand identity',
                        icon: Icons.business_rounded,
                        preview: _companyLogoFile != null
                            ? Image.file(_companyLogoFile!, fit: BoxFit.cover)
                            : ((_formValues['companyLogo'] ?? '')
                                    .toString()
                                    .trim()
                                    .isNotEmpty
                                ? Image.network(
                                    _formValues['companyLogo'],
                                    fit: BoxFit.cover,
                                  )
                                : null),
                        onTap: () => _handleImagePick(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProfileSectionCard(
                    title: 'Bank & Signature',
                    icon: Icons.account_balance_rounded,
                    children: [
                      CustomTextField(
                        controller: _bankNameController,
                        label: 'Bank Name',
                        hint: 'Enter bank name',
                      ),
                      CustomTextField(
                        controller: _accountNameController,
                        label: 'Account Name',
                        hint: 'Enter account holder name',
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
                      const SizedBox(height: 6),
                      _UploadTile(
                        title: 'Digital Signature',
                        subtitle: 'Upload stamp or signature image',
                        icon: Icons.draw_rounded,
                        preview: _digitalSignatureFile != null
                            ? Image.file(_digitalSignatureFile!,
                                fit: BoxFit.cover)
                            : ((_formValues['digitalSignature'] ?? '')
                                    .toString()
                                    .trim()
                                    .isNotEmpty
                                ? Image.network(
                                    _formValues['digitalSignature'],
                                    fit: BoxFit.cover,
                                  )
                                : null),
                        onTap: _pickDigitalSignature,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (userState.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
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
                            onPressed: () => ref
                                .read(userNotifierProvider.notifier)
                                .clearError(),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: const Color(0xFF0F6A5E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: userState.isLoading ? null : _submitForm,
                          icon: userState.isLoading
                              ? const ShimmerCircle(size: 18)
                              : Icon(Icons.save_rounded,
                                  color: colorScheme.onPrimary, size: 18),
                          label: Text(
                            'Save Changes',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: BorderSide(color: colorScheme.outlineVariant),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: colorScheme.onSurface,
                            size: 18,
                          ),
                          label: Text(
                            'Back',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: colorScheme.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _handleLogout,
                    icon: Icon(
                      Icons.logout_rounded,
                      color: colorScheme.onError,
                      size: 18,
                    ),
                    label: Text(
                      'Log Out',
                      style: TextStyle(color: colorScheme.onError),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _handleLogoutAll,
                    child: Text(
                      'Log out from all devices',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.preview,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: preview == null
                  ? Icon(icon, color: colorScheme.onSurfaceVariant, size: 24)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: preview,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.upload_rounded, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
