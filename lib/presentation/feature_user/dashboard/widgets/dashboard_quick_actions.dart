import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';

/// The handful of jobs a shop worker normally needs to start from home.
/// These deliberately use verbs rather than the back-office nouns used in
/// the sidebar, so a new cashier does not need to understand the data model
/// before making a bill or receiving goods.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key, required this.allowedPaths});

  final Set<String> allowedPaths;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
        label: 'Make bill',
        nepaliLabel: 'बिल बनाउनुहोस्',
        detail: 'Cash, digital payment or credit',
        icon: Icons.point_of_sale_outlined,
        color: AppColors.primarySoft,
        path: Routes.pos,
        onTap: () => context.go(Routes.pos),
      ),
      _QuickAction(
        label: 'Receive stock',
        nepaliLabel: 'सामान भित्र्याउनुहोस्',
        detail: 'Record goods from a supplier',
        icon: Icons.add_business_outlined,
        color: AppColors.infoSoft,
        path: Routes.purchases,
        onTap: () => context.push(Routes.purchaseNew),
      ),
      _QuickAction(
        label: 'Customer credit',
        nepaliLabel: 'ग्राहक उधारो',
        detail: 'Check and collect outstanding dues',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.successSoft,
        path: Routes.customers,
        onTap: () => context.go(Routes.customers),
      ),
      _QuickAction(
        label: 'Check stock',
        nepaliLabel: 'स्टक हेर्नुहोस्',
        detail: 'Find low or out-of-stock products',
        icon: Icons.inventory_2_outlined,
        color: AppColors.warningSoft,
        path: Routes.stock,
        onTap: () => context.go(Routes.stock),
      ),
    ];

    final visibleActions = actions
        .where(
          (action) =>
              allowedPaths.contains(action.path) ||
              (action.path == Routes.pos && allowedPaths.contains(Routes.sales)),
        )
        .toList();
    if (visibleActions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Start a task', style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Choose what you need to do now.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.smMd),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= AppBreakpoints.tablet
                ? 4
                : constraints.maxWidth >= 500
                ? 2
                : 1;
            final width = (constraints.maxWidth -
                    (columns - 1) * AppSpacing.smMd) /
                columns;
            return Wrap(
              spacing: AppSpacing.smMd,
              runSpacing: AppSpacing.smMd,
              children: [
                for (final action in visibleActions)
                  SizedBox(width: width, child: action),
              ],
            );
          },
        ),
      ],
    );
  }
}

class DashboardSetupCard extends StatelessWidget {
  const DashboardSetupCard({super.key, required this.allowedPaths});

  final Set<String> allowedPaths;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.rocket_launch_outlined, color: AppColors.primaryDeep),
            SizedBox(width: AppSpacing.smMd),
            Expanded(child: Text('Set up your mart', style: AppTypography.title)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Complete these once. After that, daily work happens from the four shortcuts above.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        if (allowedPaths.contains(Routes.vendors))
          _SetupStep(
            number: '1',
            label: 'Add a supplier',
            onTap: () => context.go(Routes.vendors),
          ),
        if (allowedPaths.contains(Routes.inventoryProducts))
          _SetupStep(
            number: '2',
            label: 'Add products and their selling prices',
            onTap: () => context.push(Routes.inventoryProductNew),
          ),
        if (allowedPaths.contains(Routes.purchases))
          _SetupStep(
            number: '3',
            label: 'Record the first stock delivery',
            onTap: () => context.push(Routes.purchaseNew),
          ),
      ],
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.nepaliLabel,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.path,
  });

  final String label;
  final String nepaliLabel;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String path;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label, $nepaliLabel. $detail',
    child: Material(
      color: color,
      borderRadius: AppBorderRadius.radiusL,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.radiusL,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.textPrimary),
              const SizedBox(height: AppSpacing.md),
              Text(label, style: AppTypography.subtitle),
              const SizedBox(height: AppSpacing.xs),
              Text(nepaliLabel, style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail,
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.label,
    required this.onTap,
  });

  final String number;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.radiusMD,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.primarySoft,
              child: Text(number, style: AppTypography.labelSmall),
            ),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(child: Text(label, style: AppTypography.label)),
            const Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    ),
  );
}
