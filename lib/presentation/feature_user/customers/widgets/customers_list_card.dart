import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/customer_model.dart';
import 'customer_avatar.dart';
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomerAvatar(name: customer.name, size: 42),
              const SizedBox(width: AppSpacing.smMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.subtitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.phone?.isNotEmpty == true
                          ? customer.phone!
                          : 'No phone number',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              CustomerRowActionsMenu(isBusy: isBusy, onSelected: onAction),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              customer.active
                  ? const AppBadge(label: 'Active', tone: AppBadgeTone.success)
                  : const AppBadge(
                      label: 'Inactive',
                      tone: AppBadgeTone.neutral,
                    ),
              if (customer.creditLimit > 0)
                _CreditChip(limit: customer.creditLimit),
            ],
          ),
          if (_hasContactDetails) ...[
            const SizedBox(height: AppSpacing.smMd),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            if (customer.email?.isNotEmpty == true)
              _InfoRow(
                icon: Icons.mail_outline_rounded,
                label: customer.email!,
              ),
            if (customer.address?.isNotEmpty == true)
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: customer.address!,
              ),
          ],
        ],
      ),
    );
  }

  bool get _hasContactDetails =>
      customer.email?.isNotEmpty == true ||
      customer.address?.isNotEmpty == true;
}

class _CreditChip extends StatelessWidget {
  const _CreditChip({required this.limit});

  final double limit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppBorderRadius.radiusFull,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 13,
            color: AppColors.primaryDeep,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Limit Rs. ${formatMoneyAmount(limit)}',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDeep,
            ),
          ),
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
          Icon(icon, size: 15, color: AppColors.iconInactive),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              style: AppTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
