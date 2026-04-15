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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surface,
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
                  'Choose layer configuration for this setup.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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

  Widget layerIcon(int layers,
      {required bool isSelected, required ColorScheme colorScheme}) {
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
                ? colorScheme.onPrimary
                : (i == 0
                    ? colorScheme.tertiary
                    : i == 1
                        ? colorScheme.secondary
                        : colorScheme.primary.withOpacity(0.8)),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withOpacity(0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            layerIcon(
              _layerCount(type),
              isSelected: isSelected,
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tap to configure',
                    style: textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimary.withOpacity(0.86)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
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
