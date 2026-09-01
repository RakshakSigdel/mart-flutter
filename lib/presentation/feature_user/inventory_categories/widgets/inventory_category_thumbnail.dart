import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// A category's [image] URL, rendered as a small rounded square — or a
/// placeholder icon when there's no image or it fails to load. This app
/// doesn't upload images; it only displays whatever URL the backend has on
/// file.
class InventoryCategoryThumbnail extends StatelessWidget {
  const InventoryCategoryThumbnail({super.key, this.imageUrl, this.size = 44});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    return ClipRRect(
      borderRadius: AppBorderRadius.radiusMD,
      child: Container(
        width: size,
        height: size,
        color: AppColors.surfaceSunken,
        child: (url == null || url.isEmpty)
            ? _placeholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() => Icon(
        Icons.category_outlined,
        size: size * 0.5,
        color: AppColors.iconInactive,
      );
}
