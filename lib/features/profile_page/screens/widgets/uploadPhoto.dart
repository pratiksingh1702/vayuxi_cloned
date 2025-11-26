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
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: 2,
                ),
                color: Colors.grey.shade100,
              ),
              child: _buildImage(),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (imagePath == null || imagePath!.isEmpty) {
      return Icon(
        isCompanyLogo ? Icons.business : Icons.person,
        size: 40,
        color: Colors.grey.shade400,
      );
    }

    if (imagePath!.startsWith('http')) {
      return ClipOval(
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
      return ClipOval(
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