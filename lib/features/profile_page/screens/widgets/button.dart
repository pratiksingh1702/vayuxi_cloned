// lib/widgets/button.dart
import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, danger }

class Button extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final bool disabled;
  final bool loading;

  const Button({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.disabled = false,
    this.loading = false,
  });

  Color _getBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (disabled) return colorScheme.surfaceContainerHighest;

    switch (variant) {
      case ButtonVariant.primary:
        return colorScheme.primary;
      case ButtonVariant.secondary:
        return Colors.transparent;
      case ButtonVariant.danger:
        return colorScheme.error;
    }
  }

  Color _getTextColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (disabled) return colorScheme.onSurfaceVariant;

    switch (variant) {
      case ButtonVariant.primary:
        return colorScheme.onPrimary;
      case ButtonVariant.secondary:
        return colorScheme.primary;
      case ButtonVariant.danger:
        return colorScheme.onError;
    }
  }

  Color _getBorderColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (disabled) return colorScheme.outlineVariant;

    switch (variant) {
      case ButtonVariant.primary:
        return colorScheme.primary;
      case ButtonVariant.secondary:
        return colorScheme.primary;
      case ButtonVariant.danger:
        return colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: disabled || loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(context),
          foregroundColor: _getTextColor(context),
          elevation: variant == ButtonVariant.secondary ? 0 : 1,
          side: variant == ButtonVariant.secondary
              ? BorderSide(color: _getBorderColor(context))
              : null,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_getTextColor(context)),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: _getTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
