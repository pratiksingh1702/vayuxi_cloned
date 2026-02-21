// screens/lagging_material_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../../core/utlis/widgets/afd.dart';
import '../../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../../core/utlis/widgets/sidebar.dart';
import '../../../salary/screens/salarycat.dart';
import '../model/insu_step_date.dart';

class LaggingMaterialScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String teamId;
  final String siteName;
  final String teamName;
  final int layerIndex;

  const LaggingMaterialScreen({
    Key? key,
    required this.siteId,
    required this.teamId,
    required this.siteName,
    required this.teamName,
    required this.layerIndex,
  }) : super(key: key);

  @override
  ConsumerState<LaggingMaterialScreen> createState() =>
      _LaggingMaterialScreenState();
}

class _LaggingMaterialScreenState
    extends ConsumerState<LaggingMaterialScreen> {
  final TextEditingController _thicknessController = TextEditingController();
  @override
  void initState() {
    super.initState();

    final insulationState = ref.read(insulationStateProvider);
    final layer = insulationState.layers[widget.layerIndex];

    _thicknessController.text =
    layer.thickness == 0 ? '' : layer.thickness.toString();
  }
  @override
  void didUpdateWidget(covariant LaggingMaterialScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.layerIndex != widget.layerIndex) {
      final insulationState = ref.read(insulationStateProvider);
      final layer = insulationState.layers[widget.layerIndex];

      _thicknessController.text =
      layer.thickness == 0 ? '' : layer.thickness.toString();
    }
  }


  final List<Map<String, String>> materials = const [
    {'name': 'Nitrile Rubber', 'image': 'assets/stepper/nitrie.webp'},
    {'name': 'PUF', 'image': 'assets/stepper/puf.webp'},
    {'name': 'LRB', 'image': 'assets/stepper/lrb.webp'},
  ];

  final List<double> thicknessOptions =
  List.generate(15, (i) => (i + 1).toDouble());

  @override
  Widget build(BuildContext context) {
    final insulationState = ref.watch(insulationStateProvider);
    final layer = insulationState.layers[widget.layerIndex];

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: const Color(0xFFD7ECFF),
      appBar: CustomAppBar(
        title: 'Lagging Material ${widget.layerIndex + 1}',
      ),
      body: BottomButtonWrapper(
        customButtons: [

            CustomButton(
              button: RoundedButton(
                text: "Save & Submit",
                color: Colors.blue,
                textColor: Colors.white,
                onPressed: () {
            _next();
                },
              ),
            )
        ],

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skip button row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _next,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
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

              const SizedBox(height: 24),

              /// MATERIAL SELECTION
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: materials.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // ✅ ONLY 2 PER ROW
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final material = materials[index];
                  final isSelected = layer.name == material['name'];

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF007BFF) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: SelectCard(
                      icon: Image.asset(
                        material['image']!,
                        width: 60,
                        height: 60,
                      ),
                      label: material['name']!,
                      onTap: () {
                        ref.read(insulationStateProvider.notifier).updateLayer(
                          index: widget.layerIndex,
                          name: material['name'],
                        );
                      },
                    ),
                  );
                },
              ),


              const SizedBox(height: 32),

              /// THICKNESS
              const Text(
                'Thickness (mm)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              _thicknessInput(layer.thickness),


              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

  }

  /// ----------------------------
  /// HELPERS
  /// ----------------------------

  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Lagging Material - ${widget.layerIndex + 1}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          onPressed: _skip,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF007BFF),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Skip',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _thicknessInput(double selectedThickness) {


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _thicknessController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "Enter thickness (mm)",
        ),
       onChanged: (value) {
            final thickness = double.tryParse(value.trim()) ?? 0;

            ref.read(insulationStateProvider.notifier).updateLayer(
              index: widget.layerIndex,
              thickness: thickness,
            );
          },

      ),
    );
  }


  Widget _materialCard({
    required String name,
    required String image,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF007BFF) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(image, width: 60, height: 60),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF007BFF)
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    final insulationState = ref.read(insulationStateProvider);
    final layer = insulationState.layers[widget.layerIndex];

    if (layer.name.isEmpty || layer.thickness == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select material and thickness'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    /// ✅ SAVE TO LAGGING PROVIDER
    ref.read(laggingMaterialProvider.notifier).add(
      LaggingMaterial(
        id: 'layer_${widget.layerIndex}',
        name: layer.name,
        thickness: layer.thickness,
        uom: 'mm',
      ),
    );

    /// 🔁 NAVIGATION
    if (widget.layerIndex < insulationState.layers.length - 1) {
      context.pushNamed(
        'lagging-material',
        extra: {
          'siteId': widget.siteId,
          'teamId': widget.teamId,
          'siteName': widget.siteName,
          'teamName': widget.teamName,
          'layerIndex': widget.layerIndex + 1,
        },
      );
    } else {
      context.pushNamed(
        'cladding',
        extra: {
          'siteId': widget.siteId,
          'teamId': widget.teamId,
          'siteName': widget.siteName,
          'teamName': widget.teamName,
        },
      );
    }
  }

  void _skip() {
    ref
        .read(laggingMaterialProvider.notifier)
        .delete('layer_${widget.layerIndex}');

    final state = ref.read(insulationStateProvider);

    if (widget.layerIndex < state.layers.length - 1) {
      context.pushReplacementNamed(
        'lagging-material',
        extra: {
          'siteId': widget.siteId,
          'teamId': widget.teamId,
          'siteName': widget.siteName,
          'teamName': widget.teamName,
          'layerIndex': widget.layerIndex + 1,
        },
      );
    } else {
      context.pushNamed(
        'cladding',
        extra: {
          'siteId': widget.siteId,
          'teamId': widget.teamId,
          'siteName': widget.siteName,
          'teamName': widget.teamName,
        },
      );
    }
  }
  @override
  void dispose() {
    _thicknessController.dispose();
    super.dispose();
  }

}
