// lib/widgets/toggle_input_box.dart
import 'package:flutter/material.dart';

class ToggleInputBox extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onToggle;

  const ToggleInputBox({
    super.key,
    required this.label,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isActive ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
        trailing: Switch(
          value: isActive,
          onChanged: (value) => onToggle(),
          activeColor: colorScheme.primary,
          inactiveThumbColor: colorScheme.onSurfaceVariant,
        ),
        onTap: onToggle,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
