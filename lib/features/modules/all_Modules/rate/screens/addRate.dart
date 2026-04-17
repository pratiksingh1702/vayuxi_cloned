import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import '../../../../../core/utlis/common_functions.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../core/utlis/widgets/fields/searchableDropdown.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../../../tour/domain/tour_controller.dart';
import '../../site_Details/repository/siteModel.dart';
import '../data/rateApi.dart';
import '../data/rate_provider.dart';
import '../domain/rateModel.dart';

class AddRateScreen extends ConsumerStatefulWidget {
  const AddRateScreen({super.key});

  @override
  ConsumerState<AddRateScreen> createState() => _AddRateScreenState();
}

class _AddRateScreenState extends ConsumerState<AddRateScreen> {
  final TextEditingController siteNameController = TextEditingController();
  final TextEditingController hsnCodeController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();
  final TextEditingController uomController = TextEditingController();

  final FocusNode uomFocusNode = FocusNode();
  bool isCustomUOM = false;
  bool isloading = false;
  List<String> uomList = [];

  @override
  void initState() {
    super.initState();
    _loadUOM();
  }

  Future<void> _loadUOM() async {
    try {
      final response = await RateApiClient().getRateUOM();

      setState(() {
        uomList =
            response.map<String>((item) => item['name'].toString()).toList();
      });
    } catch (e) {
      print("❌ Failed to load UOM: $e");
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

  Future<void> _saveRate() async {
    setState(() {
      isloading = true;
    });
    if (siteNameController.text.isEmpty ||
        rateController.text.isEmpty ||
        uomController.text.isEmpty) {
      setState(() {
        isloading = false;
      });
      AppToast.error('Please fill all required fields');
      return;
    }

    final rateData = {
      "serviceName": siteNameController.text,
      "hsnSacCode": hsnCodeController.text,
      "rate": double.tryParse(rateController.text) ?? 0,
      "uom": uomController.text, // Use whatever is in the field
      "remarks": remarkController.text,
    };

    try {
      final type = ref.read(typeProvider);
      final siteId = ref.read(selectedSiteIdProvider);

      if (type != null) {
        await ref
            .read(rateNotifierProvider.notifier)
            .postRate(rateData, type, siteId!);

        AppToast.success('Rate saved successfully');
        await ref.read(tourPersistenceProvider).markRateDone();

        // Navigate back after successful save
        if (mounted) {
          context.pop();
          context.push("/site-list/rate");
        }
      }
    } catch (e) {
      print("Error saving rate: $e");
      final error = extractBackendError(e);
      AppToast.error("❌ Failed to save rate:$error");
    } finally {
      setState(() {
        isloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: "Add Rate"),
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
              button: RoundedButton(
            text: isloading ? "Saving..." : "Save",
            color: colorScheme.primary,
            textColor: colorScheme.onPrimary,
            onPressed: _saveRate,
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
                label: "Rate in RS.",
                controller: rateController,
                keyboardType: TextInputType.number,
                isRequired: true,
              ),

              // UOM Section with Label
              // UOM Section
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: "Uom",
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                inputDecoration: InputDecoration(
                  hintText: "Search or type Unit of Measurement",
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
              ),

              // // Combined UOM Field - Can type or select from dropdown
              // TextFormField(
              //   controller: uomController,
              //   focusNode: uomFocusNode,
              //   onChanged: _onUOMChanged,
              //   decoration: InputDecoration(
              //     hintText: "Select or type Unit of Measurement",
              //     hintStyle: TextStyle(color: Colors.grey[500]),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //       borderSide: const BorderSide(color: Color(0xFFDFE2E6)),
              //     ),
              //     enabledBorder: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //       borderSide: const BorderSide(color: Color(0xFFDFE2E6)),
              //     ),
              //     focusedBorder: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(8),
              //       borderSide: const BorderSide(color: Colors.blue),
              //     ),
              //     filled: true,
              //     fillColor: Colors.white,
              //     contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              //     suffixIcon: IconButton(
              //       icon: const Icon(Icons.arrow_drop_down),
              //       onPressed: _showUOMBottomSheet,
              //     ),
              //   ),
              //   style: const TextStyle(fontSize: 16),
              // ),
              //
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
