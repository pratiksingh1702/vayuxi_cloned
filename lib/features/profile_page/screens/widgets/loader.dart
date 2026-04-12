// lib/widgets/loader.dart
import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/widgets/shimmer.dart';

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const ShimmerCircle(size: 120),
            const SizedBox(height: 30),
            _LoaderCard(
                child: const ShimmerBox(width: double.infinity, height: 50)),
            const SizedBox(height: 16),
            _LoaderCard(
                child: const ShimmerBox(width: double.infinity, height: 50)),
            const SizedBox(height: 16),
            _LoaderCard(
                child: const ShimmerBox(width: double.infinity, height: 50)),
            const SizedBox(height: 16),
            _LoaderCard(
                child: const ShimmerBox(width: double.infinity, height: 100)),
            const SizedBox(height: 16),
            _LoaderCard(
                child: const ShimmerBox(width: double.infinity, height: 50)),
          ],
        ),
      ),
    );
  }
}

class _LoaderCard extends StatelessWidget {
  const _LoaderCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: child,
    );
  }
}
