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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isActive ? Colors.blue : Colors.black87,
          ),
        ),
        trailing: Switch(
          value: isActive,
          onChanged: (value) => onToggle(),
          activeColor: Colors.blue,
        ),
        onTap: onToggle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}