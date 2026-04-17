import 'package:flutter/material.dart';

class Dropdown extends StatelessWidget {
  final List<String> options;
  final String? value;
  final Function(String) onSelect;
  final String placeholder;

  const Dropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onSelect,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          hint: Text(
            placeholder,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
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
        ),
      ),
    );
  }
}
