import 'dart:io';
import 'package:flutter/material.dart';

Widget buildSmartImage({
  required String image,
  double height = 100,
  double width = double.infinity,
  BoxFit fit = BoxFit.contain,
}) {
  if (image.isEmpty) {
    return _imagePlaceholder(height, width);
  }

  final isAsset = image.startsWith('assets/');
  final isNetwork = image.startsWith('http://') || image.startsWith('https://');
  final isFileUri = image.startsWith('file://');
  final isRawFilePath = image.startsWith('/');

  return SizedBox(
    height: height,
    width: width,
    child: () {
      if (isNetwork) {
        return Image.network(
          image,
          fit: fit,
          errorBuilder: (_, __, ___) =>
              _imagePlaceholder(height, width),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
        );
      }

      if (isAsset) {
        return Image.asset(
          image,
          fit: fit,
          errorBuilder: (_, __, ___) =>
              _imagePlaceholder(height, width),
        );
      }

      if (isFileUri || isRawFilePath) {
        final path = isFileUri ? image.replaceFirst('file://', '') : image;

        return Image.file(
          File(path),
          fit: fit,
          errorBuilder: (_, __, ___) =>
              _imagePlaceholder(height, width),
        );
      }

      // Fallback (unknown format)
      return _imagePlaceholder(height, width);
    }(),
  );
}

Widget _imagePlaceholder(double height, double width) {
  return Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(
      Icons.image_not_supported,
      color: Colors.grey,
      size: 32,
    ),
  );
}
