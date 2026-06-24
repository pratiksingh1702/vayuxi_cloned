import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/fields/custom_textField.dart';
import 'package:untitled2/features/modules/all_Modules/structure_work/boq/models/boq_structure_model.dart';
import 'package:untitled2/features/modules/all_Modules/structure_work/boq/providers/boq_structure_provider.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/features/tour/core/tour_models.dart';
import 'package:untitled2/features/tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/core/screen_owned_tour_mixin.dart';
import 'package:untitled2/features/tour/definitions/setup_module_tours.dart';
import 'package:untitled2/features/tour/providers/tour_providers.dart';
import 'boq_import_sheet.dart';

class BoqItemDetailsScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;
  final String? boqId;
  final BOQStructureItem? item;

  const BoqItemDetailsScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    this.boqId,
    this.item,
  });

  @override
  ConsumerState<BoqItemDetailsScreen> createState() =>
      _BoqItemDetailsScreenState();
}

class _BoqItemDetailsScreenState extends ConsumerState<BoqItemDetailsScreen>
    with ScreenOwnedTourMixin<BoqItemDetailsScreen> {
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  final GlobalKey _boqNameTourKey = GlobalKey(debugLabel: 'structure_boq_name');
  final GlobalKey _identityTourKey =
      GlobalKey(debugLabel: 'structure_boq_identity');
  final GlobalKey _measurementTourKey =
      GlobalKey(debugLabel: 'structure_boq_measurements');
  final GlobalKey _saveTourKey = GlobalKey(debugLabel: 'structure_boq_save');
  String? _lastShowcasedTourStepId;

  final TextEditingController boqNameController = TextEditingController();
  final TextEditingController markController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    markController.addListener(_refreshSplitPreview);
    qtyController.addListener(_refreshSplitPreview);
    if (widget.item != null) {
      markController.text = widget.item!.assemblyMark;
      descController.text = widget.item!.typeDescription;
      qtyController.text = widget.item!.quantity.toString();
      if (widget.item!.length != null)
        lengthController.text = widget.item!.length.toString();
      if (widget.item!.width != null)
        widthController.text = widget.item!.width.toString();
      if (widget.item!.height != null)
        heightController.text = widget.item!.height.toString();
      if (widget.item!.netWeightPerUnit != null)
        weightController.text = widget.item!.netWeightPerUnit.toString();
    } else {
      boqNameController.text = "${widget.siteName} BOQ";
    }
  }

  @override
  void dispose() {
    markController.removeListener(_refreshSplitPreview);
    qtyController.removeListener(_refreshSplitPreview);
    boqNameController.dispose();
    markController.dispose();
    descController.dispose();
    qtyController.dispose();
    lengthController.dispose();
    widthController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    final isEdit = widget.item != null;
    final boqName = boqNameController.text.trim();
    final assemblyMark = markController.text.trim();
    final typeDescription = descController.text.trim();
    final quantity = double.tryParse(qtyController.text.trim());

    if (!isEdit && boqName.isEmpty) {
      AppToast.error("Please enter BOQ name");
      return;
    }

    if (assemblyMark.isEmpty ||
        typeDescription.isEmpty ||
        quantity == null ||
        quantity <= 0) {
      AppToast.error("Please fill all required fields");
      return;
    }

    final payload = {
      "assemblyMark": assemblyMark,
      "typeDescription": typeDescription,
      "quantity": quantity,
      "length": double.tryParse(lengthController.text.trim()) ?? 0,
      "width": double.tryParse(widthController.text.trim()) ?? 0,
      "height": double.tryParse(heightController.text.trim()) ?? 0,
      "netWeightPerUnit": double.tryParse(weightController.text.trim()) ?? 0,
    };

    setState(() => isLoading = true);

    final notifier = ref.read(boqStructureProvider.notifier);
    final success = isEdit
        ? await notifier.updateBOQItem(
            widget.siteId,
            widget.boqId ?? '',
            widget.item!.id,
            payload,
          )
        : await notifier.createManualBOQ(
            widget.siteId,
            boqName: boqName,
            items: [payload],
          );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (success) {
      AppToast.success(isEdit
          ? "BOQ item updated successfully"
          : "BOQ created successfully");
      Navigator.pop(context, true);
    } else {
      final error = ref.read(boqStructureProvider).error;
      AppToast.error(error ?? "Failed to save BOQ item");
    }
  }

  Widget _buildSplitPreview(ColorScheme colorScheme) {
    final quantity = double.tryParse(qtyController.text.trim()) ?? 0;
    final mark = markController.text.trim();

    if (mark.isEmpty || quantity <= 1 || quantity % 1 != 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        "This will create ${quantity.toInt()} marks: $mark-1 to $mark-${quantity.toInt()}",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  void _refreshSplitPreview() {
    if (mounted) setState(() {});
  }

  void _syncTour(BuildContext showcaseContext) {
    final isEdit = widget.item != null;
    final definition = AppTourDefinition(
      id: '${SetupModuleTours.boqUploadId}_${widget.siteId}_structure_item_${isEdit ? 'edit' : 'add'}',
      title: isEdit ? 'Edit BOQ Item' : 'Add BOQ Item',
      description: 'Add or update one structural BOQ item.',
      icon: Icons.inventory_2_outlined,
      steps: [
        AppTourStep(
          id: 'structure_boq_item_intro',
          title: isEdit ? 'Edit BOQ Item' : 'Add BOQ Item',
          body: isEdit
              ? 'Use this screen to update the selected structural BOQ item.'
              : 'Use this screen to create a BOQ and add the first structural item manually.',
          progressLabel: 'Intro',
          useSpotlight: false,
        ),
        if (!isEdit)
          AppTourStep(
            id: 'structure_boq_name',
            title: 'BOQ Name',
            body: 'Give this BOQ a clear name so it is easy to identify later.',
            targetKey: _boqNameTourKey,
            progressLabel: 'BOQ',
            autoScrollToTarget: true,
          ),
        AppTourStep(
          id: 'structure_boq_identity',
          title: 'Item Identity',
          body: 'Enter the assembly mark and item type, like BR1 and Column.',
          targetKey: _identityTourKey,
          progressLabel: 'Identity',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'structure_boq_measurements',
          title: 'Measurements',
          body:
              'Enter quantity and optional size or weight details. If quantity is a whole number above 1, the app shows the mark split preview.',
          targetKey: _measurementTourKey,
          progressLabel: 'Measurements',
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'structure_boq_save',
          title: 'Save Item',
          body: 'Tap Save Item when the BOQ item details are ready.',
          targetKey: _saveTourKey,
          progressLabel: 'Save',
          tooltipBottomOffset: 96,
          autoScrollToTarget: true,
        ),
      ],
    );

    bindScreenOwnedTour(
        tourId: definition.id, showcaseContext: showcaseContext);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);
      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: SetupModuleTours.boqUploadId,
        );
      }
      final tour = tourController.activeTour;
      final step = tourController.currentStep;
      if (tour == null || tour.id != definition.id) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${tour.id}:${step.id}';
      if (step == null) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      _tourPackageAdapter.showStep(showcaseContext, step);
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

  Widget _buildFormCard({
    required ColorScheme colorScheme,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title, icon, colorScheme),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildResponsivePair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              first,
              const SizedBox(height: 12),
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveTriple(Widget first, Widget second, Widget third) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              first,
              const SizedBox(height: 12),
              second,
              const SizedBox(height: 12),
              third,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
            const SizedBox(width: 12),
            Expanded(child: third),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEdit = widget.item != null;
    ref.watch(appTourControllerProvider);

    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncTour(showcaseContext);
        return Scaffold(
          drawer: const CustomDrawer(),
          backgroundColor: colorScheme.surfaceContainerLowest,
          appBar: CustomAppBar(
            title: isEdit ? "Edit BOQ Item" : "Add BOQ Item",
          ),
          body: BottomButtonWrapper(
            customButtons: [
              CustomButton(
                button: _tourTarget(
                  _saveTourKey,
                  RoundedButton(
                    text: isLoading ? "Saving..." : "Save Item",
                    color: colorScheme.primary,
                    textColor: colorScheme.onPrimary,
                    onPressed: _saveItem,
                  ),
                ),
              ),
            ],
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isEdit) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final saved = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BoqImportSheetScreen(
                                siteId: widget.siteId,
                                siteName: widget.siteName,
                              ),
                            ),
                          );
                          if (saved == true && mounted) {
                            Navigator.pop(context, true);
                          }
                        },
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text("Import BOQ Sheet"),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: Divider(color: colorScheme.outlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR ADD MANUALLY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                            child: Divider(color: colorScheme.outlineVariant)),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (!isEdit) ...[
                    _tourTarget(
                      _boqNameTourKey,
                      _buildFormCard(
                        colorScheme: colorScheme,
                        title: "BOQ Details",
                        icon: Icons.inventory_2_outlined,
                        children: [
                          CustomTextField(
                            label: "BOQ Name",
                            controller: boqNameController,
                            isRequired: true,
                            hint: "e.g., Main Shed BOQ",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _tourTarget(
                    _identityTourKey,
                    _buildFormCard(
                      colorScheme: colorScheme,
                      title: "Identification",
                      icon: Icons.badge_outlined,
                      children: [
                        CustomTextField(
                          label: "Assembly Mark / No.",
                          controller: markController,
                          isRequired: true,
                          hint: "e.g., BR1",
                        ),
                        CustomTextField(
                          label: "Type Description",
                          controller: descController,
                          isRequired: true,
                          hint: "e.g., Column",
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _tourTarget(
                    _measurementTourKey,
                    _buildFormCard(
                      colorScheme: colorScheme,
                      title: "Measurements",
                      icon: Icons.straighten_rounded,
                      children: [
                        _buildResponsivePair(
                          CustomTextField(
                            label: "Quantity",
                            controller: qtyController,
                            isRequired: true,
                            keyboardType: TextInputType.number,
                            hint: "e.g., 12",
                          ),
                          CustomTextField(
                            label: "Unit Weight (kg)",
                            controller: weightController,
                            isRequired: false,
                            keyboardType: TextInputType.number,
                            hint: "e.g., 150",
                          ),
                        ),
                        _buildSplitPreview(colorScheme),
                        const SizedBox(height: 12),
                        _buildResponsiveTriple(
                          CustomTextField(
                            label: "Length (m)",
                            controller: lengthController,
                            isRequired: false,
                            keyboardType: TextInputType.number,
                            hint: "Optional",
                          ),
                          CustomTextField(
                            label: "Width (m)",
                            controller: widthController,
                            isRequired: false,
                            keyboardType: TextInputType.number,
                            hint: "Optional",
                          ),
                          CustomTextField(
                            label: "Height (m)",
                            controller: heightController,
                            isRequired: false,
                            keyboardType: TextInputType.number,
                            hint: "Optional",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
      String title, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
