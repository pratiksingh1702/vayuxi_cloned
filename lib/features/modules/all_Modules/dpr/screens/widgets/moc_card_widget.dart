// widgets/moc_card.dart
import 'package:flutter/material.dart';
import '../../models/moc.dart';
import '../../utils/image_track/dpr_cached_image.dart';

class MOCCard extends StatelessWidget {
  final MOC moc;
  final bool isSelected;
  final bool showEditButton;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MOCCard({
    super.key,
    required this.moc,
    this.isSelected = false,
    this.showEditButton = false,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Card(
          elevation: 0.5,
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? cs.primary : cs.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // MOC Image
                        Expanded(flex: 9, child: _buildImage(context)),

                        // MOC Name
                        Expanded(
                          flex: 2,
                          child: Text(
                            moc.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 4),
                      ],
                    ),
                  ),

                  // Edit/Delete buttons (conditionally shown)
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
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final img = moc.imageUrl;

    return DprCachedImage(
      imagePath: img ?? '',
      fit: BoxFit.cover,
      fallback: _fallbackIcon(context),
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Icon(
      Icons.house_siding_outlined,
      size: 40,
      color: cs.onSurfaceVariant,
    );
  }
}
