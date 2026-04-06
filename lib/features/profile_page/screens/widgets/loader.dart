// lib/widgets/loader.dart
import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/widgets/shimmer.dart';

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),
            ShimmerCircle(size: 120),
            SizedBox(height: 30),
            ShimmerBox(width: double.infinity, height: 50),
            SizedBox(height: 16),
            ShimmerBox(width: double.infinity, height: 50),
            SizedBox(height: 16),
            ShimmerBox(width: double.infinity, height: 50),
            SizedBox(height: 16),
            ShimmerBox(width: double.infinity, height: 100),
            SizedBox(height: 16),
            ShimmerBox(width: double.infinity, height: 50),
          ],
        ),
      ),
    );
  }
}