// lib/widgets/upload_photo_button.dart
import 'package:flutter/material.dart';
import 'dart:io';

class UploadPhotoButton extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onPressed;
  final bool isCompanyLogo;
  final double size;

  const UploadPhotoButton({
    super.key,
    this.imagePath,
    required this.onPressed,
    this.isCompanyLogo = false,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surfaceContainerLow,
              ),
              child: _buildImage(),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                child: IconButton(
                  icon: Icon(Icons.camera_alt, color: colorScheme.onPrimary),
                  onPressed: onPressed,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isCompanyLogo ? 'Company Logo' : 'Profile Photo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (imagePath == null || imagePath!.isEmpty) {
      // Uses neutral placeholder aligned with themed surface.
      return Icon(
        isCompanyLogo ? Icons.business : Icons.person,
        size: 40,
        color: Colors.grey.shade500,
      );
    }

    if (imagePath!.startsWith('http')) {
      return ClipRect(
        child: Image.network(
          imagePath!,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              isCompanyLogo ? Icons.business : Icons.person,
              size: 40,
              color: Colors.grey.shade400,
            );
          },
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(imagePath!),
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              isCompanyLogo ? Icons.business : Icons.person,
              size: 40,
              color: Colors.grey.shade400,
            );
          },
        ),
      );
    }
  }
}
