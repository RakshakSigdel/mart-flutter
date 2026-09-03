import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../controllers/vendor_detail_controller.dart';

/// A payment made to the vendor. Reduces what's payable — the backend
/// infers the ledger side, so this is just an amount.
class VendorRecordSettlementDialog extends ConsumerStatefulWidget {
  const VendorRecordSettlementDialog({super.key, required this.vendorId});

  final int vendorId;

  @override
  ConsumerState<VendorRecordSettlementDialog> createState() =>
      _VendorRecordSettlementDialogState();
}

class _VendorRecordSettlementDialogState
    extends ConsumerState<VendorRecordSettlementDialog> {
  final _amountController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter a positive amount');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(vendorDetailControllerProvider(widget.vendorId).notifier)
          .recordSettlement(amount);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      // DIAGNOSTIC (per user request — leave in place until told to
      // remove it): belt-and-suspenders — the controller always throws
      // ApiException, but if that ever changes, this dialog still shows
      // something instead of silently staying open.
      if (mounted) setState(() => _errorMessage = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: _amountController,
          label: 'Amount',
          hint: 'e.g. 5000',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          enabled: !_submitting,
          autofocus: true,
        ),
        AppFormError(message: _errorMessage),
        const SizedBox(height: AppSpacing.xl),
        AppButton.expanded(
          label: 'Record settlement',
          isLoading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

/// Opens [VendorRecordSettlementDialog] as a centered dialog on wide
/// screens, or a bottom sheet on phone. Resolves `true` once the
/// settlement is recorded.
Future<bool?> showVendorRecordSettlementDialog(
  BuildContext context, {
  required int vendorId,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
  final content = VendorRecordSettlementDialog(vendorId: vendorId);

  return isWide
      ? showAppDialog<bool>(
          context: context,
          title: 'Record settlement',
          content: content,
        )
      : showAppModal<bool>(
          context: context,
          title: 'Record settlement',
          content: content,
        );
}
