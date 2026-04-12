import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/common_functions.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/fields/searchableDropdown.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
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

class _EditRateScreenState extends ConsumerState<EditRateScreen> {
  late TextEditingController siteNameController;
  late TextEditingController hsnCodeController;
  late TextEditingController rateController;
  late TextEditingController remarkController;
  late TextEditingController uomController;

  final FocusNode uomFocusNode = FocusNode();
  bool isCustomUOM = false;

  List<String> uomList = [];
  bool isLoadingUom = false;

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
                    Navigator.pop(context);
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
      Navigator.pop(context, true); // return true to refresh list if needed
    } catch (e, stackrace) {
      print(e);
      print(stackrace);
      final error = extractBackendError(e);
      AppToast.error("❌ Failed to update rate:$error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: "Edit Rate"),
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
              button: RoundedButton(
            text: "Save",
            color: colorScheme.primary,
            textColor: colorScheme.onPrimary,
            onPressed: _updateRate,
          ))
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              CustomTextField(
                label: "Product",
                controller: siteNameController,
                isRequired: true,
              ),
              CustomTextField(
                label: "HSN/SAC Code",
                controller: hsnCodeController,
                isRequired: false,
              ),
              CustomTextField(
                label: "Rate in Rs.",
                controller: rateController,
                keyboardType: TextInputType.number,
                isRequired: true,
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
                  : SearchableDropdown(
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
                          right: BorderSide(color: colorScheme.outlineVariant),
                          top: BorderSide(color: colorScheme.outlineVariant),
                          bottom: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
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

              CustomTextField(
                label: "Remark (if any)",
                controller: remarkController,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
