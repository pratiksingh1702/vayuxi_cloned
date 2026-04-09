import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;
  final bool isOutlined;
  final double? width; // Optional width parameter

  const RoundedButton({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
    required this.onPressed,
    this.isOutlined = false,
    this.width, // Make width optional
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 48,
      child: isOutlined
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                side: BorderSide(color: color, width: 1.6),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                minimumSize: const Size(90, 48),
              ),
              onPressed: onPressed,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                minimumSize: const Size(90, 48),
              ),
              onPressed: onPressed,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
    );
  }
}
