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
                  Colors.black.withOpacity(0.36),
                  Colors.black.withOpacity(0.52),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8ECF2), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33111A2E),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                  BoxShadow(
                    color: Color(0x14111A2E),
                    blurRadius: 8,
                    offset: Offset(0, 3),
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
                          color: const Color(0xFFEFF4FF),
                        ),
                        child: const Icon(
                          Icons.language_rounded,
                          size: 28,
                          color: Color(0xFF1F4DA8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Language Setup",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A5568),
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
                      color: const Color(0xFF121826),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Get a personalized experience by selecting and downloading your preferred language pack. English is always available as the default.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF5D6B82),
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
                      color: const Color(0xFFF7FAFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCE8FF)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 18, color: Color(0xFF1F7A45)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Default: English (en-IN)",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2D3A4D),
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
                        backgroundColor: const Color(0xFF1F4DA8),
                        foregroundColor: Colors.white,
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
                        side: const BorderSide(color: Color(0xFFD7DDEA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        foregroundColor: const Color(0xFF1E2A3A),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text("Continue with English"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "You can change language anytime from Settings.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A869A),
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
