import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import '../controllers/vendor_detail_controller.dart';
import '../widgets/vendor_balance_card.dart';
import '../widgets/vendor_history_tab.dart';
import '../widgets/vendor_ledger_tab.dart';
import '../widgets/vendor_post_ledger_dialog.dart';
import '../widgets/vendor_record_settlement_dialog.dart';

/// One vendor's detail page: its record, running balance, and ledger/
/// purchase-history — everything `/vendors/{id}` and its sub-resources
/// expose about that one vendor, all on this one screen.
///
/// A vendor has exactly one of each of these (one record, one balance),
/// so — unlike the product/category detail screens, which drill into
/// several independent sub-resources — there's nowhere else to navigate
/// to from here. Ledger and history are tabs rather than separate pushed
/// screens for the same reason: no new "place" to be, just more of this
/// one vendor.
class VendorDetailScreen extends ConsumerWidget {
  const VendorDetailScreen({super.key, required this.vendorId});

  final int vendorId;

  VendorDetailController _notifier(WidgetRef ref) =>
      ref.read(vendorDetailControllerProvider(vendorId).notifier);

  Future<void> _editVendor(
    BuildContext context,
    WidgetRef ref,
    VendorModel vendor,
  ) async {
    final result = await context.push<bool>(
      Routes.vendorEdit(vendorId),
      extra: vendor,
    );
    if (result == true) {
      if (context.mounted) AppSnackBar.success(context, 'Vendor updated.');
      _notifier(ref).refresh();
    }
  }

  Future<void> _recordSettlement(BuildContext context, WidgetRef ref) async {
    final result = await showVendorRecordSettlementDialog(
      context,
      vendorId: vendorId,
    );
    if (result == true && context.mounted) {
      AppSnackBar.success(context, 'Settlement recorded.');
    }
  }

  Future<void> _postLedgerEntry(BuildContext context, WidgetRef ref) async {
    final result = await showVendorPostLedgerDialog(
      context,
      vendorId: vendorId,
    );
    if (result == true && context.mounted) {
      AppSnackBar.success(context, 'Ledger entry posted.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorDetailControllerProvider(vendorId));
    final vendor = state.vendor;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(vendor?.name ?? 'Vendor'),
        actions: [
          if (vendor != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit vendor',
              onPressed: () => _editVendor(context, ref, vendor),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: _buildBody(context, ref, state, vendor),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    VendorDetailState state,
    VendorModel? vendor,
  ) {
    if (state.isLoading && vendor == null) {
      return const AppLoader();
    }

    if (state.error != null && vendor == null) {
      return AppEmptyState.error(
        message: state.error,
        onAction: () => _notifier(ref).refresh(),
      );
    }

    if (vendor == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 2,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _VendorHeaderCard(vendor: vendor),
                const SizedBox(height: AppSpacing.md),
                VendorBalanceCard(
                  balance: state.balance,
                  isLoading: state.isBalanceLoading,
                  onRecordSettlement: () => _recordSettlement(context, ref),
                  onPostLedgerEntry: () => _postLedgerEntry(context, ref),
                ),
                const SizedBox(height: AppSpacing.md),
                const TabBar(
                  tabs: [
                    Tab(text: 'Ledger'),
                    Tab(text: 'History'),
                  ],
                  isScrollable: false,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: VendorLedgerTab(
                          ledger: state.ledger,
                          onRetry: () => _notifier(
                            ref,
                          ).loadLedger(page: state.ledger.pageNumber),
                          onPrevious: () => _notifier(ref).previousLedgerPage(),
                          onNext: () => _notifier(ref).nextLedgerPage(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: VendorHistoryTab(
                          history: state.history,
                          onRetry: () => _notifier(
                            ref,
                          ).loadHistory(page: state.history.pageNumber),
                          onPrevious: () =>
                              _notifier(ref).previousHistoryPage(),
                          onNext: () => _notifier(ref).nextHistoryPage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VendorHeaderCard extends StatelessWidget {
  const _VendorHeaderCard({required this.vendor});

  final VendorModel vendor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vendor.name, style: AppTypography.title),
          const SizedBox(height: AppSpacing.smMd),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.smMd),
          _InfoRow(
            label: 'Contact number',
            value: vendor.contactNumber?.isNotEmpty == true
                ? vendor.contactNumber!
                : '—',
          ),
          _InfoRow(
            label: 'PAN number',
            value: vendor.panNumber?.isNotEmpty == true
                ? vendor.panNumber!
                : '—',
          ),
          _InfoRow(
            label: 'Address',
            value: vendor.address?.isNotEmpty == true ? vendor.address! : '—',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
