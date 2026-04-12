// lib/widgets/input_field.dart
import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String placeholder;
  final String value;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final String? errorText;

  const InputField({
    super.key,
    required this.placeholder,
    required this.value,
    required this.onChanged,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: colorScheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        errorText: errorText,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}
