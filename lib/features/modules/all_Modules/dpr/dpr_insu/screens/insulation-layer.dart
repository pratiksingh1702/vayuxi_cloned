// screens/layer_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../../core/utlis/widgets/afd.dart';
import '../../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../../core/utlis/widgets/sidebar.dart';
import '../model/insu_step_date.dart'; // contains providers + enums

class LayerSelectionScreen extends ConsumerWidget {
  final String siteId;
  final String teamId;
  final String siteName;
  final String teamName;

  const LayerSelectionScreen({
    Key? key,
    required this.siteId,
    required this.teamId,
    required this.siteName,
    required this.teamName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(insulationStateProvider).layerType;

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: const Color(0xFFD7ECFF),
      appBar: const CustomAppBar(
        title: 'Select Layer Type',
      ),
      body: BottomButtonWrapper(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skip button row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      context.pushNamed(
                        'cladding',
                        extra: _navArgs(),
                      );
                    },
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

              const SizedBox(height: 32),

              _layerOption(
                context: context,
                ref: ref,
                label: 'Single Layer',
                type: LayerType.single,
                selectedType: selectedType,
              ),
              const SizedBox(height: 16),

              _layerOption(
                context: context,
                ref: ref,
                label: 'Double Layer',
                type: LayerType.double,
                selectedType: selectedType,
              ),
              const SizedBox(height: 16),

              _layerOption(
                context: context,
                ref: ref,
                label: 'Triple Layer',
                type: LayerType.triple,
                selectedType: selectedType,
              ),
            ],
          ),
        ),
      ),
    );

  }
  Widget layerIcon(int layers, {required bool isSelected}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        layers,
            (i) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          height: 10,
          width: 60,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : Colors.amber[700 - i * 100],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }


  Widget _layerOption({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required LayerType type,
    required LayerType? selectedType,
  }) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: () {
        // ✅ correct enum usage
        ref.read(insulationStateProvider.notifier).setLayerType(type);
        context.pushNamed(
          'lagging-material',
          extra: {
            ..._navArgs(),
            'layerIndex': 0,
          },
        );

      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007BFF) : Colors.white,
          borderRadius: BorderRadius.circular(12),

        ),
        child: Row(
          children: [
            layerIcon(
              _layerCount(type),
              isSelected: isSelected,
            ),

            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
  int _layerCount(LayerType type) {
    switch (type) {
      case LayerType.single:
        return 1;
      case LayerType.double:
        return 2;
      case LayerType.triple:
        return 3;
    }
  }


  Map<String, String> _navArgs() {
    return {
      'siteId': siteId,
      'teamId': teamId,
      'siteName': siteName,
      'teamName': teamName,
    };
  }
}
