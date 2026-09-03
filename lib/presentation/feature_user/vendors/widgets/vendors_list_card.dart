import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import 'vendor_row_actions.dart';

/// Phone layout — one card per vendor, stacked in a list.
class VendorListCard extends StatelessWidget {
  const VendorListCard({
    super.key,
    required this.vendor,
    required this.isBusy,
    required this.onAction,
  });

  final VendorModel vendor;
  final bool isBusy;
  final ValueChanged<VendorRowAction> onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => onAction(VendorRowAction.viewDetails),
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
                    Text(vendor.name, style: AppTypography.subtitle),
                    if (vendor.contactNumber != null)
                      Text(vendor.contactNumber!, style: AppTypography.caption),
                  ],
                ),
              ),
              VendorRowActionsMenu(isBusy: isBusy, onSelected: onAction),
            ],
          ),
          if (vendor.address != null && vendor.address!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.smMd),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.smMd),
            _InfoRow(icon: Icons.location_on_outlined, label: vendor.address!),
          ],
          if (vendor.panNumber != null && vendor.panNumber!.isNotEmpty)
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'PAN: ${vendor.panNumber}',
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
