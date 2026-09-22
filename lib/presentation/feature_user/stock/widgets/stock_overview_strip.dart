import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/stock_model.dart';

/// Headline counts for the stock dashboard — tracked products and how many
/// need attention (low or out of stock).
class StockOverviewStrip extends StatelessWidget {
  const StockOverviewStrip({
    super.key,
    required this.overview,
    required this.isLoading,
  });

  final StockOverviewModel? overview;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final overview = this.overview;
    if (overview == null) {
      return isLoading
          ? const LinearProgressIndicator()
          : Text('Stock overview unavailable', style: AppTypography.caption);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = <Widget>[
          _StatCard(
            icon: Icons.inventory_2_outlined,
            label: 'Tracked products',
            value: overview.trackedProducts,
            tone: AppBadgeTone.neutral,
          ),
          _StatCard(
            icon: Icons.warning_amber_rounded,
            label: 'Needing attention',
            value: overview.needingAttention,
            tone: overview.needingAttention > 0
                ? AppBadgeTone.warning
                : AppBadgeTone.success,
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLoading) const LinearProgressIndicator(minHeight: 2),
            if (constraints.maxWidth < 520) ...[
              cards[0],
              const SizedBox(height: AppSpacing.smMd),
              cards[1],
            ] else
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: AppSpacing.smMd),
                  Expanded(child: cards[1]),
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
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final int value;
  final AppBadgeTone tone;

  Color get _foreground => switch (tone) {
    AppBadgeTone.warning => AppColors.warning,
    AppBadgeTone.success => AppColors.success,
    _ => AppColors.primaryDeep,
  };

  Color get _background => switch (tone) {
    AppBadgeTone.warning => AppColors.warningSoft,
    AppBadgeTone.success => AppColors.successSoft,
    _ => AppColors.primarySoft,
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: _foreground),
          ),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: AppTypography.title),
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
