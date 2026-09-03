import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import '../controllers/vendor_detail_controller.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// The vendor's purchase trail — one entry per purchase made against this
/// vendor, newest first per the backend's own ordering.
class VendorHistoryTab extends StatelessWidget {
  const VendorHistoryTab({
    super.key,
    required this.history,
    required this.onRetry,
    required this.onPrevious,
    required this.onNext,
  });

  final VendorSubPage<VendorHistoryModel> history;
  final VoidCallback onRetry;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildContent()),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                history.totalPages == 0
                    ? 'No results'
                    : 'Page ${history.pageNumber} of ${history.totalPages} · '
                          '${history.totalElements} purchase${history.totalElements == 1 ? '' : 's'}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            IconButton(
              onPressed: history.hasPreviousPage ? onPrevious : null,
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Previous page',
            ),
            IconButton(
              onPressed: history.hasNextPage ? onNext : null,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Next page',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (history.isLoading && history.items.isEmpty) {
      return const AppListSkeleton(itemCount: 4, hasThumbnail: false);
    }

    // Scrollable rather than returned bare — see the same wrapping in
    // `VendorLedgerTab._buildContent` for why.
    if (history.error != null && history.items.isEmpty) {
      return SingleChildScrollView(
        child: AppEmptyState.error(
          message: history.error,
          onAction: onRetry,
          compact: true,
        ),
      );
    }

    if (history.isEmpty) {
      return const SingleChildScrollView(
        child: AppEmptyState(
          icon: Icons.history_rounded,
          title: 'No purchases yet',
          message: 'Purchases made against this vendor will show up here.',
          compact: true,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      itemCount: history.items.length,
      separatorBuilder: (_, _) => const Divider(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        final entry = history.items[index];
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Purchase #${entry.purchaseId}',
                    style: AppTypography.subtitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatDate(entry.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
