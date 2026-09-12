import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/customer_model.dart';
import '../controllers/customer_detail_controller.dart';

class CustomerSettleDialog extends ConsumerStatefulWidget {
  const CustomerSettleDialog({
    super.key,
    required this.customerId,
    required this.outstandingBalance,
  });

  final int customerId;
  final double outstandingBalance;

  @override
  ConsumerState<CustomerSettleDialog> createState() =>
      _CustomerSettleDialogState();
}

class _CustomerSettleDialogState extends ConsumerState<CustomerSettleDialog> {
  late final _amountController = TextEditingController(
    text: formatMoneyAmount(widget.outstandingBalance),
  );
  final _remarkController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter a positive payment amount.');
      return;
    }
    if (amount > widget.outstandingBalance) {
      setState(
        () => _errorMessage = 'Payment cannot exceed the outstanding balance.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final settlement = await ref
          .read(customerDetailControllerProvider(widget.customerId).notifier)
          .settle(
            SettleCustomerCreditRequest(
              amount: amount,
              paymentMethod: _paymentMethod,
              remark: _remarkController.text.trim().isEmpty
                  ? null
                  : _remarkController.text.trim(),
            ),
          );
      if (mounted) Navigator.of(context).pop(settlement);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted)
        setState(() => _errorMessage = 'Could not settle this balance.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Payments apply to the oldest unpaid invoices first.',
        style: AppTypography.bodySmall,
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        controller: _amountController,
        label: 'Payment amount',
        enabled: !_submitting,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
      ),
      const SizedBox(height: AppSpacing.smMd),
      AppDropdownField<PaymentMethod>(
        label: 'Payment method',
        value: _paymentMethod,
        enabled: !_submitting,
        items: [
          for (final method in PaymentMethod.values.where(
            (method) => method != PaymentMethod.credit,
          ))
            DropdownMenuItem(value: method, child: Text(method.label)),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _paymentMethod = value);
        },
      ),
      const SizedBox(height: AppSpacing.smMd),
      AppTextField(
        controller: _remarkController,
        label: 'Remark (optional)',
        enabled: !_submitting,
        maxLines: 2,
      ),
      AppFormError(message: _errorMessage),
      const SizedBox(height: AppSpacing.lg),
      AppButton.expanded(
        label: 'Settle balance',
        isLoading: _submitting,
        onPressed: _submitting ? null : _submit,
      ),
    ],
  );
}

Future<CustomerSettlementModel?> showCustomerSettleDialog(
  BuildContext context, {
  required int customerId,
  required double outstandingBalance,
}) {
  final content = CustomerSettleDialog(
    customerId: customerId,
    outstandingBalance: outstandingBalance,
  );
  return MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet
      ? showAppDialog<CustomerSettlementModel>(
          context: context,
          title: 'Settle credit balance',
          content: content,
        )
      : showAppModal<CustomerSettlementModel>(
          context: context,
          title: 'Settle credit balance',
          content: content,
        );
}
