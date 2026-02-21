import 'package:flutter/material.dart';
class SelectionCheck extends StatelessWidget {


  final bool selected;
  final VoidCallback onTap;

  const SelectionCheck({
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          backgroundColor: selected ? Colors.red : Colors.white,
          child: selected
              ? const Icon(Icons.check, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
