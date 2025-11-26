import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';

import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../Manpower Details/model/manpower_model.dart';
import '../../Manpower Details/service/manPowerProvider.dart';
import '../../site_Details/repository/siteModel.dart';
import '../model/teamModel.dart';
import '../provider/teamProvider.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';

class AddTeamScreen extends ConsumerStatefulWidget {
  final SiteModel site;

  const AddTeamScreen({super.key, required this.site});

  @override
  ConsumerState<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends ConsumerState<AddTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();

  ManpowerModel? _selectedLead;
  List<ManpowerModel> _selectedMembers = [];
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final type = ref.read(typeProvider);
    Future.microtask(() {
      ref.read(manpowerProvider.notifier).fetchManpower(type!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = ref.watch(typeProvider);
    final manpowerState = ref.watch(manpowerProvider);

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
      appBar: CustomAppBar(title: 'Add Team'),
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
                      hint: "Placeholder",
                    ),
                    const SizedBox(height: 20),

                    // --- Upload Profile Section ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Add Profile",
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
                            child: _selectedImage == null
                                ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.person_add_alt_1,
                                    size: 40, color: Colors.grey),
                                SizedBox(height: 6),
                                Text(
                                  "Upload Photo",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            )
                                : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
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
                          "Team Leads",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownSearch<ManpowerModel>(
                          selectedItem: _selectedLead,
                          itemAsString: (m) => m.fullName ?? '',
                          items: (String filter, LoadProps? props) {
                            return manpowerState.manpowerList
                                .where((m) => m.fullName!
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
                    DropdownSearch<ManpowerModel>.multiSelection(
                      items: (String filter, LoadProps? props) {
                        return manpowerState.manpowerList
                            .where((m) => m.fullName
                            .toLowerCase()
                            .contains(filter.toLowerCase()) ?? false)
                            .toList();
                      },
                      selectedItems: _selectedMembers,
                      itemAsString: (m) => m.fullName ?? '',
                      compareFn: (a, b) => a.id == b.id,
                      popupProps: PopupPropsMultiSelection.modalBottomSheet(
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
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          hintText: "Select Team Members",
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          border: const OutlineInputBorder(
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
                      child: RoundedButton(text: "Back",
                          color: Colors.white,
                          textColor: Colors.black,
                          onPressed: () {
                            Navigator.pop(context);
                          })

                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RoundedButton(text: "Submit",
                          color: Colors.blueAccent,
                          textColor: Colors.white,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final formData = FormData.fromMap({
                                "teamName": _teamNameController.text,
                                "teamLead": _selectedLead?.id ?? "",
                                "teamMembers":
                                _selectedMembers.map((m) => m.id).toList(),
                                if (_selectedImage != null)
                                  "file": await MultipartFile.fromFile(
                                  _selectedImage!.path,
                                  filename: "profile.jpg",
                                ),
                              });

                              await ref.read(teamProvider.notifier).createTeam(
                                type: type!,
                                siteId: widget.site.id,
                                formData: formData,
                              );
                              Navigator.pop(context);
                            }
                          })
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
}