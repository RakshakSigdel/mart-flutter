import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/customer_model.dart';
import '../../../shared/widgets/section_ui.dart';
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

  /// The typed amount, or null while it is blank/unparseable.
  double? get _enteredAmount => double.tryParse(_amountController.text.trim());

  double get _remainingAfter {
    final remaining = widget.outstandingBalance - (_enteredAmount ?? 0);
    return remaining < 0 ? 0 : remaining;
  }

  bool get _isValid {
    final amount = _enteredAmount;
    return amount != null &&
        amount > 0 &&
        amount <= widget.outstandingBalance + 0.001;
  }

  void _setAmount(double value) {
    _amountController.text = formatMoneyAmount(value);
    setState(() => _errorMessage = null);
  }

  Future<void> _submit() async {
    final amount = _enteredAmount;
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter a positive payment amount.');
      return;
    }
    if (amount > widget.outstandingBalance + 0.001) {
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
      if (mounted) {
        setState(() => _errorMessage = 'Could not settle this balance.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.outstandingBalance;
    final clearsBalance = _isValid && _remainingAfter <= 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // What is owed right now, so the number is never in doubt.
        Container(
          padding: const EdgeInsets.all(AppSpacing.smMd),
          decoration: BoxDecoration(
            gradient: AppGradients.softPrimary,
            borderRadius: AppBorderRadius.radiusL,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Outstanding balance',
                  style: AppTypography.bodySmall,
                ),
              ),
              Text(
                'Rs. ${formatMoneyAmount(balance)}',
                style: AppTypography.priceSmall.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.smMd),
        Text(
          'Payments apply to the oldest unpaid invoices first.',
          style: AppTypography.caption,
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
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Quick amounts: mouse-driven shortcuts, so keyboard traversal skips
        // them the way the till's quick-cash chips do.
        ExcludeFocus(
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              BrandPill(
                label: 'Full balance',
                icon: Icons.done_all_rounded,
                onTap: _submitting ? null : () => _setAmount(balance),
              ),
              BrandPill(
                label: 'Half',
                onTap: _submitting ? null : () => _setAmount(balance / 2),
              ),
              for (final amount in const [500.0, 1000.0])
                if (amount < balance)
                  BrandPill(
                    label: 'Rs. ${amount.toStringAsFixed(0)}',
                    onTap: _submitting ? null : () => _setAmount(amount),
                  ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.smMd),
        _RemainingPreview(
          remaining: _remainingAfter,
          clearsBalance: clearsBalance,
          valid: _isValid,
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
        const SizedBox(height: AppSpacing.md),
        BrandActionButton(
          label: clearsBalance ? 'Settle in full' : 'Record payment',
          icon: Icons.payments_rounded,
          loading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// Live read-out of what the customer will still owe once this payment lands.
class _RemainingPreview extends StatelessWidget {
  const _RemainingPreview({
    required this.remaining,
    required this.clearsBalance,
    required this.valid,
  });

  final double remaining;
  final bool clearsBalance;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    final color = !valid
        ? AppColors.textMuted
        : clearsBalance
        ? AppColors.success
        : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.smMd,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.radiusMD,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            clearsBalance && valid
                ? Icons.check_circle_rounded
                : Icons.schedule_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              !valid
                  ? 'Enter an amount to see the remaining balance.'
                  : clearsBalance
                  ? 'This clears the account in full.'
                  : 'Remaining after payment',
              style: AppTypography.bodySmall,
            ),
          ),
          if (valid && !clearsBalance)
            Text(
              'Rs. ${formatMoneyAmount(remaining)}',
              style: AppTypography.priceSmall.copyWith(color: color),
            ),
        ],
      ),
    );
  }
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
