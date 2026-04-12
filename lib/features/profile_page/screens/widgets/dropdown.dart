// lib/widgets/dropdown.dart
import 'package:flutter/material.dart';

class Dropdown extends StatelessWidget {
  final List<String> options;
  final String? value;
  final Function(String) onSelect;
  final String? hintText;

  const Dropdown({
    super.key,
    required this.options,
    this.value,
    required this.onSelect,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      hint: hintText != null
          ? Text(hintText!,
              style: TextStyle(color: colorScheme.onSurfaceVariant))
          : null,
      items: options.map((String option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          onSelect(newValue);
        }
      },
    );
  }
}
