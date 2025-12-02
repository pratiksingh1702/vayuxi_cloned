import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'buttons.dart';

class BottomButtonWrapper extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return  CornerClippedScreenSimple(
      child: Column(
          children: [
            // Main content scrolls above the buttons
            Expanded(child: child),
      
            // Bottom buttons
            Container(
              padding: padding,
              child: SafeArea(
                top: false,
                child: Row(
                  children: _buildButtons(context),
                ),
              ),
            ),
          ],
        ),
    );
  }

  List<Widget> _buildButtons(BuildContext context) {
    final List<Widget> buttons = [];

    // Add back button if needed
    if (showBackButton) {
      buttons.add(
        RoundedButton(
          text: 'Back',
          color: Colors.grey.shade300,
          textColor: Colors.black,
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
          isOutlined: true,
        ),
      );
    }

    // Add custom buttons
    for (final button in customButtons) {
      buttons.add(button.button);
    }

    // If only one button, it takes full width
    if (buttons.length == 1) {
      return [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: buttons.first,
          ),
        ),
      ];
    }

    // If multiple buttons, distribute equally with Expanded
    return buttons
        .map((button) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: button,
      ),
    ))
        .toList();
  }
}

class CustomButton {
  final RoundedButton button;
  const CustomButton({required this.button});
}