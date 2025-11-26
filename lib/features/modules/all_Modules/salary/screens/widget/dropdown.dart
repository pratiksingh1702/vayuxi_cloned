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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          hint: Text(placeholder),
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