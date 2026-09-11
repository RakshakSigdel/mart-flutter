import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../controllers/inventory_product_detail_controller.dart';



/// A purchase unit's VAT history — fetched on demand (`GET
/// .../purchase-units/{id}`, the only endpoint that carries it), with an
/// "Open new rate" mini-form that closes whichever rate is currently in
/// force and starts a new one.
class InventoryProductVatHistoryDialog extends ConsumerStatefulWidget {
  const InventoryProductVatHistoryDialog({
    super.key,
    required this.productId,
    required this.purchaseUnitId,
  });

  final int productId;
  final int purchaseUnitId;

  @override
  ConsumerState<InventoryProductVatHistoryDialog> createState() =>
      _InventoryProductVatHistoryDialogState();
}

class _InventoryProductVatHistoryDialogState
    extends ConsumerState<InventoryProductVatHistoryDialog> {
  late Future<ProductPurchaseUnitDetailModel> _future = _load();

  bool _showOpenRateForm = false;
  final _rateController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  Future<ProductPurchaseUnitDetailModel> _load() {
    return ref
        .read(inventoryProductDetailControllerProvider(widget.productId).notifier)
        .loadPurchaseUnitDetail(widget.purchaseUnitId);
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _openNewRate() async {
    final rate = double.tryParse(_rateController.text.trim());
    if (rate == null || rate < 0) {
      setState(() => _errorMessage = 'Enter a valid rate');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final detail = await ref
          .read(inventoryProductDetailControllerProvider(widget.productId).notifier)
          .openVatRate(
            widget.purchaseUnitId,
            OpenVatRateRequest(rate: rate),
          );
      if (!mounted) return;
      setState(() {
        _future = Future.value(detail);
        _showOpenRateForm = false;
        _rateController.clear();
      });
      AppSnackBar.success(context, 'New VAT rate opened.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductPurchaseUnitDetailModel>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const SizedBox(height: 120, child: AppLoader());
        }
        if (snapshot.hasError) {
          return AppEmptyState.error(
            message: 'Could not load VAT history.',
            onAction: () => setState(() => _future = _load()),
          );
        }

        final detail = snapshot.data!;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current rate: ${detail.currentVatRate == null ? '—' : '${formatMoney(detail.currentVatRate)}%'}',
              style: AppTypography.subtitle,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('HISTORY', style: AppTypography.eyebrow),
            const SizedBox(height: AppSpacing.sm),
            if (detail.vatRates.isEmpty)
              Text(
                'No VAT history yet.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              )
            else
              for (final rate in detail.vatRates)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${formatMoney(rate.rate)}%',
                          style: AppTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: AppSpacing.md),
            if (_showOpenRateForm) ...[
              AppTextField(
                controller: _rateController,
                label: 'New VAT rate (%)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                enabled: !_submitting,
              ),
              AppFormError(message: _errorMessage),
              const SizedBox(height: AppSpacing.smMd),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      onPressed: _submitting
                          ? null
                          : () => setState(() {
                                _showOpenRateForm = false;
                                _errorMessage = null;
                              }),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.smMd),
                  Expanded(
                    child: AppButton(
                      label: 'Save',
                      isLoading: _submitting,
                      onPressed: _submitting ? null : _openNewRate,
                    ),
                  ),
                ],
              ),
            ] else
              AppButton.expanded(
                label: 'Open new rate',
                leading: const Icon(Icons.add),
                onPressed: () => setState(() => _showOpenRateForm = true),
              ),
          ],
        );
      },
    );
  }
}

/// Opens [InventoryProductVatHistoryDialog] as a centered dialog on wide
/// screens, or a bottom sheet on phone.
Future<void> showInventoryProductVatHistoryDialog(
  BuildContext context, {
  required int productId,
  required int purchaseUnitId,
  required String unitLabel,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
  final title = 'VAT history — $unitLabel';
  final content = InventoryProductVatHistoryDialog(
    productId: productId,
    purchaseUnitId: purchaseUnitId,
  );

  return isWide
      ? showAppDialog<void>(context: context, title: title, content: content)
      : showAppModal<void>(context: context, title: title, content: content);
}
