// lib/widgets/dynamic_header.dart
import 'package:flutter/material.dart';

class DynamicHeader extends StatelessWidget {
  final String name;
  final bool showMenu;

  const DynamicHeader({
    super.key,
    required this.name,
    this.showMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        Text(
          name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        if (showMenu)
          IconButton(
            icon: Icon(Icons.menu, color: colorScheme.onSurface),
            onPressed: () {
              // Handle menu press
            },
          )
        else
          const SizedBox(width: 48), // For balanced spacing
      ],
    );
  }
}
