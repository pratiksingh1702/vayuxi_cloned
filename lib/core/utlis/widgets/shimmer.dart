import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A fully customizable shimmer loading list widget.
///
/// Usage Examples:
///
/// 1. Basic list shimmer (default card style):
///    ShimmerList()
///
/// 2. Custom item count and layout:
///    ShimmerList(
///      itemCount: 5,
///      type: ShimmerListType.tile,
///    )
///
/// 3. Grid shimmer:
///    ShimmerList(
///      type: ShimmerListType.grid,
///      crossAxisCount: 2,
///    )
///
/// 4. Fully custom item builder:
///    ShimmerList.custom(
///      itemCount: 4,
///      itemBuilder: (context, index) => MyCustomShimmerItem(),
///    )
///
/// 5. Inline (non-scrollable, inside a Column/ListView):
///    ShimmerList(scrollable: false, itemCount: 3)

enum ShimmerListType { card, tile, grid, avatar, teamGrid, moduleGrid }

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final ShimmerListType type;
  final Color? baseColor;
  final Color? highlightColor;
  final EdgeInsetsGeometry padding;
  final double itemSpacing;
  final bool scrollable;

  // Grid-specific
  final int crossAxisCount;
  final double gridChildAspectRatio;

  const ShimmerList({
    super.key,
    this.itemCount = 6,
    this.type = ShimmerListType.card,
    this.baseColor,
    this.highlightColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.itemSpacing = 12,
    this.scrollable = true,
    this.crossAxisCount = 2,
    this.gridChildAspectRatio = 1.0,
  });

  /// Factory constructor for a fully custom shimmer item builder.
  static Widget custom({
    Key? key,
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    Color? baseColor,
    Color? highlightColor,
    EdgeInsetsGeometry padding =
    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    double itemSpacing = 12,
    bool scrollable = true,
  }) {
    return _CustomShimmerList(
      key: key,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      baseColor: baseColor,
      highlightColor: highlightColor,
      padding: padding,
      itemSpacing: itemSpacing,
      scrollable: scrollable,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBase =
        baseColor ?? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0));
    final resolvedHighlight =
        highlightColor ?? (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5));

    if (type == ShimmerListType.grid) {
      return _buildGrid(resolvedBase, resolvedHighlight);
    }

    return _buildList(resolvedBase, resolvedHighlight);
  }

  Widget _buildList(Color base, Color highlight) {
    final items = List.generate(
      itemCount,
          (index) => Padding(
        padding: EdgeInsets.only(bottom: itemSpacing),
        child: _buildItem(index, base, highlight),
      ),
    );

    final shimmerContent = Column(children: items);

    if (!scrollable) {
      return Padding(padding: padding, child: shimmerContent);
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      child: shimmerContent,
    );
  }

  Widget _buildGrid(Color base, Color highlight) {
    return GridView.builder(
      shrinkWrap: !scrollable,
      physics: scrollable
          ? const NeverScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: itemSpacing,
        mainAxisSpacing: itemSpacing,
        childAspectRatio: gridChildAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (_, index) => _buildItem(index, base, highlight),
    );
  }

  Widget _buildItem(int index, Color base, Color highlight) {
    switch (type) {
      case ShimmerListType.card:
        return _ShimmerCardItem(base: base, highlight: highlight);
      case ShimmerListType.tile:
        return _ShimmerTileItem(base: base, highlight: highlight);
      case ShimmerListType.avatar:
        return _ShimmerAvatarItem(base: base, highlight: highlight);
      case ShimmerListType.grid:
        return _ShimmerGridItem(base: base, highlight: highlight);
      case ShimmerListType.teamGrid:
        return _ShimmerTeamGridItem(base: base, highlight: highlight);
      case ShimmerListType.moduleGrid:
        return _ShimmerModuleGridItem(base: base, highlight: highlight);
    }
  }
}

/// A specialized shimmer widget for image placeholders.
/// Replicates dimensions, borders, and aspect ratio of real images.
class ShimmerImage extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final double? aspectRatio;
  final BoxShape shape;
  final Color? baseColor;
  final Color? highlightColor;
  final BoxBorder? border;

  const ShimmerImage({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.aspectRatio,
    this.shape = BoxShape.rectangle,
    this.baseColor,
    this.highlightColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBase =
        baseColor ?? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0));
    final resolvedHighlight =
        highlightColor ?? (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5));

    Widget content = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        shape: shape,
        border: border,
      ),
    );

    if (aspectRatio != null) {
      content = AspectRatio(
        aspectRatio: aspectRatio!,
        child: content,
      );
    }

    return Shimmer.fromColors(
      baseColor: resolvedBase,
      highlightColor: resolvedHighlight,
      child: content,
    );
  }
}

/// A simple shimmer box for individual placeholders.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 6,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBase =
        baseColor ?? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0));
    final resolvedHighlight =
        highlightColor ?? (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5));

    return Shimmer.fromColors(
      baseColor: resolvedBase,
      highlightColor: resolvedHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A simple shimmer circle for individual placeholders.
class ShimmerCircle extends StatelessWidget {
  final double size;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerCircle({
    super.key,
    required this.size,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBase =
        baseColor ?? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0));
    final resolvedHighlight =
        highlightColor ?? (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5));

    return Shimmer.fromColors(
      baseColor: resolvedBase,
      highlightColor: resolvedHighlight,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── Internal custom list ────────────────────────────────────────────────────

class _CustomShimmerList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Color? baseColor;
  final Color? highlightColor;
  final EdgeInsetsGeometry padding;
  final double itemSpacing;
  final bool scrollable;

  const _CustomShimmerList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.baseColor,
    this.highlightColor,
    required this.padding,
    required this.itemSpacing,
    required this.scrollable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final base =
        baseColor ?? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0));
    final highlight =
        highlightColor ?? (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5));

    final children = List.generate(
      itemCount,
          (i) => Padding(
        padding: EdgeInsets.only(bottom: itemSpacing),
        child: itemBuilder(context, i),
      ),
    );

    final shimmerContent = Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(children: children),
    );

    if (!scrollable) {
      return Padding(padding: padding, child: shimmerContent);
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      child: shimmerContent,
    );
  }
}

// ─── Shimmer Item Variants ───────────────────────────────────────────────────

/// Card-style: image placeholder on top, text lines below
class _ShimmerCardItem extends StatelessWidget {
  final Color base;
  final Color highlight;

  const _ShimmerCardItem({required this.base, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Image placeholder
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Action buttons placeholders
                    Row(
                      children: [
                        Expanded(child: _skeletonBox(height: 28)),
                        const SizedBox(width: 8),
                        Expanded(child: _skeletonBox(height: 28)),
                        const SizedBox(width: 8),
                        Expanded(child: _skeletonBox(height: 28)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right Column: Field placeholders
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBox(width: 80, height: 12),
                    const SizedBox(height: 6),
                    _skeletonBox(width: double.infinity, height: 24, borderRadius: 4),
                    const SizedBox(height: 12),
                    _skeletonBox(width: 80, height: 12),
                    const SizedBox(height: 6),
                    _skeletonBox(width: double.infinity, height: 24, borderRadius: 4),
                    const SizedBox(height: 12),
                    _skeletonBox(width: 100, height: 12),
                    const SizedBox(height: 6),
                    _skeletonBox(width: double.infinity, height: 48, borderRadius: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile-style: leading circle avatar + text lines (like ListTile)
class _ShimmerTileItem extends StatelessWidget {
  final Color base;
  final Color highlight;

  const _ShimmerTileItem({required this.base, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBox(width: double.infinity, height: 13),
                  const SizedBox(height: 8),
                  _skeletonBox(width: 140, height: 11),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _skeletonBox(width: 40, height: 11),
          ],
        ),
      ),
    );
  }
}

/// Avatar-style: large circle + text centered below (social / profile list)
class _ShimmerAvatarItem extends StatelessWidget {
  final Color base;
  final Color highlight;

  const _ShimmerAvatarItem({required this.base, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBox(width: 120, height: 14),
                  const SizedBox(height: 8),
                  _skeletonBox(width: double.infinity, height: 11),
                  const SizedBox(height: 6),
                  _skeletonBox(width: 200, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid-style: square card with text below
class _ShimmerGridItem extends StatelessWidget {
  final Color base;
  final Color highlight;

  const _ShimmerGridItem({required this.base, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBox(width: double.infinity, height: 12),
                  const SizedBox(height: 6),
                  _skeletonBox(width: 60, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Team Grid-style: card with circular avatar and text
class _ShimmerTeamGridItem extends StatelessWidget {
  final Color base;
  final Color highlight;

  const _ShimmerTeamGridItem({required this.base, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 10),
              _skeletonBox(width: 80, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// Module Grid-style: specifically for the home screen module cards
class _ShimmerModuleGridItem extends StatelessWidget {
  final Color base;
  final Color highlight;

  const _ShimmerModuleGridItem({required this.base, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon skeleton
            Container(
              height: 90,
              width: 90,
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Text skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _skeletonBox(width: double.infinity, height: 14, borderRadius: 4),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _skeletonBox(width: double.infinity, height: 14, borderRadius: 4),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _skeletonBox({double? width, required double height, double borderRadius = 6}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );
}

// ─── Primitive Shimmer Shapes ────────────────────────────────────────────────

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  final double size;

  const _ShimmerCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}