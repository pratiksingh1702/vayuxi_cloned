import 'package:flutter/material.dart';

class CustomDropdownField<T> extends StatelessWidget {
  final String label;
  final bool isRequired;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;

  /// Add this new parameter
  final List<Widget> Function(BuildContext)? selectedItemBuilder;

  const CustomDropdownField({
    super.key,
    required this.label,
    this.isRequired = false,
    this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.selectedItemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: cs.error),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: DropdownButtonFormField<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              selectedItemBuilder: selectedItemBuilder,
              decoration: InputDecoration(
                hintText: hint ?? 'Select',
                border: InputBorder.none,
              ),
              validator: (v) =>
                  isRequired && v == null ? 'Please select $label' : null,
            ),
          ),
        ],
      ),
    );
  }
}
