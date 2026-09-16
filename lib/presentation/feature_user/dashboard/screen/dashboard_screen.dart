import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/core.dart';
import '../../../../data/models/models_user/summary_report_model.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';
import '../../shell/controllers/sidebar_controller.dart';
import '../../shell/models/sidebar_menu_registry.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_report_card.dart';
import '../widgets/dashboard_quick_actions.dart';
import '../widgets/dashboard_section.dart';
import '../widgets/dashboard_stock_card.dart';

/// Composes the dashboard inside the shell; data and report rendering live
/// in their respective controller and widget files.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(dashboardControllerProvider);
    final sales = ref.watch(dashboardSalesProvider(range));
    final purchases = ref.watch(dashboardPurchasesProvider(range));
    final stock = ref.watch(dashboardStockProvider);
    final auth = ref.watch(authControllerProvider);
    final sidebar = ref.watch(sidebarControllerProvider);
    final name = auth is AuthAuthenticated ? auth.session.displayName : 'Staff';
    final loading = sales.isLoading || purchases.isLoading || stock.isLoading;
    final hasNoTrackedProducts = stock.when(
      data: (overview) => overview.trackedProducts == 0,
      loading: () => false,
      error: (_, _) => false,
    );
    final allowedPaths = <String>{
      for (final section in sidebar.sections)
        for (final entry in section.entries)
          ...switch (entry) {
            ResolvedSidebarLink() => [entry.path],
            ResolvedSidebarGroup() => [
              for (final child in entry.children) child.path,
            ],
          },
    };

    Future<void> refresh() async {
      // Start all three requests before awaiting. Errors are rendered in each
      // section; they must not escape into the pull-to-refresh callback.
      ref.invalidate(dashboardSalesProvider(range));
      ref.invalidate(dashboardPurchasesProvider(range));
      ref.invalidate(dashboardStockProvider);
      await Future.wait([
        ref
            .read(dashboardSalesProvider(range).future)
            .then<void>((_) {}, onError: (Object _, StackTrace __) {}),
        ref
            .read(dashboardPurchasesProvider(range).future)
            .then<void>((_) {}, onError: (Object _, StackTrace __) {}),
        ref
            .read(dashboardStockProvider.future)
            .then<void>((_) {}, onError: (Object _, StackTrace __) {}),
      ]);
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: AppBorderRadius.radiusXL,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUSINESS OVERVIEW',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryDeep,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.smMd),
                      Text(
                        'Welcome, $name',
                        style: AppTypography.heading.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Your sales, purchases and inventory at a glance.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DashboardQuickActions(allowedPaths: allowedPaths),
                const SizedBox(height: AppSpacing.lg),
                if (hasNoTrackedProducts) ...[
                  DashboardSetupCard(allowedPaths: allowedPaths),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AppDropdownField<ReportDateRange>(
                        label: 'Sales & purchases period',
                        value: range,
                        items: [
                          for (final item in ReportDateRange.values)
                            DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null)
                            ref
                                .read(dashboardControllerProvider.notifier)
                                .selectRange(value);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      tooltip: 'Refresh dashboard',
                      onPressed: loading ? null : refresh,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      DashboardSection(
                        title: 'Sales',
                        value: sales,
                        onRetry: () =>
                            ref.invalidate(dashboardSalesProvider(range)),
                        builder: (report) => DashboardReportCard(
                          title: 'Sales',
                          period: range.label,
                          report: report,
                          icon: Icons.receipt_long_outlined,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                      DashboardSection(
                        title: 'Purchases',
                        value: purchases,
                        onRetry: () =>
                            ref.invalidate(dashboardPurchasesProvider(range)),
                        builder: (report) => DashboardReportCard(
                          title: 'Purchases',
                          period: range.label,
                          report: report,
                          icon: Icons.shopping_cart_outlined,
                          color: AppColors.info,
                        ),
                      ),
                    ];
                    if (constraints.maxWidth < AppBreakpoints.tablet) {
                      return Column(
                        children: [
                          cards[0],
                          const SizedBox(height: AppSpacing.md),
                          cards[1],
                        ],
                      );
                    }
                    // Match the taller report's natural height without a
                    // fixed height that could clip additional payment rows.
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: cards[1]),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                DashboardSection(
                  title: 'Stock health',
                  value: stock,
                  onRetry: () => ref.invalidate(dashboardStockProvider),
                  builder: (overview) => DashboardStockCard(overview: overview),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
