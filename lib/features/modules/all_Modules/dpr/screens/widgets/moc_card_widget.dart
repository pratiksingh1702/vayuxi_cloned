// widgets/moc_card.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/moc.dart';

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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
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
                        Expanded(
                            flex: 9,

                            child: _buildImage()),



                        // MOC Name
                        Expanded(
                          flex: 2,
                          child: Text(


                            moc.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.blue,
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
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.red,
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
  Widget _buildImage() {
    final img = moc.imageUrl;

    return _resolveImage(img!);
  }



  Widget _resolveImage(String img) {
    // NETWORK (CACHED)
    if (img.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: img,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (_, __, ___) => _fallbackIcon(),
      );
    }

    // FILE PATH
    if (img.startsWith('/') || img.contains('storage')) {
      return Image.file(
        File(img),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackIcon(),
      );
    }

    // ASSET IMAGE
    return Image.asset(
      img,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Icon(
      Icons.house_siding_outlined,
      size: 40,
      color: Colors.grey.shade400,
    );
  }

}