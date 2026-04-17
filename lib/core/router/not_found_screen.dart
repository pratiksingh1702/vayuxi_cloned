import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Page not found',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go(Routes.workCategory),
                child: const Text('Go to Work Categories'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
