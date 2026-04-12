// lib/widgets/address_input.dart
import 'package:flutter/material.dart';

class AddressInput extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final int maxLines;

  const AddressInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder = 'Address',
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      initialValue: value,
      maxLines: maxLines,
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
      ),
      onChanged: onChanged,
    );
  }
}
