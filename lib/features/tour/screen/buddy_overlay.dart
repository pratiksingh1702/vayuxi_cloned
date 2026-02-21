import 'package:flutter/material.dart';

class BuddyOverlay extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onHide;
  const BuddyOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.onNext,
    required this.onSkip,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: onSkip,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text(
              "Skip",
              style: TextStyle(
                color: Colors.white,
                fontSize:15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
