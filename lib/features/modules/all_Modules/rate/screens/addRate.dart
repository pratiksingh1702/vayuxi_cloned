import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../site_Details/repository/siteModel.dart';
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

  final List<String> uomList = [
    "Inches (in.)",
    "Pieces (pcs.)",
    "Number (nos.)",
    "Kilograms (kgs.)",
  ];

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

  Future<void> _saveRate() async {
    if (siteNameController.text.isEmpty ||
        hsnCodeController.text.isEmpty ||
        rateController.text.isEmpty ||
        uomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final rateData = {
      "serviceName": siteNameController.text,
      "hsnSacCode": hsnCodeController.text,
      "rate": double.tryParse(rateController.text) ?? 0,
      "uom": uomController.text.trim(), // Use whatever is in the field
      "remarks": remarkController.text,
    };

    try {
      final type = ref.read(typeProvider);
      final siteId = ref.read(selectedSiteIdProvider);

      if (type != null) {
        await ref.read(rateNotifierProvider.notifier).postRate(rateData, type, siteId!);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rate saved successfully')),
        );

        // Navigate back after successful save
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print("Error saving rate: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save rate: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "Add Rate"),
      body: SingleChildScrollView(
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
              label: "Rate in RS.",
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
            const SizedBox(height: 20),
            RoundedButton(
              text: "Save",
              color: Colors.blue,
              textColor: Colors.white,
              onPressed: _saveRate,
            )
          ],
        ),
      ),
    );
  }
}