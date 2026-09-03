import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import 'vendor_badges.dart';

/// Where the vendor's account stands right now, plus the two actions that
/// change it — kept on the vendor's one detail page rather than a route of
/// its own, same reasoning as the ledger/history tabs next to it.
class VendorBalanceCard extends StatelessWidget {
  const VendorBalanceCard({
    super.key,
    required this.balance,
    required this.isLoading,
    required this.onRecordSettlement,
    required this.onPostLedgerEntry,
  });

  final VendorBalanceModel? balance;
  final bool isLoading;
  final VoidCallback onRecordSettlement;
  final VoidCallback onPostLedgerEntry;

  @override
  Widget build(BuildContext context) {
    final balance = this.balance;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Balance', style: AppTypography.subtitle)),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          if (balance == null && !isLoading)
            Text(
              'Balance unavailable.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            )
          else if (balance != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  formatVendorMoney(balance.outstanding),
                  style: AppTypography.heading,
                ),
                const SizedBox(width: AppSpacing.sm),
                VendorBalanceTypeBadge(type: balance.balanceType),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _Stat(label: 'Payable', value: balance.totalPayable),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Receivable',
                    value: balance.totalReceivable,
                  ),
                ),
                Expanded(
                  child: _Stat(label: 'Settled', value: balance.totalSettled),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Post ledger entry',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  leading: const Icon(Icons.receipt_long_outlined, size: 16),
                  onPressed: onPostLedgerEntry,
                ),
              ),
              const SizedBox(width: AppSpacing.smMd),
              Expanded(
                child: AppButton(
                  label: 'Record settlement',
                  size: AppButtonSize.sm,
                  leading: const Icon(Icons.payments_outlined, size: 16),
                  onPressed: onRecordSettlement,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.eyebrow.copyWith(
            letterSpacing: 0.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(formatVendorMoney(value), style: AppTypography.subtitle),
      ],
    );
  }
}
