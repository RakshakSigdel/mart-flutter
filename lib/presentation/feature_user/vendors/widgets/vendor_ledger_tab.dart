import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import '../controllers/vendor_detail_controller.dart';
import 'vendor_badges.dart';

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

/// The vendor's ledger entries — a settlement or a manually posted
/// payable/receivable, newest first per the backend's own ordering.
class VendorLedgerTab extends StatelessWidget {
  const VendorLedgerTab({
    super.key,
    required this.ledger,
    required this.onRetry,
    required this.onPrevious,
    required this.onNext,
  });

  final VendorSubPage<VendorLedgerEntryModel> ledger;
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
                ledger.totalPages == 0
                    ? 'No results'
                    : 'Page ${ledger.pageNumber} of ${ledger.totalPages} · '
                          '${ledger.totalElements} entr${ledger.totalElements == 1 ? 'y' : 'ies'}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            IconButton(
              onPressed: ledger.hasPreviousPage ? onPrevious : null,
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Previous page',
            ),
            IconButton(
              onPressed: ledger.hasNextPage ? onNext : null,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Next page',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (ledger.isLoading && ledger.items.isEmpty) {
      return const AppListSkeleton(itemCount: 4, hasThumbnail: false);
    }

    // Scrollable rather than returned bare — this tab's available height
    // is whatever's left in the TabBarView after the balance card/tab bar
    // above it, which can be a couple pixels short of what a compact
    // empty state naturally needs, overflowing instead of just scrolling
    // that sliver out of view.
    if (ledger.error != null && ledger.items.isEmpty) {
      return SingleChildScrollView(
        child: AppEmptyState.error(
          message: ledger.error,
          onAction: onRetry,
          compact: true,
        ),
      );
    }

    if (ledger.isEmpty) {
      return const SingleChildScrollView(
        child: AppEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No ledger entries yet',
          message: 'Settlements and manual postings will show up here.',
          compact: true,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      itemCount: ledger.items.length,
      separatorBuilder: (_, _) => const Divider(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        final entry = ledger.items[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatVendorMoney(entry.amount),
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
            VendorBalanceTypeBadge(type: entry.balanceType),
          ],
        );
      },
    );
  }
}
