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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showMenu)
          IconButton(
            icon: const Icon(Icons.menu),
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