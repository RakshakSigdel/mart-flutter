import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/core.dart';
import '../../../../data/models/models_user/stock_model.dart';

class DashboardStockCard extends StatelessWidget {
  const DashboardStockCard({super.key, required this.overview});
  final StockOverviewModel overview;

  @override
  Widget build(BuildContext context) {
    final attention = overview.needingAttention;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppColors.primaryDeep),
              SizedBox(width: AppSpacing.smMd),
              Expanded(child: Text('Stock health', style: AppTypography.title)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Current inventory · independent of the report period',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.xxl,
            runSpacing: AppSpacing.lg,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${overview.trackedProducts}',
                    style: AppTypography.displaySmall,
                  ),
                  const Text(
                    'Tracked products',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$attention',
                    style: AppTypography.displaySmall.copyWith(
                      color: attention > 0
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ),
                  const Text(
                    'Needing attention',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: attention > 0
                  ? AppColors.warningSoft
                  : AppColors.primarySoft,
              borderRadius: AppBorderRadius.radiusMD,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    overview.trackedProducts == 0
                        ? 'No products are being tracked yet.'
                        : attention > 0
                        ? '$attention ${attention == 1 ? 'product needs' : 'products need'} ordering or attention.'
                        : 'All tracked products are clear of stock alerts.',
                    style: AppTypography.bodySmall,
                  ),
                ),
                if (attention > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: () => context.go(Routes.stock),
                    child: const Text('Review'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
