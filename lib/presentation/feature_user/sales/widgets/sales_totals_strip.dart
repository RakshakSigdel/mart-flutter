import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/sale_model.dart';

/// What was sold over the current filter window — bill count, net sales,
/// and what's still outstanding.
class SalesTotalsStrip extends StatelessWidget {
  const SalesTotalsStrip({
    super.key,
    required this.totals,
    required this.isLoading,
  });

  final SalesTotalsModel? totals;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final totals = this.totals;
    if (totals == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _StatCard(label: 'Bills', value: '${totals.billCount}'),
        ),
        const SizedBox(width: AppSpacing.smMd),
        Expanded(
          child: _StatCard(
            label: 'Net sales',
            value: formatMoneyAmount(totals.netSales),
          ),
        ),
        const SizedBox(width: AppSpacing.smMd),
        Expanded(
          child: _StatCard(
            label: 'Outstanding',
            value: formatMoneyAmount(totals.outstanding),
            tone: totals.outstanding > 0
                ? AppBadgeTone.warning
                : AppBadgeTone.success,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.tone = AppBadgeTone.neutral,
  });

  final String label;
  final String value;
  final AppBadgeTone tone;

  Color get _foreground => switch (tone) {
    AppBadgeTone.warning => AppColors.warning,
    AppBadgeTone.success => AppColors.success,
    _ => AppColors.primaryDeep,
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
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
          Text(value, style: AppTypography.title.copyWith(color: _foreground)),
        ],
      ),
    );
  }
}
