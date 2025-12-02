import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../site_Details/repository/siteModel.dart';
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

  final List<String> uomList = [
    "Inches (in.)",
    "Pieces (pcs.)",
    "Number (nos.)",
    "Kilograms (kgs.)",
  ];

  @override
  void initState() {
    super.initState();
    // Prefill fields with existing data
    siteNameController = TextEditingController(text: widget.rate.serviceName);
    hsnCodeController = TextEditingController(text: widget.rate.hsnSacCode);
    rateController = TextEditingController(text: widget.rate.rate.toString());
    remarkController = TextEditingController(text: widget.rate.remarks ?? "");
    uomController = TextEditingController(text: widget.rate.uom);

    // Check if the existing UOM is custom
    final existingUOM = widget.rate.uom;
    isCustomUOM = !uomList.contains(existingUOM);
  }

  void _showUOMBottomSheet() {
    // If user is typing custom UOM, don't show bottom sheet
    if (isCustomUOM) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
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
                  color: Colors.grey[700],
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
                      ? const Icon(Icons.check, color: Colors.blue)
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
        hsnCodeController.text.isEmpty ||
        rateController.text.isEmpty ||
        uomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rate updated successfully')),
      );

      Navigator.pop(context, true); // return true to refresh list if needed
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update rate: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Edit Rate"),
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
              button: RoundedButton(
                text: "Save & Submit",
                color: Colors.blue,
                textColor: Colors.white,
                onPressed: _updateRate,
              )
          )
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
                isRequired: true,
              ),
              CustomTextField(
                label: "Rate in Rs.",
                controller: rateController,
                keyboardType: TextInputType.number,
                isRequired: true,
              ),

              // UOM Section with Label
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "UOM",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Combined UOM Field - Can type or select from dropdown
              TextFormField(
                controller: uomController,
                focusNode: uomFocusNode,
                onChanged: _onUOMChanged,
                decoration: InputDecoration(
                  hintText: "Select or type Unit of Measurement",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFDFE2E6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFDFE2E6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_drop_down),
                    onPressed: _showUOMBottomSheet,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
              ),

              // Show indicator if using custom UOM
              if (isCustomUOM && uomController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 14, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(
                        "Using custom UOM",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
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