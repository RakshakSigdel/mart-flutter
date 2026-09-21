import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// A product's picture, or its initial on a soft brand wash when there is no
/// image on file — so rows and headers have something to anchor on.
class ProductThumb extends StatelessWidget {
  const ProductThumb({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
  });

  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.softPrimary,
        borderRadius: radius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: imageUrl?.isNotEmpty == true
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (_, _, _) => _initial,
            )
          : _initial,
    );
  }

  Widget get _initial => Text(
    name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
    style: AppTypography.label.copyWith(
      fontSize: size * 0.4,
      color: AppColors.primaryDeep,
    ),
  );
}
