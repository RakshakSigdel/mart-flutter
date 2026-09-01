import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Prev/next controls plus a "Page X of Y · N products" summary.
class InventoryProductsPaginationBar extends StatelessWidget {
  const InventoryProductsPaginationBar({
    super.key,
    required this.pageNumber,
    required this.totalPages,
    required this.totalElements,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  final int pageNumber;
  final int totalPages;
  final int totalElements;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    // pageNumber is already 1-indexed, matching the backend's own paging.
    final pageLabel = totalPages == 0
        ? 'No results'
        : 'Page $pageNumber of $totalPages · $totalElements product${totalElements == 1 ? '' : 's'}';

    return Row(
      children: [
        Expanded(
          child: Text(
            pageLabel,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ),
        IconButton(
          onPressed: hasPrevious ? onPrevious : null,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Previous page',
        ),
        IconButton(
          onPressed: hasNext ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Next page',
        ),
      ],
    );
  }
}
