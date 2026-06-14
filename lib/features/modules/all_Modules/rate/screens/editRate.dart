import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/common_functions.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/fields/searchableDropdown.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../tour/core/tour_models.dart';
import '../../../../tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/core/screen_owned_tour_mixin.dart';
import '../../../../tour/definitions/site_rate_module_tours.dart';
import '../../../../tour/providers/tour_providers.dart';
import '../../site_Details/repository/siteModel.dart';
import '../data/rateApi.dart';
import '../data/rate_provider.dart';
import '../domain/rateModel.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';

class EditRateScreen extends ConsumerStatefulWidget {
  final SiteModel site;
  final Rate rate;

  const EditRateScreen({
    super.key,
    required this.site,
    required this.rate,
  });

  @override
  ConsumerState<EditRateScreen> createState() => _EditRateScreenState();
}

class _EditRateScreenState extends ConsumerState<EditRateScreen> with ScreenOwnedTourMixin<EditRateScreen> {
  late TextEditingController siteNameController;
  late TextEditingController hsnCodeController;
  late TextEditingController rateController;
  late TextEditingController remarkController;
  late TextEditingController uomController;

  final FocusNode uomFocusNode = FocusNode();
  bool isCustomUOM = false;

  List<String> uomList = [];
  bool isLoadingUom = false;
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  String? _lastShowcasedTourStepId;
  final GlobalKey _productTourKey =
      GlobalKey(debugLabel: 'rate_edit_product');
  final GlobalKey _hsnTourKey = GlobalKey(debugLabel: 'rate_edit_hsn');
  final GlobalKey _rateTourKey = GlobalKey(debugLabel: 'rate_edit_rate');
  final GlobalKey _uomTourKey = GlobalKey(debugLabel: 'rate_edit_uom');
  final GlobalKey _remarkTourKey = GlobalKey(debugLabel: 'rate_edit_remark');
  final GlobalKey _saveTourKey = GlobalKey(debugLabel: 'rate_edit_save');

  @override
  void initState() {
    super.initState();
    // Prefill fields with existing data
    siteNameController = TextEditingController(text: widget.rate.serviceName);
    hsnCodeController = TextEditingController(text: widget.rate.hsnSacCode);
    rateController = TextEditingController(text: widget.rate.rate.toString());
    remarkController = TextEditingController(text: widget.rate.remarks ?? "");
    uomController = TextEditingController(text: widget.rate.uom);
    _loadUOM();

    // Check if the existing UOM is custom
    final existingUOM = widget.rate.uom;
    isCustomUOM = !uomList.contains(existingUOM);
  }

  Future<void> _loadUOM() async {
    try {
      setState(() => isLoadingUom = true);

      final response = await RateApiClient().getRateUOM();

      uomList =
          response.map<String>((item) => item['name'].toString()).toList();

      setState(() {});
    } catch (e) {
      print("❌ Failed to load UOM: $e");
    } finally {
      setState(() => isLoadingUom = false);
    }
  }

  void _showUOMBottomSheet() {
    // If user is typing custom UOM, don't show bottom sheet
    if (isCustomUOM) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Select Unit of Measurement",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: uomList.length,
              itemBuilder: (context, index) {
                final uom = uomList[index];
                return ListTile(
                  title: Text(uom),
                  trailing: uomController.text == uom
                      ? Icon(Icons.check, color: colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      uomController.text = uom;
                      isCustomUOM = false;
                    });
                    context.pop();
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _onUOMChanged(String value) {
    // Check if the current value matches any predefined UOM
    final isPredefined = uomList.contains(value);
    setState(() {
      isCustomUOM = !isPredefined && value.isNotEmpty;
    });
  }

  Future<void> _updateRate() async {
    if (siteNameController.text.isEmpty ||
        rateController.text.isEmpty ||
        uomController.text.isEmpty) {
      AppToast.info("Please fill all required fields");
      return;
    }

    final updatedData = {
      "serviceName": siteNameController.text,
      "hsnSacCode": hsnCodeController.text,
      "rate": double.tryParse(rateController.text) ?? 0,
      "uom": uomController.text.trim(), // Use whatever is in the field
      "remarks": remarkController.text,
    };

    try {
      final siteId = widget.site.id;
      await ref
          .read(rateNotifierProvider.notifier)
          .updateRate(updatedData, siteId, widget.rate.id);

      AppToast.success('Rate updated successfully');
      context.pop(true); // return true to refresh list if needed
    } catch (e, stackrace) {
      print(e);
      print(stackrace);
      final error = extractBackendError(e);
      AppToast.error("❌ Failed to update rate:$error");
    }
  }

  void _syncRateEditTour(BuildContext showcaseContext) {
    final definition = AppTourDefinition(
      id: '${SiteRateModuleTours.rateId}_form_edit',
      title: 'Edit Rate',
      description: 'Learn how to update an existing rate.',
      icon: Icons.edit_rounded,
      steps: [
        const AppTourStep(
          id: 'rate_edit_intro',
          title: 'Edit Rate',
          body: 'Use this form to correct or update a saved rate.',
          progressLabel: 'Edit rate',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'rate_edit_product',
          title: 'Product or Service',
          body: 'Change the item, service, or work name here.',
          targetKey: _productTourKey,
          progressLabel: 'Product',
          showTooltip: false,
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'rate_edit_hsn',
          title: 'HSN/SAC Code',
          body: 'Update the HSN or SAC code if it needs correction.',
          targetKey: _hsnTourKey,
          progressLabel: 'HSN/SAC',
          showTooltip: false,
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'rate_edit_rate',
          title: 'Rate Amount',
          body: 'Change the saved amount for this item or work.',
          targetKey: _rateTourKey,
          progressLabel: 'Rate',
          showTooltip: false,
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'rate_edit_uom',
          title: 'Unit of Measurement',
          body: 'Choose or type the unit used for this rate.',
          targetKey: _uomTourKey,
          progressLabel: 'UOM',
          showTooltip: false,
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'rate_edit_remark',
          title: 'Remarks',
          body: 'Update any extra note for this rate.',
          targetKey: _remarkTourKey,
          progressLabel: 'Remarks',
          showTooltip: false,
          autoScrollToTarget: true,
        ),
        AppTourStep(
          id: 'rate_edit_save',
          title: 'Save Changes',
          body: 'Tap Save when the updated rate details are ready.',
          targetKey: _saveTourKey,
          progressLabel: 'Save',
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
      final tourState = ref.read(appTourControllerProvider);
      final tourController = ref.read(appTourControllerProvider.notifier);
      if (tourState.status != AppTourStatus.running) {
        await tourController.maybeStartRuntimeTour(
          definition,
          policyTourId: SiteRateModuleTours.rateId,
        );
      }
      final step = tourController.currentStep;
      final activeTour = tourController.activeTour;
      if (activeTour == null || activeTour.id != definition.id) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
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

  Widget _tourTarget(
    GlobalKey key,
    Widget child, {
    bool advanceOnTap = false,
  }) {
    return Showcase.withWidget(
      key: key,
      container: const SizedBox.shrink(),
      overlayOpacity: 0.72,
      targetPadding: const EdgeInsets.all(8),
      targetBorderRadius: BorderRadius.circular(14),
      disableDefaultTargetGestures: false,
      disposeOnTap: advanceOnTap ? true : null,
      onTargetClick: advanceOnTap
          ? () => ref.read(appTourControllerProvider.notifier).next()
          : null,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    ref.watch(appTourControllerProvider);
    return ShowCaseWidget(
      builder: (showcaseContext) {
        _syncRateEditTour(showcaseContext);
        return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: "Edit Rate"),
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
              button: _tourTarget(
            _saveTourKey,
            RoundedButton(
              text: "Save",
              color: colorScheme.primary,
              textColor: colorScheme.onPrimary,
              onPressed: _updateRate,
            ),
          ))
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _tourTarget(
                _productTourKey,
                CustomTextField(
                  label: "Product",
                  controller: siteNameController,
                  isRequired: true,
                ),
                advanceOnTap: true,
              ),
              _tourTarget(
                _hsnTourKey,
                CustomTextField(
                  label: "HSN/SAC Code",
                  controller: hsnCodeController,
                  isRequired: false,
                ),
                advanceOnTap: true,
              ),
              _tourTarget(
                _rateTourKey,
                CustomTextField(
                  label: "Rate in Rs.",
                  controller: rateController,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
                advanceOnTap: true,
              ),

              // UOM Section with Label
              const SizedBox(height: 8),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: "UOM",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              isLoadingUom
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  : _tourTarget(
                      _uomTourKey,
                      SearchableDropdown(
                        data: uomList,
                        value: uomController.text,
                        placeholder: "Search or type Unit of Measurement",
                        onSelect: (value) {
                          setState(() {
                            uomController.text = value;
                          });
                        },
                        containerDecoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(color: colorScheme.outlineVariant),
                            right:
                                BorderSide(color: colorScheme.outlineVariant),
                            top: BorderSide(color: colorScheme.outlineVariant),
                            bottom:
                                BorderSide(color: colorScheme.outlineVariant),
                          ),
                        ),
                      ),
                      advanceOnTap: true,
                    ),
              const SizedBox(height: 4),

              // Combined UOM Field - Can type or select from dropdown

              // Show indicator if using custom UOM
              if (isCustomUOM && uomController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 14, color: colorScheme.tertiary),
                      const SizedBox(width: 4),
                      Text(
                        "Using custom UOM",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.tertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              _tourTarget(
                _remarkTourKey,
                CustomTextField(
                  label: "Remark (if any)",
                  controller: remarkController,
                  maxLines: 3,
                ),
                advanceOnTap: true,
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
