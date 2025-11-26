import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../site_Details/repository/siteModel.dart';
import '../data/rate_provider.dart';
import '../domain/rateModel.dart';

class AddRateScreen extends ConsumerStatefulWidget {
  final SiteModel site;
  const AddRateScreen({super.key, required this.site});

  @override
  ConsumerState<AddRateScreen> createState() => _AddRateScreenState();
}

class _AddRateScreenState extends ConsumerState<AddRateScreen> {
  final TextEditingController siteNameController = TextEditingController();
  final TextEditingController hsnCodeController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();

  String? selectedUOM;

  final List<String> uomList = [
    "Inches (in.)",
    "Pieces (pcs.)",
    "Number (nos.)",
    "Kilograms (kgs.)",
  ];

  void _showUOMBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: uomList.length,
          itemBuilder: (context, index) {
            final uom = uomList[index];
            return ListTile(
              title: Text(uom),
              trailing: selectedUOM == uom
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() {
                  selectedUOM = uom;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _saveRate() async {
    if (siteNameController.text.isEmpty ||
        hsnCodeController.text.isEmpty ||
        rateController.text.isEmpty ||
        selectedUOM == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final rateData = {
      "serviceName": siteNameController.text,
      "hsnSacCode": hsnCodeController.text,
      "rate": double.tryParse(rateController.text) ?? 0,
      "uom": selectedUOM,
      "remarks": remarkController.text,
    };

    try {
      final type = ref.read(typeProvider);
      final siteId = widget.site.id;

      if (type != null) {
        await ref.read(rateNotifierProvider.notifier).postRate(rateData, type, siteId);

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
      appBar: AppBar(title: const Text("Add Rate")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(
              label: "Product ",
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
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showUOMBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDFE2E6)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedUOM ?? "Select Unit of Measurement",
                      style: TextStyle(
                        color: selectedUOM == null ? Colors.grey : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            CustomTextField(
              label: "Remark (if any)",
              controller: remarkController,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveRate,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text("Save & Submit"),
            ),
          ],
        ),
      ),
    );
  }
}