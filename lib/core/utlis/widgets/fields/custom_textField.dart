import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool isRequired;
  final int maxLines;
  final double? TextSize;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final FocusNode? focusNode;

  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.focusNode,
    this.isRequired = false,
    this.maxLines = 1,
    this.controller,
    this.TextSize = 14,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.validator,
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
                fontSize: TextSize,
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
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: hint ?? 'Enter $label',
              hintStyle: TextStyle(
                color: cs.onSurfaceVariant,
              ),
              filled: true,
              fillColor: cs.surface,
              prefixIcon: prefixIcon,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cs.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: cs.primary),
              ),
            ),
            validator: (value) {
              // required validation
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return 'This field is required';
              }

              // user custom validation
              if (validator != null) {
                return validator!(value);
              }

              return null;
            },
          ),
        ],
      ),
    );
  }
}
