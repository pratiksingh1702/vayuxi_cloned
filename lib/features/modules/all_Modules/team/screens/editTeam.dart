import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';

import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../../../tour/core/tour_models.dart';
import '../../../../tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/core/screen_owned_tour_mixin.dart';
import '../../../../tour/definitions/manpower_team_module_tours.dart';
import '../../../../tour/providers/tour_providers.dart';
import '../../Manpower Details/model/manpower_model.dart';
import '../../Manpower Details/service/manPowerProvider.dart';
import '../../attendance/offline/repo/att_sync.dart';
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

class _EditTeamScreenState extends ConsumerState<EditTeamScreen> with ScreenOwnedTourMixin<EditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();

  ManpowerModel? _selectedLead;
  List<ManpowerModel> _selectedMembers = [];
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isDataInitialized = false;
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  String? _lastShowcasedTourStepId;
  final GlobalKey _nameTourKey = GlobalKey(debugLabel: 'team_edit_name');
  final GlobalKey _imageTourKey = GlobalKey(debugLabel: 'team_edit_image');
  final GlobalKey _leadTourKey = GlobalKey(debugLabel: 'team_edit_lead');
  final GlobalKey _membersTourKey = GlobalKey(debugLabel: 'team_edit_members');
  final GlobalKey _submitTourKey = GlobalKey(debugLabel: 'team_edit_submit');

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
        debugPrint(
            '✅ Team lead found: ${_selectedLead?.fullName} (${_selectedLead?.id})');
      } catch (e) {
        _selectedLead = null;
        debugPrint('❌ Team lead not found with ID: ${widget.team.teamLeadId}');
        debugPrint(
            '   Available IDs: ${manpowerList.map((m) => m.id).join(", ")}');
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
      final missingIds =
          widget.team.teamMemberIds.where((id) => !foundIds.contains(id));
      if (missingIds.isNotEmpty) {
        debugPrint(
            '⚠️ Some team members not found in manpower list: $missingIds');
      }
    }

    _isDataInitialized = true;
    setState(() {});
  }

  Future<void> _cropImage(File imageFile) async {
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
            cropGridColor: colorScheme.onSurface.withValues(alpha: 0.35),
            cropFrameColor: colorScheme.primary,
            cropGridStrokeWidth: 1,
            cropFrameStrokeWidth: 2,
            activeControlsWidgetColor: colorScheme.primary,
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
            backgroundColor: colorScheme.error,
          ),
        );
      }
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
        await _cropImage(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: colorScheme.error,
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
        else if (_selectedImage == null && _currentImageUrl == null)
          "teamLeadImage": "",
      });
      print("===== FORM DATA =====");

      for (var field in formData.fields) {
        print("${field.key}: ${field.value}");
      }

      for (var file in formData.files) {
        print("${file.key}: ${file.value.filename}");
      }

      print("=====================");
      final type = ref.read(typeProvider)!;
      final colorScheme = Theme.of(context).colorScheme;

      try {
        await ref.read(teamProvider.notifier).updateTeam(
              siteId: widget.site.id,
              teamId: widget.team.id,
              data: formData,
              type: type,
            );
        ref.invalidate(manpowerSyncControllerProvider((type: type)));

        if (!mounted) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Team updated successfully'),
              backgroundColor: colorScheme.primary,
            ),
          );

        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            context.pop();
          }
        });
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Failed to update team: ${e.toString()}'),
              backgroundColor: colorScheme.error,
            ),
          );
      }
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  String _memberName(ManpowerModel member) {
    return (member.fullName ?? '').trim().isNotEmpty
        ? member.fullName!.trim()
        : 'Unnamed member';
  }

  void _setTeamLead(ManpowerModel? selected) {
    setState(() {
      _selectedLead = selected;
      if (selected != null &&
          !_selectedMembers.any((member) => member.id == selected.id)) {
        _selectedMembers = [selected, ..._selectedMembers];
      }
    });
  }

  Future<void> _openMemberPicker(
    List<ManpowerModel> manpowerList,
    FormFieldState<List<ManpowerModel>> field,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final search = TextEditingController();
    var draft = List<ManpowerModel>.from(_selectedMembers);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = search.text.trim().toLowerCase();
            final filtered = manpowerList.where((member) {
              return _memberName(member).toLowerCase().contains(query);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select Team Members',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: search,
                        decoration: InputDecoration(
                          hintText: 'Search members',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text('No members found'))
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final member = filtered[index];
                                  final selected =
                                      draft.any((item) => item.id == member.id);
                                  void toggle() {
                                    setModalState(() {
                                      if (selected) {
                                        draft = draft
                                            .where(
                                                (item) => item.id != member.id)
                                            .toList();
                                      } else {
                                        draft = [...draft, member];
                                      }
                                    });
                                    setState(() {
                                      _selectedMembers = draft;
                                    });
                                    field.didChange(_selectedMembers);
                                  }

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(_memberName(member)),
                                    trailing: Checkbox(
                                      value: selected,
                                      onChanged: (_) => toggle(),
                                    ),
                                    onTap: toggle,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    search.dispose();
  }

  Widget _buildMemberSelector(
    List<ManpowerModel> manpowerList,
    ColorScheme colorScheme,
  ) {
    return FormField<List<ManpowerModel>>(
      initialValue: _selectedMembers,
      validator: (_) =>
          _selectedMembers.isEmpty ? 'Select at least one member' : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openMemberPicker(manpowerList, field),
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: 'Select Team Members',
                  errorText: field.errorText,
                  filled: true,
                  fillColor: colorScheme.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedMembers.isEmpty
                            ? 'Select Team Members'
                            : '${_selectedMembers.length} member${_selectedMembers.length == 1 ? '' : 's'} selected',
                        style: TextStyle(
                          color: _selectedMembers.isEmpty
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            if (_selectedMembers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedMembers.map((member) {
                  return InputChip(
                    label: Text(_memberName(member)),
                    onDeleted: () {
                      setState(() {
                        _selectedMembers = _selectedMembers
                            .where((item) => item.id != member.id)
                            .toList();
                      });
                      field.didChange(_selectedMembers);
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }

  void _syncTeamEditTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${ManpowerTeamModuleTours.teamId}_form_edit',
      title: 'Edit Team',
      description: 'Learn how to update a team.',
      icon: Icons.groups_rounded,
      steps: [
        const AppTourStep(
          id: 'team_edit_intro',
          title: 'Edit Team',
          body: 'Use this form to update a saved team.',
          progressLabel: 'Edit team',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'team_edit_name',
          title: 'Team Name',
          body: 'Update the team name here.',
          targetKey: _nameTourKey,
          progressLabel: 'Name',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'team_edit_image',
          title: 'Team Photo',
          body: 'Change or remove the team photo here.',
          targetKey: _imageTourKey,
          progressLabel: 'Photo',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'team_edit_lead',
          title: 'Team Lead',
          body: 'Update the person responsible for this team.',
          targetKey: _leadTourKey,
          progressLabel: 'Lead',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'team_edit_members',
          title: 'Team Members',
          body: 'Update the manpower members included in this team.',
          targetKey: _membersTourKey,
          progressLabel: 'Members',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'team_edit_submit',
          title: 'Update Team',
          body: 'Tap Update Team when changes are ready.',
          targetKey: _submitTourKey,
          progressLabel: 'Update',
          tooltipBottomOffset: 96,
          autoScrollToTarget: true,
        ),
      ],
    );
    bindScreenOwnedTour(tourId: definition.id, showcaseContext: showcaseContext);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final state = ref.read(appTourControllerProvider);
      final controller = ref.read(appTourControllerProvider.notifier);
      if (state.status != AppTourStatus.running) {
        await controller.maybeStartRuntimeTour(
          definition,
          policyTourId: ManpowerTeamModuleTours.teamId,
        );
      }
      final step = controller.currentStep;
      final activeTour = controller.activeTour;
      if (activeTour == null || activeTour.id != definition.id) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) return;
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      await _tourPackageAdapter.showStep(showcaseContext, step);
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return Showcase.withWidget(
      key: key,
      container: const SizedBox.shrink(),
      overlayOpacity: 0.72,
      targetPadding: const EdgeInsets.all(8),
      targetBorderRadius: BorderRadius.circular(14),
      disableDefaultTargetGestures: false,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final manpowerState = ref.watch(manpowerProvider);
    final colorScheme = Theme.of(context).colorScheme;

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

    ref.watch(appTourControllerProvider);
    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncTeamEditTour(showcaseContext);
        return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
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
                    _tourTarget(
                      _nameTourKey,
                      CustomTextField(
                        label: "Team Name",
                        isRequired: true,
                        controller: _teamNameController,
                        hint: "Enter team name",
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Upload Profile Section ---
                    _tourTarget(
                      _imageTourKey,
                      Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Team Profile",
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
                                              errorBuilder:
                                                  (context, error, stackTrace) {
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
                                      )
                                    : _buildPlaceholderImage(),
                          ),
                        ),
                      ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- Team Lead Card ---
                    _tourTarget(
                      _leadTourKey,
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
                            _setTeamLead(selected);
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
                                        .withValues(alpha: 0)),
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
                    ),

                    const SizedBox(height: 20),

                    // --- Team Members Card ---
                    _tourTarget(
                      _membersTourKey,
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
                        _buildMemberSelector(
                          manpowerState.manpowerList,
                          colorScheme,
                        ),
                      ],
                      ),
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
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _tourTarget(
                        _submitTourKey,
                        RoundedButton(
                          text: "Update Team",
                          color: colorScheme.primary,
                          textColor: colorScheme.onPrimary,
                          onPressed: _submitForm,
                        ),
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
      },
    );
  }

  Widget _buildPlaceholderImage() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_add_alt_1,
            size: 40, color: colorScheme.onSurfaceVariant),
        const SizedBox(height: 6),
        Text(
          "Upload Photo",
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
