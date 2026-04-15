import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CompanyCard extends StatelessWidget {
  final String imagePath;
  final String defaultImage;
  final String companyName;
  final IconData fallbackIcon;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool show;

  const CompanyCard({
    super.key,
    required this.imagePath,
    required this.companyName,
    this.defaultImage = 'assets/images/default.webp',
    this.fallbackIcon = Icons.location_city_rounded,
    this.onTap,
    this.onDelete,
    this.show = false,
  });

  Widget _buildIconPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 100,
      width: double.infinity,
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        size: 42,
        color: cs.onSurfaceVariant,
      ),
    );
  }

  Widget _buildCardImage(BuildContext context) {
    final normalized = imagePath.trim();
    if (normalized.isEmpty) {
      return _buildIconPlaceholder(context);
    }

    if (normalized.startsWith('assets/')) {
      return Image.asset(
        normalized,
        height: 100,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildIconPlaceholder(context),
      );
    }

    return CachedNetworkImage(
      imageUrl: normalized,
      height: 100,
      width: double.infinity,
      fit: BoxFit.cover,
      memCacheWidth: 400,
      errorWidget: (context, url, error) => _buildIconPlaceholder(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 0,
          color: isDark ? cs.surfaceContainer : cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: isDark
                  ? cs.outline.withOpacity(0.35)
                  : cs.outlineVariant.withOpacity(0.9),
            ),
          ),
          child: Stack(children: [
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                      child: _buildCardImage(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      companyName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (show)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.error.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: cs.onError,
                      size: 18,
                    ),
                  ),
                ),
              )
          ]),
        ),
      ),
    );
  }
}
