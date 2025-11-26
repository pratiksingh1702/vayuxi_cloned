import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';

import '../../../../../core/utlis/widgets/custom_appBar.dart';
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

    // // Store current image URL
    // _currentImageUrl = widget.team.teamImage;

    // Note: Team lead and members will be set after manpower data is loaded
  }

  void _preFillTeamData(List<ManpowerModel> manpowerList) {
    // Pre-fill team lead
    if (widget.team.teamLeadId != null) {
      try {
        _selectedLead = manpowerList.firstWhere(
              (m) => m.id == widget.team.teamLeadId,
        );
      } catch (e) {
        // If team lead not found, set to null
        _selectedLead = null;
      }
    }

    // Pre-fill team members
    if (widget.team.teamMemberIds.isNotEmpty) {
      _selectedMembers = manpowerList.where((member) {
        // Handle both object and string ID formats
        return (widget.team.teamMemberIds).contains(member.id);
            }).toList();
    }

    setState(() {});
  }
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _currentImageUrl = null; // Clear the URL when new image is selected
      });
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
            filename: "profile.jpg",
          ),
      });
      final type=ref.read(typeProvider);

      await ref.read(teamProvider.notifier).updateTeam(
        siteId: widget.site.id,
        teamId: widget.team.id,
        formData: formData, type: type!,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = ref.watch(typeProvider);
    final manpowerState = ref.watch(manpowerProvider);

    // Pre-fill data when manpower is loaded
    if (manpowerState.manpowerList.isNotEmpty &&
        (_selectedLead == null || _selectedMembers.isEmpty)) {
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
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: 'Edit Team'),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: Form(
          key: _formKey,
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
                    onTap: _pickImage,
                    child: Container(
                      height: 130,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                          : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _currentImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        ),
                      )
                          : _buildPlaceholderImage(),
                    ),
                  ),
                  if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Current image",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
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
                          .where((m) => m.fullName != null &&
                          m.fullName!.toLowerCase().contains(filter.toLowerCase()))
                          .toList();
                    },
                    compareFn: (a, b) => a.id == b.id,
                    onChanged: (selected) {
                      setState(() {
                        _selectedLead = selected;
                      });
                    },
                    popupProps: const PopupProps.modalBottomSheet(),
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
                          borderRadius: BorderRadius.all(Radius.circular(8)),
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
                          .where((m) => m.fullName != null &&
                          m.fullName!.toLowerCase().contains(filter.toLowerCase()))
                          .toList();
                    },
                    selectedItems: _selectedMembers,
                    itemAsString: (m) => m.fullName ?? 'Unknown',
                    compareFn: (a, b) => a.id == b.id,
                    popupProps: PopupPropsMultiSelection.modalBottomSheet(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search Members',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
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

              // --- Action Buttons ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.black54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Update Team",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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