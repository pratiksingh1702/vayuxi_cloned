import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/typeProvider/work_type.dart';

class LanguageFirstTimePopup extends StatefulWidget {
  final FutureOr<void> Function() onSelectLanguage;
  final FutureOr<void> Function() onSkip;
  final FutureOr<void> Function() onStartTour;
  final FutureOr<void> Function() onSkipPopup;
  final FutureOr<void> Function(List<String> selectedTypes)
      onWorkspaceConfirmed;

  const LanguageFirstTimePopup({
    super.key,
    required this.onSelectLanguage,
    required this.onSkip,
    required this.onStartTour,
    required this.onSkipPopup,
    required this.onWorkspaceConfirmed,
  });

  @override
  State<LanguageFirstTimePopup> createState() => _LanguageFirstTimePopupState();
}

class _LanguageFirstTimePopupState extends State<LanguageFirstTimePopup> {
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
        _activePanel = 1;
      });
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      rethrow;
    }
  }

  void _showDomainSelection() {
    if (_busy) return;
    setState(() => _activePanel = 2);
  }

  Future<void> _saveWorkspaceTypes(List<String> selectedTypes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('user_workspace_types', selectedTypes);
    } catch (_) {
      // Workspace personalization is helpful, but onboarding should not block.
    }
  }

  Future<void> _finishWorkspace(List<String> selectedTypes) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _saveWorkspaceTypes(selectedTypes);
      await widget.onWorkspaceConfirmed(selectedTypes);
      await widget.onStartTour();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skipWorkspace() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await _saveWorkspaceTypes(const []);
      await widget.onWorkspaceConfirmed(const []);
      await widget.onSkipPopup();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _activeBody(ColorScheme cs, bool isSmall) {
    if (_activePanel == 2) {
      return _DomainSelectionBody(
        key: const ValueKey('domain-selection'),
        cs: cs,
        isSmall: isSmall,
        busy: _busy,
        font: _font,
        onConfirm: _finishWorkspace,
        onSkip: _skipWorkspace,
      );
    }

    if (_activePanel == 1) {
      return _TourIntroBody(
        key: const ValueKey('tour-intro'),
        cs: cs,
        isSmall: isSmall,
        busy: _busy,
        font: _font,
        onStart: _showDomainSelection,
        onSkip: _skipWorkspace,
      );
    }

    return _LanguageBody(
      key: const ValueKey('language'),
      cs: cs,
      isSmall: isSmall,
      busy: _busy,
      font: _font,
      onSelectLanguage: () => _afterLanguageChoice(widget.onSelectLanguage),
      onContinueEnglish: () => _afterLanguageChoice(widget.onSkip),
    );
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
                  final isDomain = keyText.contains('domain-selection');
                  final incomingOffset = isIntro || isDomain
                      ? const Offset(1, 0)
                      : const Offset(-1, 0);
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
                child: _activeBody(cs, isSmall),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DomainSelectionBody extends StatefulWidget {
  final ColorScheme cs;
  final bool isSmall;
  final bool busy;
  final TextStyle Function({
    double? size,
    FontWeight? weight,
    Color? color,
    double? height,
  }) font;
  final FutureOr<void> Function(List<String> selectedTypes) onConfirm;
  final FutureOr<void> Function() onSkip;

  const _DomainSelectionBody({
    super.key,
    required this.cs,
    required this.isSmall,
    required this.busy,
    required this.font,
    required this.onConfirm,
    required this.onSkip,
  });

  @override
  State<_DomainSelectionBody> createState() => _DomainSelectionBodyState();
}

class _DomainSelectionBodyState extends State<_DomainSelectionBody> {
  final Set<String> _selectedTypes = {};

  void _toggle(WorkType type) {
    if (widget.busy) return;
    setState(() {
      if (!_selectedTypes.add(type.name)) {
        _selectedTypes.remove(type.name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final font = widget.font;
    final canStart = _selectedTypes.isNotEmpty && !widget.busy;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * 36, 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: widget.busy ? null : widget.onSkip,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Skip popup',
                style: IconButton.styleFrom(
                  backgroundColor: cs.primary.withOpacity(0.1),
                  foregroundColor: cs.primary,
                  minimumSize: const Size(36, 36),
                  fixedSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Workspace Setup',
                  style: font(
                    size: 14,
                    weight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "What's your work domain?",
            style: font(
              size: widget.isSmall ? 21 : 24,
              height: 1.2,
              weight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Select the work types you handle. You can always add more later.',
            style: font(
              size: 14,
              height: 1.45,
              weight: FontWeight.w400,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: WorkType.values.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.18,
            ),
            itemBuilder: (context, index) {
              final type = WorkType.values[index];
              return _DomainTypeChip(
                type: type,
                selected: _selectedTypes.contains(type.name),
                onTap: () => _toggle(type),
                font: font,
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  canStart ? () => widget.onConfirm(_selectedTypes.toList()) : null,
              icon: widget.busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.workspace_premium_rounded, size: 19),
              label: Text(
                'Start My Workspace',
                style: font(weight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                disabledBackgroundColor: cs.primary.withOpacity(0.38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainTypeChip extends StatelessWidget {
  const _DomainTypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
    required this.font,
  });

  final WorkType type;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle Function({
    double? size,
    FontWeight? weight,
    Color? color,
    double? height,
  }) font;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: selected ? 1.02 : 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: selected
                  ? type.accentColor.withOpacity(0.1)
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? type.accentColor : cs.outlineVariant,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          type.imagePath,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) => Container(
                            color: type.accentColor.withOpacity(0.14),
                            child: Icon(
                              Icons.business_center_rounded,
                              color: type.accentColor,
                            ),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 180),
                        right: selected ? 6 : -24,
                        top: 6,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: selected ? 1 : 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: type.accentColor,
                              boxShadow: [
                                BoxShadow(
                                  color: type.accentColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  type.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: font(
                    size: 12,
                    weight: FontWeight.w800,
                    color: selected ? type.accentColor : cs.onSurface,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton.filledTonal(
                onPressed: busy ? null : onSkip,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Skip popup',
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
          _TourIntroImageSlider(cs: cs),
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

class _TourIntroImageSlider extends StatefulWidget {
  final ColorScheme cs;

  const _TourIntroImageSlider({required this.cs});

  @override
  State<_TourIntroImageSlider> createState() => _TourIntroImageSliderState();
}

class _TourIntroImageSliderState extends State<_TourIntroImageSlider> {
  static const _images = [
    'assets/images/tour_intro/erp_intro_1.png',
    'assets/images/tour_intro/erp_intro_2.png',
    'assets/images/tour_intro/erp_intro_3.png',
  ];

  late final PageController _controller;
  Timer? _timer;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
    _timer = Timer.periodic(const Duration(milliseconds: 2300), (_) {
      if (!mounted || !_controller.hasClients) return;
      final nextIndex = (_activeIndex + 1) % _images.length;
      _controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return Column(
      children: [
        TweenAnimationBuilder<double>(
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
            height: 190,
            child: PageView.builder(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              itemCount: _images.length,
              onPageChanged: (index) => setState(() => _activeIndex = index),
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double distance = 0;
                    if (_controller.hasClients &&
                        _controller.position.haveDimensions) {
                      distance = (_controller.page ?? _activeIndex.toDouble()) - index;
                    } else {
                      distance = (_activeIndex - index).toDouble();
                    }
                    final scale = (1 - distance.abs() * 0.08).clamp(0.9, 1.0);
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.16),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          _images[index],
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, __, ___) => Container(
                            color: cs.primaryContainer,
                            child: Icon(
                              Icons.dashboard_customize_rounded,
                              size: 56,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _images.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _IntroDot(
                active: _activeIndex == index,
                color: cs.primary,
              ),
            ),
          ),
        ),
      ],
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
