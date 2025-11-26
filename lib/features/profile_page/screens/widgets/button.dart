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
    if (disabled) return Colors.grey;

    switch (variant) {
      case ButtonVariant.primary:
        return Theme.of(context).primaryColor;
      case ButtonVariant.secondary:
        return Colors.transparent;
      case ButtonVariant.danger:
        return Colors.red;
    }
  }

  Color _getTextColor(BuildContext context) {
    if (disabled) return Colors.grey;

    switch (variant) {
      case ButtonVariant.primary:
        return Colors.white;
      case ButtonVariant.secondary:
        return Theme.of(context).primaryColor;
      case ButtonVariant.danger:
        return Colors.white;
    }
  }

  Color _getBorderColor(BuildContext context) {
    if (disabled) return Colors.grey;

    switch (variant) {
      case ButtonVariant.primary:
        return Theme.of(context).primaryColor;
      case ButtonVariant.secondary:
        return Theme.of(context).primaryColor;
      case ButtonVariant.danger:
        return Colors.red;
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
          side: variant == ButtonVariant.secondary
              ? BorderSide(color: _getBorderColor(context))
              : null,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: loading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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