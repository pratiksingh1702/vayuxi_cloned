import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, danger }

class CommonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final bool disabled;

  const CommonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.disabled = false,
  });

  Color _getColor(ColorScheme cs) {
    switch (variant) {
      case ButtonVariant.secondary:
        return cs.secondary;
      case ButtonVariant.danger:
        return cs.error;
      case ButtonVariant.primary:
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getColor(cs),
          foregroundColor: variant == ButtonVariant.danger
              ? cs.onError
              : variant == ButtonVariant.secondary
                  ? cs.onSecondary
                  : cs.onPrimary,
          disabledBackgroundColor: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label),
      ),
    );
  }
}
