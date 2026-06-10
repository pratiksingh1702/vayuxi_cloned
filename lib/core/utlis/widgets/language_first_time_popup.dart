import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageFirstTimePopup extends StatefulWidget {
  final FutureOr<void> Function() onSelectLanguage;
  final FutureOr<void> Function() onSkip;
  final FutureOr<void> Function() onStartTour;
  final FutureOr<void> Function() onSkipTour;

  const LanguageFirstTimePopup({
    super.key,
    required this.onSelectLanguage,
    required this.onSkip,
    required this.onStartTour,
    required this.onSkipTour,
  });

  @override
  State<LanguageFirstTimePopup> createState() => _LanguageFirstTimePopupState();
}

class _LanguageFirstTimePopupState extends State<LanguageFirstTimePopup> {
  bool _showTourIntro = false;
  bool _busy = false;
  int _activePanel = 0;

  TextStyle _font({
    double? size,
    FontWeight? weight,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      decoration: TextDecoration.none,
    );
  }

  Future<void> _afterLanguageChoice(FutureOr<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _showTourIntro = true;
        _activePanel = 1;
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      rethrow;
    }
  }

  Future<void> _finishIntro(FutureOr<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 360;

    return Stack(
      children: [
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
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: _PopupShell(
              isDark: isDark,
              cs: cs,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  final keyText = child.key.toString();
                  final isIntro = keyText.contains('tour-intro');
                  final incomingOffset =
                      isIntro ? const Offset(1, 0) : const Offset(-1, 0);
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );

                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: incomingOffset,
                        end: Offset.zero,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
                child: _showTourIntro
                    ? _TourIntroBody(
                        key: ValueKey('tour-intro-$_activePanel'),
                        cs: cs,
                        isSmall: isSmall,
                        busy: _busy,
                        font: _font,
                        onStart: () => _finishIntro(widget.onStartTour),
                        onSkip: () => _finishIntro(widget.onSkipTour),
                      )
                    : _LanguageBody(
                        key: ValueKey('language-$_activePanel'),
                        cs: cs,
                        isSmall: isSmall,
                        busy: _busy,
                        font: _font,
                        onSelectLanguage: () =>
                            _afterLanguageChoice(widget.onSelectLanguage),
                        onContinueEnglish: () =>
                            _afterLanguageChoice(widget.onSkip),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PopupShell extends StatelessWidget {
  final bool isDark;
  final ColorScheme cs;
  final Widget child;

  const _PopupShell({
    super.key,
    required this.isDark,
    required this.cs,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height - 40;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: 430,
        maxHeight: maxHeight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: child,
      ),
    );
  }
}

class _LanguageBody extends StatelessWidget {
  final ColorScheme cs;
  final bool isSmall;
  final bool busy;
  final TextStyle Function({
    double? size,
    FontWeight? weight,
    Color? color,
    double? height,
  }) font;
  final VoidCallback onSelectLanguage;
  final VoidCallback onContinueEnglish;

  const _LanguageBody({
    super.key,
    required this.cs,
    required this.isSmall,
    required this.busy,
    required this.font,
    required this.onSelectLanguage,
    required this.onContinueEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                'Language Setup',
                style: font(
                  size: 15,
                  weight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Choose your app language',
          style: font(
            size: isSmall ? 21 : 24,
            height: 1.2,
            weight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Get a personalized experience by selecting and downloading your preferred language pack. English is always available as the default.',
          style: font(
            size: 14,
            height: 1.5,
            weight: FontWeight.w400,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cs.tertiaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: cs.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Default: English (en-IN)',
                  style: font(
                    size: 13,
                    weight: FontWeight.w600,
                    color: cs.onTertiaryContainer,
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
            onPressed: busy ? null : onSelectLanguage,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.translate_rounded, size: 19),
            label: Text('Select Language', style: font(weight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              disabledBackgroundColor: cs.primary.withOpacity(0.45),
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
            onPressed: busy ? null : onContinueEnglish,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              foregroundColor: cs.onSurface,
            ),
            child: Text(
              'Continue with English',
              style: font(size: 14, weight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'You can change language anytime from Settings.',
            textAlign: TextAlign.center,
            style: font(
              size: 12,
              weight: FontWeight.w400,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _TourIntroBody extends StatelessWidget {
  final ColorScheme cs;
  final bool isSmall;
  final bool busy;
  final TextStyle Function({
    double? size,
    FontWeight? weight,
    Color? color,
    double? height,
  }) font;
  final VoidCallback onStart;
  final VoidCallback onSkip;

  const _TourIntroBody({
    super.key,
    required this.cs,
    required this.isSmall,
    required this.busy,
    required this.font,
    required this.onStart,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * 44, 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: busy ? null : onSkip,
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurface,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: font(size: 12, weight: FontWeight.w600),
              ),
              child: const Text('Skip Tour'),
            ),
            const SizedBox(width: 4),
            IconButton.filledTonal(
              onPressed: busy ? null : onSkip,
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: 'Skip tour',
              style: IconButton.styleFrom(
                backgroundColor: cs.primary.withOpacity(0.1),
                foregroundColor: cs.primary,
                minimumSize: const Size(34, 34),
                fixedSize: const Size(34, 34),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _ErpPreviewArt(cs: cs),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _IntroDot(active: true, color: cs.primary),
            const SizedBox(width: 7),
            _IntroDot(active: false, color: cs.primary),
            const SizedBox(width: 7),
            _IntroDot(active: false, color: cs.primary),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Welcome to Your',
          textAlign: TextAlign.center,
          style: font(
            size: isSmall ? 20 : 22,
            height: 1.15,
            weight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        Text(
          'Professional ERP System',
          textAlign: TextAlign.center,
          style: font(
            size: isSmall ? 22 : 25,
            height: 1.15,
            weight: FontWeight.w800,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Take a quick guided tour to understand the app faster, discover important actions, and avoid guessing where things are.',
          textAlign: TextAlign.center,
          style: font(
            size: 14,
            height: 1.48,
            weight: FontWeight.w400,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _BenefitItem(
                icon: Icons.explore_rounded,
                label: 'Easy\nNavigation',
                accent: Color(0xFF6366F1),
              ),
              _BenefitItem(
                icon: Icons.lightbulb_rounded,
                label: 'Smart\nGuidance',
                accent: Color(0xFFF59E0B),
              ),
              _BenefitItem(
                icon: Icons.schedule_rounded,
                label: 'Save\nTime',
                accent: Color(0xFF2563EB),
              ),
              _BenefitItem(
                icon: Icons.rocket_launch_rounded,
                label: 'Boost\nWork',
                accent: Color(0xFF10B981),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: busy ? null : onStart,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              disabledBackgroundColor: cs.primary.withOpacity(0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Let's Start",
                  style: font(
                    size: 16,
                    weight: FontWeight.w800,
                    color: cs.onPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded, size: 21),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: busy ? null : onStart,
          child: Text(
            'Explore with us',
            style: font(
              size: 14,
              weight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class _ErpPreviewArt extends StatelessWidget {
  final ColorScheme cs;

  const _ErpPreviewArt({required this.cs});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 14),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: SizedBox(
        height: 185,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primaryContainer.withOpacity(0.55),
                    cs.surfaceContainerHighest.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 18,
              child: Container(
                width: 190,
                height: 106,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.primary.withOpacity(0.34)),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.16),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ERP',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.pie_chart_rounded,
                            color: cs.tertiary, size: 28),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ArtLine(width: 90, color: cs.primary),
                    const SizedBox(height: 7),
                    _ArtLine(width: 140, color: cs.outlineVariant),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _MiniBar(height: 20, color: cs.primary),
                        _MiniBar(height: 32, color: cs.tertiary),
                        _MiniBar(height: 25, color: cs.secondary),
                        const Spacer(),
                        Icon(Icons.trending_up_rounded,
                            color: Colors.green.shade600, size: 26),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 22,
              bottom: 30,
              child: _FloatingPanel(
                cs: cs,
                icon: Icons.bar_chart_rounded,
                color: cs.primary,
              ),
            ),
            Positioned(
              right: 18,
              bottom: 24,
              child: _FloatingPanel(
                cs: cs,
                icon: Icons.groups_rounded,
                color: Colors.teal,
              ),
            ),
            Positioned(
              left: 58,
              top: 12,
              child: _FloatingIcon(
                cs: cs,
                icon: Icons.settings_rounded,
                color: cs.primary,
              ),
            ),
            Positioned(
              right: 64,
              top: 8,
              child: _FloatingIcon(
                cs: cs,
                icon: Icons.analytics_rounded,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _BenefitItem({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.14),
              border: Border.all(color: accent.withOpacity(0.18)),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroDot extends StatelessWidget {
  final bool active;
  final Color color;

  const _IntroDot({required this.active, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: active ? 18 : 10,
      height: 8,
      decoration: BoxDecoration(
        color: active ? color : color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _ArtLine extends StatelessWidget {
  final double width;
  final Color color;

  const _ArtLine({required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 7,
      decoration: BoxDecoration(
        color: color.withOpacity(0.32),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final double height;
  final Color color;

  const _MiniBar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: height,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.75),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _FloatingPanel extends StatelessWidget {
  final ColorScheme cs;
  final IconData icon;
  final Color color;

  const _FloatingPanel({
    required this.cs,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 58,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  final ColorScheme cs;
  final IconData icon;
  final Color color;

  const _FloatingIcon({
    required this.cs,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.24),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(icon, color: cs.onPrimary, size: 22),
    );
  }
}
