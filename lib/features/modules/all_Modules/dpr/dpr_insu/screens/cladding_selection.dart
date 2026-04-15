// screens/cladding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../../core/utlis/widgets/afd.dart';
import '../../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../../core/utlis/widgets/sidebar.dart';
import '../../../salary/screens/salarycat.dart';
import '../../screens/widgets/size_Selection.dart';
import '../model/insu_step_date.dart';

class CladdingScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String teamId;
  final String siteName;
  final String teamName;

  const CladdingScreen({
    Key? key,
    required this.siteId,
    required this.teamId,
    required this.siteName,
    required this.teamName,
  }) : super(key: key);

  static const List<Map<String, String>> materials = [
    {'name': 'SS Sheet', 'image': 'assets/stepper/ss.webp'},
    {'name': 'Aluminium Sheet', 'image': 'assets/stepper/ss.webp'},
  ];

  @override
  ConsumerState<CladdingScreen> createState() => _CladdingScreenState();
}

class _CladdingScreenState extends ConsumerState<CladdingScreen> {
  final TextEditingController _thicknessController = TextEditingController();
  @override
  void initState() {
    super.initState();

    final cladding = ref.read(insulationStateProvider).cladding;

    _thicknessController.text =
        cladding.thickness == 0 ? '' : cladding.thickness.toString();
  }

  @override
  void dispose() {
    _thicknessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cladding = ref.watch(insulationStateProvider).cladding;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surface,
      appBar: const CustomAppBar(
        title: 'Cladding',
      ),
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
            button: RoundedButton(
              text: "Save & Submit",
              color: colorScheme.primary,
              textColor: colorScheme.onPrimary,
              onPressed: () {
                _submit(context);
              },
            ),
          )
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skip button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _submit(context),
                    style: TextButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.55)),
                ),
                child: Text(
                  'Set up cladding material and configuration.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// MATERIAL SELECTION
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: CladdingScreen.materials.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final material = CladdingScreen.materials[index];
                  final isSelected = cladding.name == material['name'];

                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withOpacity(0.5),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SelectCard(
                      icon: Image.asset(
                        material['image']!,
                        width: 60,
                        height: 60,
                      ),
                      label: material['name']!,
                      onTap: () {
                        ref
                            .read(insulationStateProvider.notifier)
                            .setCladding(name: material['name']);
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              /// THICKNESS
              Text(
                'Thickness (SWG)',
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              _thicknessInput(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thicknessInput() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
          controller: _thicknessController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: colorScheme.onSurface),
          cursorColor: colorScheme.primary,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Enter thickness (SWG)",
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          onChanged: (value) {
            final thickness = double.tryParse(value.trim()) ?? 0;

            ref.read(insulationStateProvider.notifier).setCladding(
                  thickness: thickness,
                );
          }),
    );
  }

  void _submit(BuildContext context) {
    final cladding = ref.read(insulationStateProvider).cladding;
    final thickness = double.tryParse(_thicknessController.text.trim()) ?? 0;

    ref.read(insulationStateProvider.notifier).setCladding(
          thickness: thickness,
        );

    // if (cladding.name.isEmpty || cladding.thickness == 0) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Select cladding material and thickness'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    //   return;
    // }

    final payload = ref.read(insulationStateProvider).toJson();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SizeSelectionPage(),
      ),
    );
  }
}
