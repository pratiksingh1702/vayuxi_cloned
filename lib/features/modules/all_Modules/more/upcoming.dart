import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class Updates extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large SVG in center
            Container(
              width: 250,
              height: 250,
              child: SvgPicture.asset(
                'assets/images/updates.webp', // Replace with your SVG path
                fit: BoxFit.contain,
              ),
            ),

            SizedBox(height: 40),

            // Optional text below SVG
            Text(
              'Your App Name',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 10),

            Text(
              'Beautiful centered SVG design',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}