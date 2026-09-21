import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/sale_model.dart';
import '../controllers/sale_detail_controller.dart';

/// Step 2 of the POS flow - shows the created bill summary and lets the
/// cashier print the tax invoice, then start a new bill.
class PosPrintStep extends ConsumerStatefulWidget {
  const PosPrintStep({
    super.key,
    required this.sale,
    required this.onNewBill,
  });

  /// The [SaleDetailModel] returned by [SalesController.createSale]. May be
  /// null briefly if the widget is mounted before the sale is created (the
  /// parent's [IndexedStack] keeps all steps alive).
  final SaleDetailModel? sale;

  /// Called when the user taps "Go Back / New Bill", resetting the POS.
  final VoidCallback onNewBill;

  @override
  ConsumerState<PosPrintStep> createState() => _PosPrintStepState();
}

class _PosPrintStepState extends ConsumerState<PosPrintStep> {
  bool _printing = false;
  TaxInvoicePaperType _paperType = TaxInvoicePaperType.mm80;

  Future<void> _printInvoice() async {
    final sale = widget.sale;
    if (sale == null) return;
    setState(() => _printing = true);
    try {
      final bytes = await ref
          .read(saleDetailControllerProvider(sale.id).notifier)
          .downloadTaxInvoice(_paperType);
      final filename =
          'tax-invoice-${sale.invoiceNumber}-${_paperType.apiValue}.pdf';
      await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(bytes),
        name: filename,
      );
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Could not print invoice: $e');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;

    if (sale == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppBorderRadius.radiusL,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bill saved successfully!',
                            style: AppTypography.subtitle.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                          Text(
                            'Invoice: ${sale.invoiceNumber}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Bill summary card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items', style: AppTypography.subtitle),
                    const SizedBox(height: AppSpacing.smMd),
                    if (sale.items.isEmpty)
                      Text(
                        'No items.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      )
                    else
                      for (var i = 0; i < sale.items.length; i++) ...[
                        if (i > 0) const Divider(height: AppSpacing.smMd),
                        _ItemRow(item: sale.items[i]),
                      ],
                    const Divider(height: AppSpacing.lg),
                    _TotalRow(label: 'Subtotal', value: sale.subTotal),
                    if (sale.discountAmount > 0)
                      _TotalRow(
                        label: 'Discount',
                        value: -sale.discountAmount,
                      ),
                    _TotalRow(label: 'VAT', value: sale.vatAmount),
                    const Divider(height: AppSpacing.smMd),
                    _TotalRow(
                      label: 'Net Total',
                      value: sale.netTotal,
                      emphasize: true,
                    ),
                    if (sale.changeAmount > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _TotalRow(label: 'Paid', value: sale.paidAmount),
                      _TotalRow(
                        label: 'Change to return',
                        value: sale.changeAmount,
                      ),
                    ],
                    if (sale.paymentMethod != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Payment: ${formatPaymentMethod(sale.paymentMethod)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Print options card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Print Receipt', style: AppTypography.subtitle),
                    const SizedBox(height: AppSpacing.smMd),
                    AppDropdownField<TaxInvoicePaperType>(
                      label: 'Paper format',
                      value: _paperType,
                      enabled: !_printing,
                      items: [
                        for (final pt in TaxInvoicePaperType.values)
                          DropdownMenuItem(
                            value: pt,
                            child: Text(pt.label),
                          ),
                      ],
                      onChanged: (pt) {
                        if (pt != null) setState(() => _paperType = pt);
                      },
                    ),
                    const SizedBox(height: AppSpacing.smMd),
                    AppButton.expanded(
                      label: 'Print Invoice',
                      leading: const Icon(Icons.print_rounded, size: 18),
                      isLoading: _printing,
                      onPressed: _printing ? null : _printInvoice,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // New bill button
              OutlinedButton.icon(
                onPressed: widget.onNewBill,
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text('Go Back / New Bill'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.smMd,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Local helper widgets (mirrors sale_detail_screen.dart helpers)
// -----------------------------------------------------------------------------

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final SaleItemModel item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName ?? 'Product #${item.productId}',
                style: AppTypography.body,
              ),
              Text(
                '${formatMoneyAmount(item.quantity)}'
                '${item.unitSymbol != null ? ' ${item.unitSymbol}' : ''}'
                ' x ${formatMoneyAmount(item.rate)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Text(formatMoneyAmount(item.lineTotal), style: AppTypography.body),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize ? AppTypography.title : AppTypography.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasize
                  ? style
                  : style.copyWith(color: AppColors.textMuted),
            ),
          ),
          Text(formatMoneyAmount(value), style: style),
        ],
      ),
    );
  }
}
