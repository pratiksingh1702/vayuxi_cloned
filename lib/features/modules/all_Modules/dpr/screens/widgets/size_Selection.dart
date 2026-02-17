// pages/size_selection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../../../../core/utlis/widgets/fields/custom_textField.dart';
import '../../../../../language/service/providers.dart';
import '../../dpr_insu/screens/testing.dart';
import '../../providers/selectedSize_provider.dart';
import '../add_description.dart';

class SizeSelectionPage extends ConsumerWidget {
  const SizeSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSize = ref.watch(selectedSizeProvider);
    final TextEditingController sizeController = TextEditingController(
      text: selectedSize ?? '',
    );
    final lang=ref.watch(dailyEntryTranslationHelperProvider);

    return Scaffold(
      appBar: CustomAppBar(title: lang.enterSizeTitle),
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
            button: RoundedButton(
              text: 'Save',
              color: Colors.blue,
              textColor: Colors.white,
              onPressed: () {
                if (sizeController.text.trim().isNotEmpty) {
                  ref.read(selectedSizeProvider.notifier).state = sizeController
                      .text
                      .trim();
                  final type=ref.read(typeProvider);
                  if (type=="mechanical_work"){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddDescriptionScreen(),
                      ),
                    );}else{
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddInsulationDescriptionScreen(),
                      ),
                    );


                  }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Size "${sizeController.text.trim()}" saved!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );


                  // Optional: Navigate back
                  // Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a size'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Size input field
              CustomTextField(
                label: lang.sizeTab,
                TextSize: 20,
                hint: 'Enter size (e.g., 10, M, XL, 42, etc.)',
                controller: sizeController,
                keyboardType: TextInputType.text,
                isRequired: true,
                prefixIcon: const Icon(Icons.straighten, color: Colors.grey),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a size';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Display selected size
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
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Selected Size: $selectedSize',
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

              // Save button
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     onPressed: () {
              //       if (sizeController.text.trim().isNotEmpty) {
              //         ref.read(selectedSizeProvider.notifier).state =
              //             sizeController.text.trim();
              //         Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //             builder: (context) => AddDescriptionScreen(
              //                   ),
              //           ),
              //         );
              //
              //         ScaffoldMessenger.of(context).showSnackBar(
              //           SnackBar(
              //             content: Text('Size "${sizeController.text.trim()}" saved!'),
              //             backgroundColor: Colors.green,
              //           ),
              //         );
              //
              //         // Optional: Navigate back
              //         // Navigator.pop(context);
              //       } else {
              //         ScaffoldMessenger.of(context).showSnackBar(
              //           const SnackBar(
              //             content: Text('Please enter a size'),
              //             backgroundColor: Colors.red,
              //           ),
              //         );
              //       }
              //     },
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.blue,
              //       foregroundColor: Colors.white,
              //       padding: const EdgeInsets.symmetric(vertical: 16),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //     ),
              //     child: const Text(
              //       'Save Size',
              //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
