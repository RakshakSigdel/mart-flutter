import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/customer_model.dart';
import 'customer_row_actions.dart';

class CustomerListCard extends StatelessWidget {
  const CustomerListCard({
    super.key,
    required this.customer,
    required this.isBusy,
    required this.onAction,
  });

  final CustomerModel customer;
  final bool isBusy;
  final ValueChanged<CustomerRowAction> onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => onAction(CustomerRowAction.viewDetails),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: AppTypography.subtitle),
                    if (customer.phone != null)
                      Text(customer.phone!, style: AppTypography.caption),
                  ],
                ),
              ),
              CustomerRowActionsMenu(isBusy: isBusy, onSelected: onAction),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          customer.active
              ? const AppBadge(label: 'Active', tone: AppBadgeTone.success)
              : const AppBadge(label: 'Inactive', tone: AppBadgeTone.neutral),
          if ((customer.email != null && customer.email!.isNotEmpty) || (customer.address != null && customer.address!.isNotEmpty) || customer.creditLimit > 0) ...[
            const SizedBox(height: AppSpacing.smMd),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.smMd),
            if (customer.email != null && customer.email!.isNotEmpty)
              _InfoRow(icon: Icons.email_outlined, label: customer.email!),
            if (customer.address != null && customer.address!.isNotEmpty)
              _InfoRow(icon: Icons.location_on_outlined, label: customer.address!),
            if (customer.creditLimit > 0)
              _InfoRow(icon: Icons.account_balance_wallet_outlined, label: 'Limit: Rs. ${customer.creditLimit.toStringAsFixed(2)}'),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.iconInactive),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
