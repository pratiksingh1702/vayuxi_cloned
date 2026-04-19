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
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.20 : 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.58 : 0.34),
        ),
      ),
      child: Icon(
        icon,
        size: 34,
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

  const SelectCard({
    super.key,
    required this.icon,
    this.color = Colors.black,
    required this.label,
    required this.onTap,
    this.width,
    this.height,
  });

  // Helper function to capitalize first letter
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Card(
      elevation: 0.8,
      color: isDark ? cs.surfaceContainer : cs.surface,
      surfaceTintColor: cs.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? cs.outline.withOpacity(0.35) : cs.outlineVariant,
        ),
      ),
      shadowColor: cs.shadow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 70,
                width: 70,
                child: Center(
                  child: icon,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _capitalize(label), // Capitalize first letter here
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
