import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import '../controllers/vendor_detail_controller.dart';

/// A manual payable or receivable posted against the vendor — not tied to
/// a purchase, unlike the entries the purchasing flow posts on its own.
class VendorPostLedgerDialog extends ConsumerStatefulWidget {
  const VendorPostLedgerDialog({super.key, required this.vendorId});

  final int vendorId;

  @override
  ConsumerState<VendorPostLedgerDialog> createState() =>
      _VendorPostLedgerDialogState();
}

class _VendorPostLedgerDialogState
    extends ConsumerState<VendorPostLedgerDialog> {
  final _amountController = TextEditingController();
  VendorBalanceType? _balanceType = VendorBalanceType.payable;
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
    final type = _balanceType;
    if (type == null) {
      setState(() => _errorMessage = 'Select a balance type');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(vendorDetailControllerProvider(widget.vendorId).notifier)
          .postLedgerEntry(amount, type);
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
        const SizedBox(height: AppSpacing.smMd),
        AppDropdownField<VendorBalanceType?>(
          label: 'Balance type',
          value: _balanceType,
          enabled: !_submitting,
          items: [
            for (final type in VendorBalanceType.values)
              DropdownMenuItem(value: type, child: Text(type.label)),
          ],
          onChanged: (value) => setState(() => _balanceType = value),
        ),
        AppFormError(message: _errorMessage),
        const SizedBox(height: AppSpacing.xl),
        AppButton.expanded(
          label: 'Post entry',
          isLoading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

/// Opens [VendorPostLedgerDialog] as a centered dialog on wide screens, or
/// a bottom sheet on phone. Resolves `true` once the entry is posted.
Future<bool?> showVendorPostLedgerDialog(
  BuildContext context, {
  required int vendorId,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
  final content = VendorPostLedgerDialog(vendorId: vendorId);

  return isWide
      ? showAppDialog<bool>(
          context: context,
          title: 'Post ledger entry',
          content: content,
        )
      : showAppModal<bool>(
          context: context,
          title: 'Post ledger entry',
          content: content,
        );
}
