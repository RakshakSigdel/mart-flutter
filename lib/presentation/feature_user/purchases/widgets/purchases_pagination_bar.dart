import 'package:flutter/material.dart';

import '../../../shared/widgets/section_ui.dart';

/// Paging footer for the purchase ledger. Unfilled — the ledger sits
/// directly on the page rather than inside a panel.
class PurchasesPaginationBar extends StatelessWidget {
  const PurchasesPaginationBar({
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
    return SectionPaginationBar(
      pageNumber: pageNumber,
      totalPages: totalPages,
      totalElements: totalElements,
      itemNoun: 'purchase',
      hasPrevious: hasPrevious,
      hasNext: hasNext,
      onPrevious: onPrevious,
      onNext: onNext,
      filled: false,
    );
  }
}
