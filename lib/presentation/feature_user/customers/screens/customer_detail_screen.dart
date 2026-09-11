import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../controllers/customer_detail_controller.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerDetailControllerProvider(customerId));
    final controller = ref.read(customerDetailControllerProvider(customerId).notifier);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const AppLoader(),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: AppEmptyState.error(
          message: state.error,
          onAction: controller.refresh,
        ),
      );
    }

    final customer = state.customer;
    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit customer',
            onPressed: () async {
              final result = await context.push<bool>(
                Routes.customerEdit(customer.id),
                extra: customer,
              );
              if (result == true) {
                controller.refresh();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Customer Info',
                          style: AppTypography.display,
                        ),
                      ),
                      customer.active
                          ? const AppBadge(label: 'Active', tone: AppBadgeTone.success)
                          : const AppBadge(label: 'Inactive', tone: AppBadgeTone.neutral),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _DetailRow(label: 'Name', value: customer.name),
                  _DetailRow(label: 'Phone', value: customer.phone ?? '—'),
                  _DetailRow(label: 'Email', value: customer.email ?? '—'),
                  _DetailRow(label: 'PAN', value: customer.panNumber ?? '—'),
                  _DetailRow(label: 'Address', value: customer.address ?? '—'),
                  _DetailRow(label: 'Credit Limit', value: 'Rs. ${customer.creditLimit.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
}
