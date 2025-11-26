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
    return TextFormField(
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      onChanged: onChanged,
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
    );
  }
}