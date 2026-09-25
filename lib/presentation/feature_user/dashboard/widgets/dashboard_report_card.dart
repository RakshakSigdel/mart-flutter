import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/summary_report_model.dart';

class DashboardReportCard extends StatelessWidget {
  const DashboardReportCard({
    super.key,
    required this.title,
    required this.period,
    required this.report,
    required this.icon,
    required this.color,
  });
  final String title;
  final String period;
  final SummaryReportModel report;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final returns = report.returns;
    final paymentTotal = report.paymentTypeTotals.fold<double>(
      0,
      (sum, item) => sum + item.netTotal.abs(),
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.smMd),
              Expanded(child: Text(title, style: AppTypography.title)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(period, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Text(
            returns == null
                ? 'Net ${title.toLowerCase()}'
                : 'Net ${returns.subject.toLowerCase()} after returns',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatMoneyAmount(returns?.netAfterReturns ?? report.netTotal),
            style: AppTypography.displaySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            children: [
              _Metric(label: 'Transactions', value: '${report.count}'),
              _Metric(
                label: returns == null ? 'VAT amount' : 'VAT after returns',
                value: formatMoneyAmount(
                  returns?.vatAmountAfterReturns ?? report.vatAmount,
                ),
              ),
              _Metric(
                label: returns == null
                    ? 'Average transaction'
                    : 'Average before returns',
                value: formatMoneyAmount(
                  report.count == 0 ? 0 : report.netTotal / report.count,
                ),
              ),
            ],
          ),
          if (returns != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(color: AppColors.border),
            ),
            Material(
              color: Colors.transparent,
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
                title: Text(
                  '${returns.subject} returns',
                  style: AppTypography.subtitle,
                ),
                subtitle: Text(
                  '${returns.count} notes · ${formatMoneyAmount(returns.amount)}',
                  style: AppTypography.bodySmall,
                ),
                children: [
                  Wrap(
                    spacing: AppSpacing.xl,
                    runSpacing: AppSpacing.md,
                    children: [
                      _Metric(
                        label: '${returns.subject} before returns',
                        value: formatMoneyAmount(report.netTotal),
                      ),
                      _Metric(
                        label: 'Return VAT',
                        value: formatMoneyAmount(returns.vatAmount),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(color: AppColors.border),
          ),
          const Text('By payment method', style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.md),
          if (report.paymentTypeTotals.isEmpty)
            const Text(
              'No payment breakdown for this period.',
              style: AppTypography.bodySmall,
            ),
          for (final item in report.paymentTypeTotals)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          formatSnakeCaseLabel(item.paymentMethod),
                          style: AppTypography.bodySmall,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          formatMoneyAmount(item.netTotal),
                          style: AppTypography.subtitle,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LinearProgressIndicator(
                    value: paymentTotal == 0
                        ? 0
                        : (item.netTotal.abs() / paymentTotal).clamp(0, 1),
                    color: color,
                    backgroundColor: AppColors.surfaceSunken,
                    borderRadius: AppBorderRadius.radiusMD,
                    semanticsLabel:
                        '${formatSnakeCaseLabel(item.paymentMethod)} share of reported payment totals',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTypography.bodySmall),
      const SizedBox(height: AppSpacing.xs),
      Text(value, style: AppTypography.subtitle),
    ],
  );
}
