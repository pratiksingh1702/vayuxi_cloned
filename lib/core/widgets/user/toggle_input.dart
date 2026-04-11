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
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? cs.primaryContainer : cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? cs.primary : cs.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: isActive ? cs.primary : cs.onSurface,
                    fontWeight: FontWeight.w600)),
            Icon(
              isActive ? Icons.check_circle : Icons.circle_outlined,
              color: isActive ? cs.primary : cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
