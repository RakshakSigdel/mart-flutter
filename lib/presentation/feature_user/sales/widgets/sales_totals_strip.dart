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
    if (totals == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.smMd),
        child: isLoading
            ? const LinearProgressIndicator()
            : Text('Sales overview unavailable', style: AppTypography.caption),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 480
            ? constraints.maxWidth
            : (constraints.maxWidth - 24) / 3;
        return Column(
          children: [
            if (isLoading) const LinearProgressIndicator(minHeight: 2),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _StatCard(
                    label: 'Bills',
                    value: '${totals.billCount}',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _StatCard(
                    label: 'Net sales',
                    value: formatMoneyAmount(totals.netSales),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _StatCard(
                    label: 'Outstanding',
                    value: formatMoneyAmount(totals.outstanding),
                    tone: totals.outstanding > 0
                        ? AppBadgeTone.warning
                        : AppBadgeTone.success,
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.title.copyWith(color: _foreground),
            ),
          ),
        ],
      ),
    );
  }
}
