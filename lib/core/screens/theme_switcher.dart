import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/modules/all_Modules/more/theme/provider/theme_controller.dart';

class BeautifulThemeSwitcher extends ConsumerWidget {
  const BeautifulThemeSwitcher({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeState = ref.watch(themeProvider);

    final isDark = switch (themeState.themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => Theme.of(context).brightness == Brightness.dark,
    };

    final width = compact ? 78.0 : 108.0;
    final height = compact ? 34.0 : 40.0;
    final thumbSize = compact ? 28.0 : 34.0;

    return GestureDetector(
      onTap: () {
        ref
            .read(themeProvider.notifier)
            .changeMode(isDark ? ThemeMode.light : ThemeMode.dark);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF10213A),
                    const Color(0xFF060B16),
                  ]
                : [
                    const Color(0xFFFFE9A9),
                    const Color(0xFFFFC66B),
                  ],
          ),
          border: Border.all(
            color: isDark
                ? colorScheme.outline.withOpacity(0.45)
                : const Color(0xFFFFB24B),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(isDark ? 0.32 : 0.16),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: compact ? 8 : 10,
              child: Icon(
                Icons.wb_sunny_rounded,
                size: compact ? 16 : 18,
                color: isDark ? Colors.white54 : const Color(0xFF9C5B00),
              ),
            ),
            Positioned(
              right: compact ? 8 : 10,
              child: Icon(
                Icons.nights_stay_rounded,
                size: compact ? 14 : 16,
                color: isDark ? const Color(0xFFA2C7FF) : Colors.white70,
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF98BFFF),
                            const Color(0xFF5C8FE4),
                          ]
                        : [
                            Colors.white,
                            const Color(0xFFFFF7D6),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: compact ? 15 : 18,
                  color: isDark
                      ? const Color(0xFF0D2B63)
                      : const Color(0xFFF39C12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BeautifulLogoutButton extends StatelessWidget {
  const BeautifulLogoutButton({
    super.key,
    required this.onPressed,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = compact ? 34.0 : 40.0;

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE1DF),
              Color(0xFFFFC2BC),
            ],
          ),
          border: Border.all(color: const Color(0xFFE88E85)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.14),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.logout_rounded,
              size: 16,
              color: Color(0xFF9C1D14),
            ),
          ],
        ),
      ),
    );
  }
}
