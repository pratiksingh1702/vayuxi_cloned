// pages/size_selection_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../language/service/providers.dart';
import '../../providers/selectedSize_provider.dart';
import '../add_description.dart';
import '../../dpr_insu/screens/testing.dart';

class SizeSelectionPage extends ConsumerStatefulWidget {
  const SizeSelectionPage({super.key});

  @override
  ConsumerState<SizeSelectionPage> createState() =>
      _SizeSelectionPageState();
}

class _SizeSelectionPageState
    extends ConsumerState<SizeSelectionPage> {

  late TextEditingController sizeController;

  @override
  void initState() {
    super.initState();

    // Initialize controller ONCE
    final selectedSize = ref.read(selectedSizeProvider);
    sizeController = TextEditingController(text: selectedSize ?? '');
  }

  @override
  void dispose() {
    sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSize = ref.watch(selectedSizeProvider);
    final selectedUnit = ref.watch(selectedUnitProvider);
    final lang = ref.watch(dailyEntryTranslationHelperProvider);

    return Scaffold(
      appBar: CustomAppBar(title: lang.enterSizeTitle),
      drawer: CustomDrawer(),
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
            button: RoundedButton(
              text: 'Save',
              color: Colors.blue,
              textColor: Colors.white,
              onPressed: () {
                final value = sizeController.text.trim();

                if (value.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a size'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Save size to provider
                ref.read(selectedSizeProvider.notifier).state = value;

                final type = ref.read(typeProvider);

                if (type == "mechanical_work") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddDescriptionScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddInsulationDescriptionScreen(),
                    ),
                  );
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Size "$value" saved!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [

              /// Title + Unit Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Text(
                        "Size",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        " *",
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),

                  /// UOM Dropdown
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border:
                      Border.all(color: const Color(0xFFDFE2E6)),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedUnit,
                        items: const [
                          DropdownMenuItem(
                            value: 'mm',
                            child: Text('mm'),
                          ),
                          DropdownMenuItem(
                            value: 'inch',
                            child: Text('inch'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            // Changing UOM will NOT reset size anymore
                            ref
                                .read(selectedUnitProvider.notifier)
                                .state = value;
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// Size Input
              CustomTextField(
                label: '',
                hint: 'Enter size (e.g., 10, 42, etc.)',
                controller: sizeController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(
                  Icons.straighten,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 20),

              /// Display Saved Size
              if (selectedSize != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Selected Size: $selectedSize $selectedUnit',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}