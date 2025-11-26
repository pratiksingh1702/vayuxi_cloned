import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  String? selectedUOM;

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
    selectedUOM = widget.rate.uom;
  }

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
                setState(() => selectedUOM = uom);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _updateRate() async {
    if (siteNameController.text.isEmpty ||
        hsnCodeController.text.isEmpty ||
        rateController.text.isEmpty ||
        selectedUOM == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final updatedData = {
      "serviceName": siteNameController.text,
      "hsnSacCode": hsnCodeController.text,
      "rate": double.tryParse(rateController.text) ?? 0,
      "uom": selectedUOM,
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
      appBar: AppBar(title: const Text("Edit Rate")),
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
              label: "Rate in Rs.",
              controller: rateController,
              keyboardType: TextInputType.number,
              isRequired: true,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showUOMBottomSheet,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
              onPressed: _updateRate,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text("Update Rate"),
            ),
          ],
        ),
      ),
    );
  }
}
