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
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        child,
        if (isUpdating)
          Positioned.fill(
            child: Container(
              color: colorScheme.scrim.withOpacity(0.45),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}