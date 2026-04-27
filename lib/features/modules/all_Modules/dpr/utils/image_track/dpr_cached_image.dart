import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../../core/utlis/widgets/shimmer.dart';
import '../../offline/data/local/cache_image_dao.dart';
import '../../offline/data/remote/image_cache_service.dart';

class DprCachedImage extends StatefulWidget {
  final String imagePath;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final Widget? fallback;
  final bool showShimmer;
  final Widget? shimmer;

  const DprCachedImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.fallback,
    this.showShimmer = true,
    this.shimmer,
  });

  @override
  State<DprCachedImage> createState() => _DprCachedImageState();
}

class _DprCachedImageState extends State<DprCachedImage> {
  String? _cachedPath;

  @override
  void initState() {
    super.initState();
    _refreshCacheState();
  }

  @override
  void didUpdateWidget(covariant DprCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _refreshCacheState();
    }
  }

  void _refreshCacheState() {
    _cachedPath = null;
    if (_isNetworkImage(widget.imagePath)) {
      _loadCachedPath(widget.imagePath);
    }
  }

  Future<void> _loadCachedPath(String url) async {
    final cached = await CachedImageDao().getLocalPath(url);
    if (cached != null) {
      final file = File(cached);
      if (await file.exists()) {
        if (mounted) {
          setState(() => _cachedPath = cached);
        }
        return;
      }
    }

    ImageCacheService.cacheImage(
      url: url,
      fileName: _fileNameFor(url),
    ).then((path) {
      if (!mounted) return;
      if (path.isNotEmpty) {
        setState(() => _cachedPath = path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.imagePath;

    if (_isNetworkImage(imagePath)) {
      if (_cachedPath != null && _cachedPath!.isNotEmpty) {
        return Image.file(
          File(_cachedPath!),
          fit: widget.fit,
          alignment: widget.alignment,
          width: widget.width,
          height: widget.height,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _fallback(context),
        );
      }

      return Image.network(
        imagePath,
        fit: widget.fit,
        alignment: widget.alignment,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null || !widget.showShimmer) return child;
          return _loadingWidget(context);
        },
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    if (_isFilePath(imagePath)) {
      return Image.file(
        File(imagePath),
        fit: widget.fit,
        alignment: widget.alignment,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    if (imagePath.isNotEmpty) {
      return Image.asset(
        imagePath,
        fit: widget.fit,
        alignment: widget.alignment,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    return _fallback(context);
  }

  Widget _loadingWidget(BuildContext context) {
    return widget.shimmer ??
        ShimmerImage(
          width: widget.width,
          height: widget.height,
          borderRadius: 8,
        );
  }

  Widget _fallback(BuildContext context) {
    return widget.fallback ?? const SizedBox.shrink();
  }

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  bool _isFilePath(String path) {
    return path.startsWith('/') || path.contains('storage');
  }

  String _fileNameFor(String url) {
    final ext = _extensionFromUrl(url);
    return 'dpr_${url.hashCode}$ext';
  }

  String _extensionFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? '';
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex < path.lastIndexOf('/')) {
      return '.img';
    }
    return path.substring(dotIndex);
  }
}
