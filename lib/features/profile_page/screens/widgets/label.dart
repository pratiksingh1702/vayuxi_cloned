// lib/widgets/label.dart
import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  final String text;
  final bool required;

  const Label({
    super.key,
    required this.text,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          if (required)
            Text(
              ' *',
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
