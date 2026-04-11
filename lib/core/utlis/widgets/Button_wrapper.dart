import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/language/service/providers.dart';
import 'buttons.dart';

class BottomButtonWrapper extends ConsumerWidget {
  final Widget child;
  final List<CustomButton> customButtons;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const BottomButtonWrapper({
    super.key,
    required this.child,
    this.customButtons = const [],
    this.showBackButton = true,
    this.onBackPressed,
    this.padding = const EdgeInsets.all(16.0),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CornerClippedScreenSimple(
      child: Column(
        children: [
          /// Main content
          Expanded(child: child),

          /// Bottom buttons
          Container(
            padding: padding,
            color: backgroundColor,
            child: SafeArea(
              top: false,
              child: Row(
                children: _buildButtons(context, ref),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildButtons(BuildContext context, WidgetRef ref) {
    final List<Widget> buttons = [];
    final t = ref.read(dailyEntryTranslationHelperProvider);
    final cs = Theme.of(context).colorScheme;

    if (showBackButton) {
      buttons.add(
        RoundedButton(
          text: t.backButton,
          color: cs.surfaceContainerHighest,
          textColor: cs.onSurface,
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
          isOutlined: true,
        ),
      );
    }

    for (final button in customButtons) {
      buttons.add(button.button);
    }

    if (buttons.length == 1) {
      return [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: buttons.first,
          ),
        ),
      ];
    }

    return buttons
        .map(
          (button) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: button,
            ),
          ),
        )
        .toList();
  }
}

class CustomButton {
  final Widget button;
  const CustomButton({required this.button});
}
