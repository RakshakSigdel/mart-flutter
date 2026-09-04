import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../controllers/sale_detail_controller.dart';

/// Takes a payment against an unpaid or part-paid bill.
class SaleTakePaymentDialog extends ConsumerStatefulWidget {
  const SaleTakePaymentDialog({
    super.key,
    required this.saleId,
    required this.dueAmount,
  });

  final int saleId;

  /// Pre-fills the amount field with the full outstanding balance — the
  /// common case is paying it off in one go.
  final double dueAmount;

  @override
  ConsumerState<SaleTakePaymentDialog> createState() =>
      _SaleTakePaymentDialogState();
}

class _SaleTakePaymentDialogState extends ConsumerState<SaleTakePaymentDialog> {
  late final _amountController = TextEditingController(
    text: widget.dueAmount > 0 ? formatMoneyAmount(widget.dueAmount) : '',
  );
  PaymentMethod _paymentMethod = PaymentMethod.cash;
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
          .read(saleDetailControllerProvider(widget.saleId).notifier)
          .recordPayment(amount, _paymentMethod);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          enabled: !_submitting,
          autofocus: true,
        ),
        const SizedBox(height: AppSpacing.smMd),
        AppDropdownField<PaymentMethod>(
          label: 'Payment method',
          value: _paymentMethod,
          enabled: !_submitting,
          items: [
            for (final method in PaymentMethod.values)
              DropdownMenuItem(value: method, child: Text(method.label)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _paymentMethod = value);
          },
        ),
        AppFormError(message: _errorMessage),
        const SizedBox(height: AppSpacing.xl),
        AppButton.expanded(
          label: 'Record payment',
          isLoading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

/// Opens [SaleTakePaymentDialog] as a centered dialog on wide screens, or a
/// bottom sheet on phone. Resolves `true` once the payment is recorded.
Future<bool?> showSaleTakePaymentDialog(
  BuildContext context, {
  required int saleId,
  required double dueAmount,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
  final content = SaleTakePaymentDialog(saleId: saleId, dueAmount: dueAmount);

  return isWide
      ? showAppDialog<bool>(
          context: context,
          title: 'Take payment',
          content: content,
        )
      : showAppModal<bool>(
          context: context,
          title: 'Take payment',
          content: content,
        );
}
