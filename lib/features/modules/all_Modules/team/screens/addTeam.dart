import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';

import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../../../tour/domain/tour_controller.dart';
import '../../Manpower Details/model/manpower_model.dart';
import '../../Manpower Details/service/manPowerProvider.dart';
import '../../attendance/offline/repo/att_sync.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../../site_Details/repository/siteModel.dart';
import '../model/teamModel.dart';
import '../provider/teamProvider.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';

class AddTeamScreen extends ConsumerStatefulWidget {
  const AddTeamScreen({super.key});

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
    final colorScheme = Theme.of(context).colorScheme;
    try {
      // Step 1: Pick image from gallery
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        // Step 2: Crop the selected image
        final croppedFile = await _cropImage(File(pickedFile.path));

        if (croppedFile != null) {
          setState(() {
            _selectedImage = File(croppedFile.path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }

  Future<CroppedFile?> _cropImage(File imageFile) async {
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Team Profile',
            toolbarColor: colorScheme.surface,
            toolbarWidgetColor: colorScheme.onSurface,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
            cropGridRowCount: 3,
            cropGridColumnCount: 3,
            cropGridColor: colorScheme.onSurface.withOpacity(0.35),
            cropFrameColor: colorScheme.primary,
            cropGridStrokeWidth: 1,
            cropFrameStrokeWidth: 2,
            activeControlsWidgetColor: colorScheme.primary,
            // Free crop - no aspect ratio presets
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
            // Free crop - no aspect ratio presets
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

      return croppedFile;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cropping image: ${e.toString()}'),
          backgroundColor: colorScheme.error,
        ),
      );
      return null;
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text('Choose Image Source',
              style: TextStyle(color: colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: colorScheme.primary),
                title: const Text('Gallery'),
                onTap: () {
                  context.pop();
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: colorScheme.primary),
                title: const Text('Camera'),
                onTap: () {
                  context.pop();
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
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        final croppedFile = await _cropImage(File(pickedFile.path));

        if (croppedFile != null) {
          setState(() {
            _selectedImage = File(croppedFile.path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: colorScheme.error,
        ),
      );
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
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = ref.watch(typeProvider);
    final manpowerState = ref.watch(manpowerProvider);
    final siteId = ref.read(selectedSiteIdProvider);
    final colorScheme = Theme.of(context).colorScheme;

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
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
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
                      hint: "Add Team Name",
                    ),
                    const SizedBox(height: 20),

                    // --- Upload Profile Section ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add Profile",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            height: 130,
                            width: 120,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: colorScheme.outlineVariant),
                            ),
                            child: _selectedImage == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_add_alt_1,
                                          size: 40,
                                          color: colorScheme.onSurfaceVariant),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Upload Photo",
                                        style: TextStyle(
                                            color:
                                                colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  )
                                : Stack(
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
                                            decoration: BoxDecoration(
                                              color: colorScheme.error,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              size: 16,
                                              color: colorScheme.onError,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
                          popupProps: PopupProps.modalBottomSheet(
                            showSearchBox: true,
                            modalBottomSheetProps: ModalBottomSheetProps(
                              backgroundColor: colorScheme.surface,
                            ),
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'Search Team Lead',
                                hintStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            itemBuilder:
                                (context, item, isDisabled, isSelected) {
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                title: Text(
                                  item.fullName ?? '',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              );
                            },
                          ),
                          dropdownBuilder: (context, selectedItem) {
                            return Text(
                              selectedItem?.fullName ?? '',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                          decoratorProps: DropDownDecoratorProps(
                            decoration: InputDecoration(
                              hintText: "Select Team Lead",
                              filled: true,
                              fillColor: colorScheme.surface,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(
                                    color: colorScheme.outlineVariant
                                        .withOpacity(0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(
                                    color: colorScheme.outlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(8)),
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
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
                          itemAsString: (m) => m.fullName ?? '',
                          compareFn: (a, b) => a.id == b.id,
                          popupProps: PopupPropsMultiSelection.modalBottomSheet(
                            showSearchBox: true,
                            modalBottomSheetProps: ModalBottomSheetProps(
                              backgroundColor: colorScheme.surface,
                            ),
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'Search Members',
                                hintStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest,
                              ),
                            ),
                            itemBuilder:
                                (context, item, isDisabled, isSelected) {
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  isSelected
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                ),
                                title: Text(
                                  item.fullName ?? '',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              );
                            },
                            title: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Select Team Members",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          onChanged: (values) {
                            setState(() {
                              _selectedMembers = values;
                            });
                          },
                          dropdownBuilder: (context, selectedItems) {
                            return Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: selectedItems.map((member) {
                                return Chip(
                                  label: Text(
                                    member.fullName ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                  backgroundColor: colorScheme.primary,
                                  deleteIconColor: colorScheme.onPrimary,
                                  onDeleted: () {
                                    setState(() {
                                      _selectedMembers = _selectedMembers
                                          .where((m) => m.id != member.id)
                                          .toList();
                                    });
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            );
                          },
                          decoratorProps: DropDownDecoratorProps(
                            decoration: InputDecoration(
                              hintText: "Select Team Members",
                              filled: true,
                              fillColor: colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(
                                    color: colorScheme.outlineVariant
                                        .withOpacity(0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(8)),
                                borderSide: BorderSide(
                                    color: colorScheme.outlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(8)),
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
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
                        color: colorScheme.surface,
                        textColor: colorScheme.onSurface,
                        onPressed: () {
                          context.pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RoundedButton(
                        text: "Submit",
                        color: colorScheme.primary,
                        textColor: colorScheme.onPrimary,
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
                                  filename: "team_profile.jpg",
                                ),
                            });

                            await ref.read(teamProvider.notifier).createTeam(
                                  type: type!,
                                  siteId: siteId!,
                                  data: formData,
                                );
                            ref.invalidate(
                                manpowerSyncControllerProvider((type: type)));
                            await ref
                                .read(tourPersistenceProvider)
                                .markTeamDone();

                            context.pop();
                          }
                        },
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
}
