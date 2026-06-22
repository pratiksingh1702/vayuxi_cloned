import 'package:flutter/material.dart';

class SelectCardIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const SelectCardIcon({
    super.key,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.48 : 0.22),
        ),
      ),
      child: Icon(
        icon,
        size: 29,
        color: color,
      ),
    );
  }
}

class SelectCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final double? width;
  final double? height;
  final String? subtitle;

  const SelectCard({
    super.key,
    required this.icon,
    this.color = Colors.black,
    required this.label,
    required this.onTap,
    this.width,
    this.height,
    this.subtitle,
  });

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String? _defaultSubtitle(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized == 'view' || normalized.startsWith('view ')) {
      return 'Review existing records';
    }
    if (normalized == 'add' || normalized.startsWith('add ')) {
      return 'Create a new record';
    }
    if (normalized.contains('manual')) {
      return 'Enter details manually';
    }
    if (normalized.contains('upload') || normalized.contains('import')) {
      return 'Upload from file';
    }
    return null;
  }

  Color _accentColor(ColorScheme cs) {
    if (icon is SelectCardIcon) return (icon as SelectCardIcon).color;
    if (color != Colors.black) return color;
    return cs.primary;
  }

  IconData? _iconData() {
    if (icon is SelectCardIcon) return (icon as SelectCardIcon).icon;
    return null;
  }

  String _ctaLabel(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized == 'view' || normalized.startsWith('view ')) return 'Open';
    if (normalized == 'add' || normalized.startsWith('add ')) return 'Create';
    if (normalized.contains('upload') || normalized.contains('import')) {
      return 'Upload';
    }
    return 'Continue';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accentColor(cs);
    final cardSubtitle = subtitle ?? _defaultSubtitle(label);
    final title = _capitalize(label);
    final watermarkIcon = _iconData();
    final textColor = cs.onSurface;
    final mutedColor = cs.onSurfaceVariant;

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: isDark ? 0.16 : 0.09),
                isDark ? cs.surfaceContainerHigh : cs.surface,
                isDark ? cs.surfaceContainerHigh : Colors.white,
              ],
              stops: const [0, 0.48, 1],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? accent.withValues(alpha: 0.28)
                  : accent.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: cs.shadow.withValues(alpha: isDark ? 0.14 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                if (watermarkIcon != null)
                  Positioned(
                    right: -18,
                    top: 10,
                    child: Icon(
                      watermarkIcon,
                      size: 92,
                      color: accent.withValues(alpha: isDark ? 0.07 : 0.045),
                    ),
                  ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.95),
                          accent.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 15, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          icon,
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(
                                  alpha: isDark ? 0.18 : 0.11),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: accent.withValues(
                                  alpha: isDark ? 0.24 : 0.16,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _ctaLabel(label),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    height: 1,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: accent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        title,
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      if (cardSubtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          cardSubtitle,
                          textAlign: TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (width != null || height != null) {
      return Align(
        child: SizedBox(
          width: width,
          height: height,
          child: card,
        ),
      );
    }

    return card;
  }
}
