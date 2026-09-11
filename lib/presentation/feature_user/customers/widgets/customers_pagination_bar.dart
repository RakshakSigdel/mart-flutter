import 'package:flutter/material.dart';

import '../../../../core/core.dart';

class CustomersPaginationBar extends StatelessWidget {
  const CustomersPaginationBar({
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
    final pageLabel = totalPages == 0
        ? 'No results'
        : 'Page $pageNumber of $totalPages · $totalElements customer${totalElements == 1 ? '' : 's'}';

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
