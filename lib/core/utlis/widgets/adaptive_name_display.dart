import 'package:flutter/material.dart';

class AdaptiveNameDisplay extends StatefulWidget {
  final String name;
  final String prefix;
  final TextStyle? style;
  final double minFontSize;
  final int maxLines;

  const AdaptiveNameDisplay({
    super.key,
    required this.name,
    this.prefix = '',
    this.style,
    this.minFontSize = 12,
    this.maxLines = 2,
  });

  @override
  State<AdaptiveNameDisplay> createState() => _AdaptiveNameDisplayState();
}

class _AdaptiveNameDisplayState extends State<AdaptiveNameDisplay> {
  int _mode = 0; // 0: full name, 1: fit, 2: initials

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return name;
    if (parts.length == 1) return name;

    final initials = parts
        .take(parts.length - 1)
        .map((e) => e.isNotEmpty ? '${e[0].toUpperCase()}.' : '')
        .join();
    return '$initials ${parts.last}';
  }

  String _composeText(String displayName) {
    final cleanedPrefix = widget.prefix.trim();
    if (cleanedPrefix.isEmpty) return displayName;
    return '$cleanedPrefix, $displayName';
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    switch (_mode) {
      // Priority 1: show full text first (allow wrapping)
      case 0:
        child = Text(
          _composeText(widget.name),
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: TextOverflow.ellipsis,
        );
        break;

      // Priority 2: fit full text in one line by reducing font size
      case 1:
        child = LayoutBuilder(
          builder: (context, constraints) {
            final style = widget.style ?? const TextStyle();
            final minFontSize = widget.minFontSize;
            final text = _composeText(widget.name);

            double fontSize = style.fontSize ?? 18;
            final tp = TextPainter(
              textDirection: TextDirection.ltr,
              maxLines: 1,
            );

            while (fontSize > minFontSize) {
              tp.text = TextSpan(
                text: text,
                style: style.copyWith(fontSize: fontSize),
              );
              tp.layout(maxWidth: constraints.maxWidth);
              if (!tp.didExceedMaxLines) break;
              fontSize -= 1;
            }

            return Text(
              text,
              style: style.copyWith(fontSize: fontSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        );
        break;

      // Priority 3: fallback initials style
      case 2:
      default:
        child = Text(
          _composeText(_getInitials(widget.name)),
          style: widget.style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
        break;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = (_mode + 1) % 3;
        });
      },
      child: child,
    );
  }
}
