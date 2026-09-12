import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/customer_model.dart';
import '../controllers/customer_detail_controller.dart';
import '../widgets/customer_settle_dialog.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerDetailControllerProvider(customerId));
    final controller = ref.read(
      customerDetailControllerProvider(customerId).notifier,
    );

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const AppLoader(),
      );
    }
    if (state.error != null || state.customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: AppEmptyState.error(
          message: state.error ?? 'Customer not found.',
          onAction: controller.refresh,
        ),
      );
    }

    final customer = state.customer!;
    final outstanding = state.outstanding;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh customer balance',
            onPressed: controller.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit customer',
            onPressed: () async {
              final changed = await context.push<bool>(
                Routes.customerEdit(customer.id),
                extra: customer,
              );
              if (changed == true) controller.refresh();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CustomerInfoCard(customer: customer),
                const SizedBox(height: AppSpacing.md),
                if (outstanding != null)
                  _CreditSection(
                    outstanding: outstanding,
                    onSettle: () async {
                      if (outstanding.totalOutstanding <= 0) return;
                      final settlement = await showCustomerSettleDialog(
                        context,
                        customerId: customer.id,
                        outstandingBalance: outstanding.totalOutstanding,
                      );
                      if (settlement != null && context.mounted) {
                        AppSnackBar.success(
                          context,
                          '${formatMoneyAmount(settlement.amountSettled)} applied to '
                          '${settlement.settledInvoices.length} invoice${settlement.settledInvoices.length == 1 ? '' : 's'}.',
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerInfoCard extends StatelessWidget {
  const _CustomerInfoCard({required this.customer});
  final CustomerModel customer;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Customer information', style: AppTypography.title),
            ),
            AppBadge(
              label: customer.active ? 'Active' : 'Inactive',
              tone: customer.active
                  ? AppBadgeTone.success
                  : AppBadgeTone.neutral,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.xxl,
          runSpacing: AppSpacing.md,
          children: [
            _Info(label: 'Phone', value: customer.phone ?? '—'),
            _Info(label: 'Email', value: customer.email ?? '—'),
            _Info(label: 'PAN', value: customer.panNumber ?? '—'),
            _Info(
              label: 'Credit limit',
              value: formatMoneyAmount(customer.creditLimit),
            ),
            _Info(label: 'Address', value: customer.address ?? '—'),
          ],
        ),
      ],
    ),
  );
}

class _CreditSection extends StatelessWidget {
  const _CreditSection({required this.outstanding, required this.onSettle});
  final CustomerOutstandingModel outstanding;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Credit account', style: AppTypography.title),
            ),
            AppButton(
              label: 'Settle balance',
              size: AppButtonSize.sm,
              leading: const Icon(Icons.payments_outlined, size: 18),
              onPressed: outstanding.totalOutstanding > 0 ? onSettle : null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.xxl,
          runSpacing: AppSpacing.md,
          children: [
            _CreditMetric(
              label: 'Outstanding',
              value: formatMoneyAmount(outstanding.totalOutstanding),
              color: outstanding.totalOutstanding > 0
                  ? AppColors.warning
                  : AppColors.success,
            ),
            _CreditMetric(
              label: 'Available credit',
              value: formatMoneyAmount(outstanding.availableCredit),
            ),
            _CreditMetric(
              label: 'Credit limit',
              value: formatMoneyAmount(outstanding.creditLimit),
            ),
            _CreditMetric(
              label: 'Unpaid invoices',
              value: '${outstanding.unpaidInvoiceCount}',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.md),
        Text('Unpaid invoices (oldest first)', style: AppTypography.subtitle),
        const SizedBox(height: AppSpacing.smMd),
        if (outstanding.unpaidSales.isEmpty)
          const AppEmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'No outstanding invoices',
            message: 'This customer has no unpaid credit balance.',
          )
        else
          for (final sale in outstanding.unpaidSales) _InvoiceRow(sale: sale),
      ],
    ),
  );
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.sale});
  final CustomerOutstandingSale sale;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    padding: const EdgeInsets.all(AppSpacing.smMd),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppBorderRadius.radiusMD,
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sale.invoiceNumber, style: AppTypography.subtitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                sale.soldAt == null
                    ? 'Date unavailable'
                    : '${sale.soldAt!.day}/${sale.soldAt!.month}/${sale.soldAt!.year}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatMoneyAmount(sale.dueAmount),
              style: AppTypography.subtitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Due of ${formatMoneyAmount(sale.netTotal)}',
              style: AppTypography.caption,
            ),
          ],
        ),
      ],
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTypography.body),
      ],
    ),
  );
}

class _CreditMetric extends StatelessWidget {
  const _CreditMetric({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTypography.bodySmall),
      const SizedBox(height: AppSpacing.xs),
      Text(value, style: AppTypography.title.copyWith(color: color)),
    ],
  );
}
