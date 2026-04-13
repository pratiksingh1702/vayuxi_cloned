import 'dart:io';

import 'package:flutter/material.dart';
import '../../models/floorModel.dart';

class FloorCard extends StatelessWidget {
  final Floor floor;
  final bool isSelected;
  final bool showEditButton;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FloorCard({
    super.key,
    required this.floor,
    this.isSelected = false,
    this.showEditButton = false,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.08),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image container (70% of available space)
                  Expanded(
                    flex: 9,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: cs.surfaceContainerLow,
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: _buildImage(context),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Text content (30% of available space)
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        floor.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Edit button
            if (showEditButton) ...[
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit Icon
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.outlineVariant),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withOpacity(0.2),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: cs.primary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Delete Icon
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.outlineVariant),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withOpacity(0.2),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: cs.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final img = floor.image;

    return _resolveImage(context, img);
  }

  Widget _resolveImage(BuildContext context, String img) {
    if (img.startsWith('http')) {
      return Image.network(
        img,
        fit: BoxFit.fitHeight,
        errorBuilder: (_, __, ___) => _fallbackIcon(context),
      );
    }

    // FILE PATH
    if (img.startsWith('/') || img.contains('storage')) {
      return Image.file(
        File(img),
        fit: BoxFit.fitHeight,
        errorBuilder: (_, __, ___) => _fallbackIcon(context),
      );
    }

    // ASSET IMAGE (mock)
    return Image.asset(
      img,
      fit: BoxFit.fitHeight,
      errorBuilder: (_, __, ___) => _fallbackIcon(context),
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Icon(
        Icons.house_siding_outlined,
        size: 40,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}
