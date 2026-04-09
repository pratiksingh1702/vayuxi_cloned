import 'dart:ui';

import 'package:flutter/material.dart';

import '../colors/colors.dart';

class CornerClippedScreenSimple extends StatelessWidget {
  final Widget child;

  final double cornerRadius;

  final Color color;

  const CornerClippedScreenSimple({
    Key? key,
    required this.child,
    this.color = AppColors.lightBlue,

    this.cornerRadius = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(Theme.of(context).scaffoldBackgroundColor);
    print("color at clipped 😑😑😑");
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            "assets/images/Gemini_Generated_Image_pi2r7npi2r7npi2r.webp",
            fit: BoxFit.cover,
          ),
        ),

        // Clipped Content using Container with BorderRadius
        Positioned.fill(
          child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: Container(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    // color: Theme.of(context).scaffoldBackgroundColor,
                    color: color,


                  ),

                  child: child)),
        ),
      ],
    );
  }
}