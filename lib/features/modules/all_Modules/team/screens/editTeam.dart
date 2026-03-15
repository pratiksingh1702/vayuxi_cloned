import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';

import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../Manpower Details/model/manpower_model.dart';
import '../../Manpower Details/service/manPowerProvider.dart';
import '../../site_Details/repository/siteModel.dart';
import '../model/teamModel.dart';
import '../provider/teamProvider.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';

class EditTeamScreen extends ConsumerStatefulWidget {
  final SiteModel site;
  final TeamModel team;

  const EditTeamScreen({super.key, required this.site, required this.team});

  @override
  ConsumerState<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends ConsumerState<EditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();

  ManpowerModel? _selectedLead;
  List<ManpowerModel> _selectedMembers = [];
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isDataInitialized = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeForm();
    final type = ref.read(typeProvider);
    Future.microtask(() {
      ref.read(manpowerProvider.notifier).fetchManpower(type!);
    });
  }

  void _initializeForm() {
    // Pre-fill team name
    _teamNameController.text = widget.team.teamName;

    // Store current image URL
    _currentImageUrl = widget.team.teamLeadImage;

    debugPrint('📋 Initializing Edit Team Form:');
    debugPrint('   Team Name: ${widget.team.teamName}');
    debugPrint('   Team Lead ID: ${widget.team.teamLeadId}');
    debugPrint('   Team Member IDs: ${widget.team.teamMemberIds}');
    debugPrint('   Team Image: ${widget.team.teamLeadImage}');
  }

  void _preFillTeamData(List<ManpowerModel> manpowerList) {
    if (_isDataInitialized) return;

    debugPrint('🔄 Pre-filling team data...');
    debugPrint('   Available manpower count: ${manpowerList.length}');

    // Pre-fill team lead
    if (widget.team.teamLeadId != null && widget.team.teamLeadId!.isNotEmpty) {
      try {
        _selectedLead = manpowerList.firstWhere(
              (m) => m.id == widget.team.teamLeadId,
        );
        debugPrint('✅ Team lead found: ${_selectedLead?.fullName} (${_selectedLead?.id})');
      } catch (e) {
        _selectedLead = null;
        debugPrint('❌ Team lead not found with ID: ${widget.team.teamLeadId}');
        debugPrint('   Available IDs: ${manpowerList.map((m) => m.id).join(", ")}');
      }
    }

    // Pre-fill team members
    if (widget.team.teamMemberIds.isNotEmpty) {
      _selectedMembers = manpowerList.where((member) {
        bool isSelected = widget.team.teamMemberIds.contains(member.id);
        if (isSelected) {
          debugPrint('✅ Team member found: ${member.fullName} (${member.id})');
        }
        return isSelected;
      }).toList();

      debugPrint('   Total members selected: ${_selectedMembers.length}');

      // Check for missing members
      final foundIds = _selectedMembers.map((m) => m.id).toSet();
      final missingIds = widget.team.teamMemberIds.where((id) => !foundIds.contains(id));
      if (missingIds.isNotEmpty) {
        debugPrint('⚠️ Some team members not found in manpower list: $missingIds');
      }
    }

    _isDataInitialized = true;
    setState(() {});
  }

  Future<void> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Team Profile',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
            cropGridRowCount: 3,
            cropGridColumnCount: 3,
            cropGridColor: Colors.white.withOpacity(0.5),
            cropFrameColor: Colors.blueAccent,
            cropGridStrokeWidth: 1,
            cropFrameStrokeWidth: 2,
            activeControlsWidgetColor: Colors.blueAccent,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Team Profile',
            minimumAspectRatio: 0.1,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
            resetAspectRatioEnabled: true,
            aspectRatioLockEnabled: false,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(
              width: 520,
              height: 520,
            ),
            viewwMode: WebViewMode.mode_1,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImage = File(croppedFile.path);
          _currentImageUrl = null; // Clear the URL when new image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cropping image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        await _cropImage(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final formData = FormData.fromMap({
        "teamName": _teamNameController.text,
        "teamLead": _selectedLead?.id ?? "",
        "teamMembers": _selectedMembers.map((m) => m.id).toList(),
        if (_selectedImage != null)
          "file": await MultipartFile.fromFile(
            _selectedImage!.path,
            filename: "team_profile.jpg",
          )
        else if (_selectedImage==null && _currentImageUrl==null)
          "file": "",

      });
      print("===== FORM DATA =====");

      for (var field in formData.fields) {
        print("${field.key}: ${field.value}");
      }

      for (var file in formData.files) {
        print("${file.key}: ${file.value.filename}");
      }

      print("=====================");
      final type = ref.read(typeProvider);

      await ref.read(teamProvider.notifier).updateTeam(
        siteId: widget.site.id,
        teamId: widget.team.id,
        data: formData,
        type: type!,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = ref.watch(typeProvider);
    final manpowerState = ref.watch(manpowerProvider);

    // Pre-fill data when manpower is loaded
    if (manpowerState.manpowerList.isNotEmpty && !_isDataInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preFillTeamData(manpowerState.manpowerList);
      });
    }

    if (manpowerState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (manpowerState.error != null) {
      return Scaffold(
        body: Center(child: Text("Error: ${manpowerState.error}")),
      );
    }

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: 'Edit Team'),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // --- Team Name Field ---
                    CustomTextField(
                      label: "Team Name",
                      isRequired: true,
                      controller: _teamNameController,
                      hint: "Enter team name",
                    ),
                    const SizedBox(height: 20),

                    // --- Upload Profile Section ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Team Profile",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            height: 130,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: _selectedImage != null
                                ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImage = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                                : _currentImageUrl != null &&
                                _currentImageUrl!.isNotEmpty
                                ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  child: Image.network(
                                    _currentImageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error,
                                        stackTrace) {
                                      return _buildPlaceholderImage();
                                    },
                                    loadingBuilder: (context, child,
                                        loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return const Center(
                                        child:
                                        CircularProgressIndicator(),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _currentImageUrl = null;
                                      });
                                    },
                                    child: Container(
                                      padding:
                                      const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                                : _buildPlaceholderImage(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // --- Team Lead Card ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Team Lead",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownSearch<ManpowerModel>(
                          selectedItem: _selectedLead,
                          itemAsString: (m) => m.fullName ?? 'Unknown',
                          items: (String filter, LoadProps? props) {
                            return manpowerState.manpowerList
                                .where((m) =>
                            m.fullName != null &&
                                m.fullName!
                                    .toLowerCase()
                                    .contains(filter.toLowerCase()))
                                .toList();
                          },
                          compareFn: (a, b) => a.id == b.id,
                          onChanged: (selected) {
                            setState(() {
                              _selectedLead = selected;
                            });
                          },
                          popupProps: const PopupProps.modalBottomSheet(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'Search Team Lead',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          decoratorProps: const DropDownDecoratorProps(
                            decoration: InputDecoration(
                              hintText: "Select Team Lead",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // --- Team Members Card ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Team Members",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownSearch<ManpowerModel>.multiSelection(
                          items: (String filter, LoadProps? props) {
                            return manpowerState.manpowerList
                                .where((m) =>
                            m.fullName
                                ?.toLowerCase()
                                .contains(filter.toLowerCase()) ??
                                false)
                                .toList();
                          },
                          selectedItems: _selectedMembers,
                          itemAsString: (m) => m.fullName ?? 'Unknown',
                          compareFn: (a, b) => a.id == b.id,
                          popupProps:
                          PopupPropsMultiSelection.modalBottomSheet(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'Search Members',
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            title: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Select Team Members",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          onChanged: (values) {
                            setState(() {
                              _selectedMembers = values;
                            });
                          },
                          decoratorProps: const DropDownDecoratorProps(
                            decoration: InputDecoration(
                              hintText: "Select Team Members",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          validator: (values) {
                            if (values == null || values.isEmpty) {
                              return "Select at least one member";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // --- Action Buttons ---
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RoundedButton(
                        text: "Back",
                        color: Colors.white,
                        textColor: Colors.black,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RoundedButton(
                        text: "Update Team",
                        color: Colors.blueAccent,
                        textColor: Colors.white,
                        onPressed: _submitForm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.person_add_alt_1, size: 40, color: Colors.grey),
        SizedBox(height: 6),
        Text(
          "Upload Photo",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}