import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/page_response.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import '../../../../providers/providers_user/vendor_provider.dart';

/// A mart-wide purchase trail. Vendor detail already presents the scoped
/// history; this dialog is for an accountant who needs to browse every
/// vendor's records from one place.
class AllVendorHistoryDialog extends ConsumerStatefulWidget {
  const AllVendorHistoryDialog({super.key});

  @override
  ConsumerState<AllVendorHistoryDialog> createState() =>
      _AllVendorHistoryDialogState();
}

class _AllVendorHistoryDialogState
    extends ConsumerState<AllVendorHistoryDialog> {
  PageResponse<VendorHistoryModel>? _page;
  String? _error;
  bool _loading = true;
  int _pageNumber = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load([int? page]) async {
    final requestedPage = page ?? _pageNumber;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(vendorRemoteDataSourceProvider)
          .allHistory(page: requestedPage);
      if (!mounted) return;
      setState(() {
        _page = result;
        _pageNumber = requestedPage;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.message;
        });
    }
  }

  Future<void> _openEntry(VendorHistoryModel entry) async {
    try {
      final detail = await ref
          .read(vendorRemoteDataSourceProvider)
          .historyById(entry.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Purchase history entry'),
          content: Text(
            '${detail.vendorName ?? 'Vendor #${detail.vendorId}'}\n'
            'Purchase #${detail.purchaseId}\n'
            'Recorded ${_formatDate(detail.createdAt)}',
          ),
          actions: [
            AppButton(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('All vendor purchase history'),
    content: SizedBox(width: 640, height: 440, child: _buildContent()),
    actions: [
      if (_page != null) ...[
        IconButton(
          tooltip: 'Previous page',
          onPressed: _pageNumber > 1 && !_loading
              ? () => _load(_pageNumber - 1)
              : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text('Page $_pageNumber of ${_page!.totalPages}'),
        IconButton(
          tooltip: 'Next page',
          onPressed: !_page!.last && !_loading
              ? () => _load(_pageNumber + 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
      AppButton(
        label: 'Close',
        variant: AppButtonVariant.secondary,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  );

  Widget _buildContent() {
    if (_loading && _page == null) return const AppLoader();
    if (_error != null) {
      return AppEmptyState.error(
        message: _error!,
        onAction: _load,
        compact: true,
      );
    }
    final entries = _page?.content ?? const <VendorHistoryModel>[];
    if (entries.isEmpty) {
      return const AppEmptyState(
        icon: Icons.history_rounded,
        title: 'No purchase history',
        message: 'Vendor purchases will appear here.',
        compact: true,
      );
    }
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(entry.vendorName ?? 'Vendor #${entry.vendorId}'),
          subtitle: Text(
            'Purchase #${entry.purchaseId} · ${_formatDate(entry.createdAt)}',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _openEntry(entry),
        );
      },
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}

Future<void> showAllVendorHistoryDialog(BuildContext context) =>
    showDialog<void>(
      context: context,
      builder: (_) => const AllVendorHistoryDialog(),
    );
