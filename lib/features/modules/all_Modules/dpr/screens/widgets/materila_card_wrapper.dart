import 'package:flutter/material.dart';

class MaterialCardWrapper extends StatelessWidget {
  final bool isUpdating;
  final Widget child;

  const MaterialCardWrapper({
    required this.isUpdating,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isUpdating)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}