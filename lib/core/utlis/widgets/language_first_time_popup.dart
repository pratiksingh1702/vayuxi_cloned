import 'dart:ui';
import 'package:flutter/material.dart';

class LanguageFirstTimePopup extends StatelessWidget {
  final VoidCallback onSelectLanguage;
  final VoidCallback onSkip;

  const LanguageFirstTimePopup({
    super.key,
    required this.onSelectLanguage,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    return Stack(
      children: [
        // Soft dim + blur backdrop keeps context visible without visual noise.
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.scrim.withOpacity(0.36),
                  cs.scrim.withOpacity(0.52),
                ],
              ),
            ),
          ),
        ),

        // Premium white card
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 430),
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 18 : 24,
                vertical: isSmall ? 20 : 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? cs.surfaceContainerHigh : cs.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.outlineVariant, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: cs.primaryContainer,
                        ),
                        child: Icon(
                          Icons.language_rounded,
                          size: 28,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Language Setup",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Choose your app language",
                    style: TextStyle(
                      fontSize: isSmall ? 21 : 24,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Get a personalized experience by selecting and downloading your preferred language pack. English is always available as the default.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 18, color: cs.onTertiaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Default: English (en-IN)",
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onSelectLanguage,
                      icon: const Icon(Icons.translate_rounded, size: 19),
                      label: const Text("Select Language"),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: onSkip,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        foregroundColor: cs.onSurface,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text("Continue with English"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "You can change language anytime from Settings.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
