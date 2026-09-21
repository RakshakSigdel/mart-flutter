import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/customer_model.dart';
import '../../../shared/widgets/section_ui.dart';
import '../controllers/customer_detail_controller.dart';
import '../widgets/customer_avatar.dart';
import '../widgets/customer_credit_panel.dart';
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
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gutter = AppBreakpoints.isPhone(constraints.maxWidth)
                ? AppSpacing.sm
                : AppSpacing.md;
            return SingleChildScrollView(
              padding: EdgeInsets.all(gutter),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CustomerIdentityPanel(customer: customer),
                      SizedBox(height: gutter),
                      if (outstanding != null)
                        CustomerCreditPanel(
                          outstanding: outstanding,
                          onSettle: () =>
                              _settle(context, customer, outstanding),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _settle(
    BuildContext context,
    CustomerModel customer,
    CustomerOutstandingModel outstanding,
  ) async {
    if (outstanding.totalOutstanding <= 0) return;
    final settlement = await showCustomerSettleDialog(
      context,
      customerId: customer.id,
      outstandingBalance: outstanding.totalOutstanding,
    );
    if (settlement == null || !context.mounted) return;

    final count = settlement.settledInvoices.length;
    final remaining = settlement.remainingBalance;
    AppSnackBar.success(
      context,
      'Rs. ${formatMoneyAmount(settlement.amountSettled)} applied to '
      '$count invoice${count == 1 ? '' : 's'}. '
      '${remaining <= 0 ? 'Account fully settled.' : 'Rs. ${formatMoneyAmount(remaining)} still due.'}',
    );
  }
}

/// Who the customer is: avatar, name, contact details and status.
class _CustomerIdentityPanel extends StatelessWidget {
  const _CustomerIdentityPanel({required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionPanelHeader(
            icon: Icons.person_rounded,
            eyebrow: 'CUSTOMER',
            subtitle: 'Profile and contact details',
            trailing: AppBadge(
              label: customer.active ? 'Active' : 'Inactive',
              tone: customer.active
                  ? AppBadgeTone.success
                  : AppBadgeTone.neutral,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CustomerAvatar(name: customer.name, size: 56),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            customer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            customer.phone?.isNotEmpty == true
                                ? customer.phone!
                                : 'No phone number on file',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xl,
                  runSpacing: AppSpacing.smMd,
                  children: [
                    _Info(label: 'Email', value: customer.email),
                    _Info(label: 'PAN', value: customer.panNumber),
                    _Info(
                      label: 'Credit limit',
                      value: 'Rs. ${formatMoneyAmount(customer.creditLimit)}',
                    ),
                    _Info(label: 'Address', value: customer.address),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasValue ? value! : 'Not set',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
              color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
