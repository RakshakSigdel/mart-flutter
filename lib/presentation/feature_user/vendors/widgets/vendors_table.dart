import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import 'vendor_row_actions.dart';

/// Tablet/desktop layout — one row per vendor in a scrollable table.
class VendorsTable extends StatelessWidget {
  const VendorsTable({
    super.key,
    required this.vendors,
    required this.busyIds,
    required this.onAction,
  });

  final List<VendorModel> vendors;
  final Set<int> busyIds;
  final void Function(VendorModel vendor, VendorRowAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTypography.eyebrow.copyWith(letterSpacing: 0.4);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: math.max(800, constraints.maxWidth),
          ),
          child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(AppColors.surface),
            headingTextStyle: headerStyle,
            columnSpacing: AppSpacing.lg,
            columns: const [
              DataColumn(label: Text('NAME')),
              DataColumn(label: Text('ADDRESS')),
              DataColumn(label: Text('CONTACT')),
              DataColumn(label: Text('PAN')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final vendor in vendors)
                DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          vendor.name,
                          style: AppTypography.subtitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onTap: () =>
                          onAction(vendor, VendorRowAction.viewDetails),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Text(
                          vendor.address?.isNotEmpty == true
                              ? vendor.address!
                              : '—',
                          style: AppTypography.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        vendor.contactNumber?.isNotEmpty == true
                            ? vendor.contactNumber!
                            : '—',
                      ),
                    ),
                    DataCell(
                      Text(
                        vendor.panNumber?.isNotEmpty == true
                            ? vendor.panNumber!
                            : '—',
                      ),
                    ),
                    DataCell(
                      VendorRowActionsMenu(
                        isBusy: busyIds.contains(vendor.id),
                        onSelected: (action) => onAction(vendor, action),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
