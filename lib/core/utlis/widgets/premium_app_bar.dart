import 'dart:ui';

import 'package:flutter/material.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.actions = const <Widget>[],
    this.bottom,
    this.showDrawerButton = true,
    this.onDrawerPressed,
    this.drawerIcon = Icons.menu_rounded,
    this.drawerTooltip = 'Open menu',
    this.backgroundImage,
    this.backgroundGradient,
    this.surfaceTintColor,
    this.height = 74,
    this.horizontalPadding = 12,
    this.verticalPadding = 8,
    this.titleMaxWidth = 420,
  }) : assert(
          title != null || titleWidget != null,
          'Provide either title or titleWidget.',
        );

  final String? title;
  final Widget? titleWidget;
  final Widget? subtitle;
  final List<Widget> actions;
  final Widget? bottom;
  final bool showDrawerButton;
  final VoidCallback? onDrawerPressed;
  final IconData drawerIcon;
  final String drawerTooltip;
  final String? backgroundImage;
  final LinearGradient? backgroundGradient;
  final Color? surfaceTintColor;
  final double height;
  final double horizontalPadding;
  final double verticalPadding;
  final double titleMaxWidth;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? colorScheme.surface : colorScheme.surfaceContainerLowest;

    final gradient = backgroundGradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scaffoldBg,
            scaffoldBg,
          ],
        );

    final surfaceColor = surfaceTintColor ?? scaffoldBg;
    final effectiveOnDrawerPressed =
        onDrawerPressed ?? () => Scaffold.maybeOf(context)?.openDrawer();

    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: backgroundImage == null
              ? null
              : DecorationImage(
                  image: AssetImage(backgroundImage!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    colorScheme.surface.withOpacity(0.22),
                    BlendMode.screen,
                  ),
                ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: gradient),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: SafeArea(
              bottom: false,
              child: Container(
                height: height,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  verticalPadding,
                  horizontalPadding,
                  verticalPadding,
                ),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withOpacity(0.18),
                      width: 0.9,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          if (showDrawerButton)
                            _PremiumIconButton(
                              tooltip: drawerTooltip,
                              icon: drawerIcon,
                              onPressed: effectiveOnDrawerPressed,
                              accentColor: colorScheme.primary,
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: titleMaxWidth),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: titleWidget ??
                                    _PremiumTitleText(
                                      title: title!,
                                      subtitle: subtitle,
                                    ),
                              ),
                            ),
                          ),
                          if (actions.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (int i = 0; i < actions.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 8),
                                  actions[i],
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (bottom != null) ...[
                      const SizedBox(height: 8),
                      bottom!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumTitleText extends StatelessWidget {
  const _PremiumTitleText({
    required this.title,
    this.subtitle,
  });

  final String title;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
            color: colorScheme.onSurface,
            height: 1.1,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
            child: subtitle!,
          ),
        ],
      ],
    );
  }
}

class _PremiumIconButton extends StatelessWidget {
  const _PremiumIconButton({
    required this.icon,
    required this.onPressed,
    required this.accentColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color accentColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final button = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : cs.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        splashRadius: 20,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, color: accentColor, size: 20),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class PremiumActionIcon extends StatelessWidget {
  const PremiumActionIcon({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? cs.surfaceContainerHigh : cs.surface.withOpacity(0.95));
    final fg = iconColor ?? cs.primary;
    final border = borderColor ?? fg.withOpacity(0.14);

    final child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        splashRadius: size / 2,
        icon: Icon(icon, size: 20, color: fg),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}

class PremiumTitleBadge extends StatelessWidget {
  const PremiumTitleBadge({
    super.key,
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: cs.onPrimaryContainer),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: cs.onPrimaryContainer,
                letterSpacing: 0.18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
