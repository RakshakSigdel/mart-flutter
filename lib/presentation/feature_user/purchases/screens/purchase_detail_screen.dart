import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/purchase_model.dart';
import '../controllers/purchase_detail_controller.dart';

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

/// One purchase's detail page: the bill's own record, the vendor it was
/// bought from, and every line item — read-only, since a recorded purchase
/// is immutable (the backend exposes no edit/remove for this resource).
class PurchaseDetailScreen extends ConsumerWidget {
  const PurchaseDetailScreen({super.key, required this.purchaseId});

  final int purchaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purchaseDetailControllerProvider(purchaseId));
    final purchase = state.purchase;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(purchase?.billNumber ?? 'Purchase'),
      ),
      body: _buildBody(ref, state, purchase),
    );
  }

  Widget _buildBody(
    WidgetRef ref,
    PurchaseDetailState state,
    PurchaseDetailModel? purchase,
  ) {
    if (state.isLoading && purchase == null) {
      return const AppLoader();
    }

    if (state.error != null && purchase == null) {
      return AppEmptyState.error(
        message: state.error,
        onAction: () => ref
            .read(purchaseDetailControllerProvider(purchaseId).notifier)
            .refresh(),
      );
    }

    if (purchase == null) return const SizedBox.shrink();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(purchase.billNumber, style: AppTypography.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formatDate(purchase.purchaseDate),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.smMd),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.smMd),
                    _InfoRow(
                      label: 'Vendor',
                      value: purchase.vendorName ?? '—',
                    ),
                    if (purchase.vendorPanNumber != null)
                      _InfoRow(
                        label: 'Vendor PAN',
                        value: purchase.vendorPanNumber!,
                      ),
                    if (purchase.vendorAddress != null)
                      _InfoRow(
                        label: 'Vendor address',
                        value: purchase.vendorAddress!,
                      ),
                    _InfoRow(
                      label: 'Payment method',
                      value: formatPaymentMethod(purchase.paymentMethod),
                    ),
                    _InfoRow(
                      label: 'Tax scheme',
                      value: formatTaxScheme(purchase.taxScheme),
                    ),
                    if (purchase.remark != null && purchase.remark!.isNotEmpty)
                      _InfoRow(label: 'Remark', value: purchase.remark!),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items', style: AppTypography.subtitle),
                    const SizedBox(height: AppSpacing.smMd),
                    if (purchase.items.isEmpty)
                      Text(
                        'No items on this purchase.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      )
                    else
                      for (var i = 0; i < purchase.items.length; i++) ...[
                        if (i > 0) const Divider(height: AppSpacing.lg),
                        _ItemRow(item: purchase.items[i]),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TotalRow(label: 'Subtotal', value: purchase.subTotal),
                    _TotalRow(
                      label: 'Discount',
                      value: -purchase.discountAmount,
                    ),
                    _TotalRow(
                      label: 'Taxable amount',
                      value: purchase.taxableAmount,
                    ),
                    _TotalRow(label: 'VAT', value: purchase.vatAmount),
                    const Divider(height: AppSpacing.lg),
                    _TotalRow(
                      label: 'Net total',
                      value: purchase.netTotal,
                      emphasize: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final PurchaseItemModel item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName ?? 'Product #${item.productId}',
                style: AppTypography.subtitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${formatMoneyAmount(item.quantity)}'
                '${item.purchaseUnitSymbol != null ? ' ${item.purchaseUnitSymbol}' : ''}'
                ' × ${formatMoneyAmount(item.rate)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Text(formatMoneyAmount(item.lineTotal), style: AppTypography.subtitle),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize ? AppTypography.title : AppTypography.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasize
                  ? style
                  : style.copyWith(color: AppColors.textMuted),
            ),
          ),
          Text(formatMoneyAmount(value), style: style),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
