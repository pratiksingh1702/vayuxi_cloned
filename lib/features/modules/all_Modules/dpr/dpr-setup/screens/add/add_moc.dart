// screens/add_moc_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import '../../../../../../../core/local/isar_db.dart';
import '../../../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../../../../core/utlis/widgets/sidebar.dart';
import '../../../models/moc.dart';
import '../../../models/rate_file_models.dart';
import '../../../offline/mech/repo/rate_Repo.dart';
import '../../../providers/mocProvider.dart';
import 'package:file_picker/file_picker.dart';

import '../../../providers/rate_variant_provider.dart';
import 'package:untitled2/features/tour/core/tour_models.dart';
import 'package:untitled2/features/tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/core/screen_owned_tour_mixin.dart';
import 'package:untitled2/features/tour/definitions/setup_module_tours.dart';
import 'package:untitled2/features/tour/providers/tour_providers.dart';

class AddMOCPage extends ConsumerStatefulWidget {
  final MOC? moc;
  const AddMOCPage({super.key,this.moc});

  @override
  ConsumerState<AddMOCPage> createState() => _AddMOCPageState();
}

class _AddMOCPageState extends ConsumerState<AddMOCPage> with ScreenOwnedTourMixin<AddMOCPage> {
  static const _tourAdapter = TourPackageAdapter();
  final _formKey = GlobalKey<FormState>();
  final _nameTourKey = GlobalKey(debugLabel: 'dpr_moc_name');
  final _applyTourKey = GlobalKey(debugLabel: 'dpr_moc_apply_all');
  final _imageTourKey = GlobalKey(debugLabel: 'dpr_moc_image');
  final _saveTourKey = GlobalKey(debugLabel: 'dpr_moc_save');
  final _nameController = TextEditingController();
  String? _existingImageUrl; // backend image
  File? _selectedImage;      // newly picked image
  bool _isApplied = false;



  bool _isSubmitting = false;
  String? _lastTourStep;
  @override
  void initState() {
    super.initState();

    final moc = widget.moc;
    if (moc != null) {
      _nameController.text = moc.name;

      // Handle image (URL or local)
      if (moc.imageUrl != null && moc.imageUrl!.isNotEmpty) {
        _existingImageUrl = moc.imageUrl!;
      }
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  Future<void> _pickImage() async {
    final helper = ImageUploadHelper(context);

    final file = await helper.pickAndCropImage(
      enableCropping: true,
      cropTitle: 'Crop MOC Image',
    );

    if (file != null) {
      setState(() {
        _selectedImage = file;
      });
    }
  }






  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final siteID = ref.read(selectedSiteIdProvider)!;
      final name = _nameController.text.trim();

      if (widget.moc == null) {
        // ================= CREATE =================

        final rateFileMeta = ref.watch(rateFileMetaProvider(siteID));





        final rateUploadId = rateFileMeta['rateFileId'] ;
        // In _submitForm, inside the CREATE block:
        final existingNames =
        ref.read(mocListDetectedProvider(siteID));

        final existingWithImages =
        ref.read(mocWithImagesProvider(siteID));

        await ref.read(mocProvider.notifier).create(
          name: name,
          rateUploadId: rateUploadId,
          existingMocNames: existingNames,
          existingMocsWithImages: existingWithImages,
          image: _selectedImage!,
        );
        final repo = RateRepository(AppIsarDB.isar);
        await repo.syncRateFile(siteID);

        ref.invalidate(rateFileAnalysisProvider(siteID));
      }
      else {
        // ================= UPDATE =================
        final siteID = ref.read(selectedSiteIdProvider)!;
        final rateFileMeta = ref.read(rateFileMetaProvider(siteID));
        final rateUploadId = rateFileMeta['rateFileId'];

        final existingNames =
        ref.read(mocListDetectedProvider(siteID));

        final existingWithImages =
        ref.read(mocWithImagesProvider(siteID));

        final updatedNames = existingNames.map((e) {
          return e == widget.moc!.name ? name : e;
        }).toList();

        final updatedWithImages = existingWithImages.map((e) {
          if (e.name == widget.moc!.name) {
            return NamedImage(
              name: name,
              image: _selectedImage != null
                  ? _selectedImage!.path
                  : e.image,
            );
          }
          return e;
        }).toList();

        await ref.read(mocProvider.notifier).create(
          name: "", // no new addition
          rateUploadId: rateUploadId,
          existingMocNames: updatedNames,
          existingMocsWithImages: updatedWithImages,
          image: null,
        );

        ref.invalidate(rateFileAnalysisProvider(siteID));
      }

      if (!mounted) return;
      context.pop(true);
    } catch (e, stackTrace) {
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _syncTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${SetupModuleTours.dprSetupId}_moc_form',
      title: 'Add MOC',
      description: 'Create a DPR material option.',
      icon: Icons.account_tree_rounded,
      steps: [
        AppTourStep(
          id: 'dpr_moc_name',
          title: 'MOC Name',
          body: 'Enter the material or construction type used in DPR entry.',
          targetKey: _nameTourKey,
          progressLabel: 'Name',
        ),
        AppTourStep(
          id: 'dpr_moc_apply_all',
          title: 'Available Sites',
          body: 'Choose whether this MOC is only for this site or all company sites.',
          targetKey: _applyTourKey,
          progressLabel: 'Sites',
        ),
        AppTourStep(
          id: 'dpr_moc_image',
          title: 'MOC Image',
          body: 'Upload a clear image so this MOC is easy to identify during entry.',
          targetKey: _imageTourKey,
          progressLabel: 'Image',
        ),
        AppTourStep(
          id: 'dpr_moc_save',
          title: 'Save MOC',
          body: 'Save the completed MOC setup.',
          targetKey: _saveTourKey,
          progressLabel: 'Save',
        ),
      ],
    );
    bindScreenOwnedTour(tourId: definition.id, showcaseContext: showcaseContext);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
      final controller = ref.read(appTourControllerProvider.notifier);
      if (ref.read(appTourControllerProvider).status != AppTourStatus.running) {
        await controller.maybeStartRuntimeTour(
          definition,
          policyTourId: SetupModuleTours.dprSetupId,
        );
      }
      final tour = controller.activeTour;
      final step = controller.currentStep;
      if (tour == null || tour.id != definition.id) {
        if (_lastTourStep != null) _tourAdapter.dismiss(showcaseContext);
        _lastTourStep = null;
        return;
      }
      final key = step == null ? null : '${tour.id}:${step.id}';
      if (step == null || key == _lastTourStep) return;
      _lastTourStep = key;
      _tourAdapter.showStep(showcaseContext, step);
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) => Showcase.withWidget(
        key: key,
        container: const SizedBox.shrink(),
        overlayOpacity: 0.72,
        targetPadding: const EdgeInsets.all(8),
        targetBorderRadius: BorderRadius.circular(14),
        child: child,
      );


  @override
  Widget build(BuildContext context) {
    ref.watch(appTourControllerProvider);
    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncTour(showcaseContext);
        return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: const CustomDrawer(),
      appBar:CustomAppBar(title: "Add MOC"),
      backgroundColor: AppColors.lightBlue,
      body: CornerClippedScreenSimple(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name Field
                _tourTarget(
                  _nameTourKey,
                  CustomTextField(
                    label: 'MOC Name',
                    hint: 'Enter MOC name (e.g., Stainless Steel, HDPE)',
                    isRequired: true,
                    TextSize: 16,
                    controller: _nameController,
                    keyboardType: TextInputType.text,
                  ),
                ),
                _tourTarget(_applyTourKey, _buildIsAppliedField()),
                const SizedBox(height: 24),
        
                // Image Upload Section

                _tourTarget(
                  _imageTourKey,
                  UploadBox(
                    title: 'MOC Image',
                    subtitle: 'Tap to change image',
                    buttonText: 'Change Image',
                    onPressed: _pickImage,
                    previewWidget:
                        (_selectedImage != null || _existingImageUrl != null)
                            ? UploadBoxPreview(
                                file: _selectedImage,
                                source: _existingImageUrl,
                                isImage: true,
                                onRemove: () {
                                  setState(() {
                                    _selectedImage = null;
                                    _existingImageUrl = null;
                                  });
                                },
                                onEdit: _pickImage,
                              )
                            : null,
                  ),
                ),


        
                // Submit Button
                _tourTarget(_saveTourKey, ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Adding MOC...'),
                    ],
                  )
                      : const Text(
                    'Save MOC',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )),
                const SizedBox(height: 12),
        
                // Cancel Button
                OutlinedButton(
                  onPressed: _isSubmitting ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
        );
      },
    );
  }
  Widget _buildIsAppliedField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply to all sites in company',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isApplied
                      ? 'This moc will be available for ALL sites in your company'
                      : 'This moc will only be available for the current site',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isApplied,
            onChanged: (value) {
              setState(() {
                _isApplied = value;
              });
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }
}
