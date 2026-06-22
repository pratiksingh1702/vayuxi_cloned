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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : cs.surfaceContainerLow,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Icon(
          fallbackIcon,
          size: 24,
          color: cs.onSurfaceVariant,
        ),
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
        height: 90,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildIconPlaceholder(context),
      );
    }

    return CachedNetworkImage(
      imageUrl: normalized,
      height: 90,
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
    final title =
        companyName.trim().isEmpty ? 'Unknown Site' : companyName.trim();

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? cs.surfaceContainerHigh : cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? cs.outline.withValues(alpha: 0.28)
                    : cs.outlineVariant,
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: isDark ? 0.14 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardImage(context),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Site details',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'Open site',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (show)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: cs.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: cs.error,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
