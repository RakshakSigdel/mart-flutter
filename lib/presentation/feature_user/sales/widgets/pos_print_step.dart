import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/sale_model.dart';
import '../controllers/sale_detail_controller.dart';
import '../../../shared/widgets/section_ui.dart';

/// Step 2 of the POS flow - shows the created bill summary and lets the
/// cashier print the tax invoice, then start a new bill.
class PosPrintStep extends ConsumerStatefulWidget {
  const PosPrintStep({super.key, required this.sale, required this.onNewBill});

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

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: sale == null
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final gutter = AppBreakpoints.isPhone(constraints.maxWidth)
                    ? AppSpacing.sm
                    : AppSpacing.md;
                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(gutter),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SuccessHero(invoiceNumber: sale.invoiceNumber),
                          SizedBox(height: gutter),
                          _ReceiptPanel(sale: sale),
                          SizedBox(height: gutter),
                          _PrintPanel(
                            paperType: _paperType,
                            printing: _printing,
                            onPaperTypeChanged: (pt) =>
                                setState(() => _paperType = pt),
                            onPrint: _printInvoice,
                          ),
                          SizedBox(height: gutter),
                          _NewBillButton(onPressed: widget.onNewBill),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// The "sale is done" banner — the payoff at the end of the flow.
class _SuccessHero extends StatelessWidget {
  const _SuccessHero({required this.invoiceNumber});

  final String invoiceNumber;

  @override
  Widget build(BuildContext context) {
    return AppScaleIn(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.mdLg),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: AppBorderRadius.radiusXL,
          border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 30,
                color: AppColors.textInverse,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bill saved',
                    style: AppTypography.title.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    invoiceNumber.isEmpty
                        ? 'The sale has been recorded.'
                        : 'Invoice $invoiceNumber has been recorded.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The saved bill: its lines, then the money in a dark footer.
class _ReceiptPanel extends StatelessWidget {
  const _ReceiptPanel({required this.sale});

  final SaleDetailModel sale;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionPanelHeader(
            icon: Icons.receipt_long_rounded,
            eyebrow: 'RECEIPT',
            subtitle: sale.invoiceNumber.isEmpty
                ? 'Saved bill'
                : 'Invoice ${sale.invoiceNumber}',
            trailing: SectionBadge(label: '${sale.items.length}'),
          ),
          if (sale.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'No items on this bill.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.smMd,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < sale.items.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: AppSpacing.md,
                        color: AppColors.border,
                      ),
                    _ItemRow(item: sale.items[i]),
                  ],
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSunken,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TotalLine(
                  label: 'Subtotal',
                  value: formatMoneyAmount(sale.subTotal),
                ),
                if (sale.discountAmount > 0)
                  TotalLine(
                    label: 'Discount',
                    value: '- ${formatMoneyAmount(sale.discountAmount)}',
                  ),
                TotalLine(
                  label: 'VAT',
                  value: formatMoneyAmount(sale.vatAmount),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'NET TOTAL',
                        style: AppTypography.eyebrow.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Rs. ${formatMoneyAmount(sale.netTotal)}',
                          style: AppTypography.price,
                        ),
                      ),
                    ),
                  ],
                ),
                if (sale.changeAmount > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TotalLine(
                    label: 'Paid',
                    value: formatMoneyAmount(sale.paidAmount),
                  ),
                  TotalLine(
                    label: 'Change to return',
                    value: 'Rs. ${formatMoneyAmount(sale.changeAmount)}',
                    emphasize: true,
                  ),
                ],
                if (sale.paymentMethod != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Paid by ${formatPaymentMethod(sale.paymentMethod)}',
                    style: AppTypography.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paper size plus the print action.
class _PrintPanel extends StatelessWidget {
  const _PrintPanel({
    required this.paperType,
    required this.printing,
    required this.onPaperTypeChanged,
    required this.onPrint,
  });

  final TaxInvoicePaperType paperType;
  final bool printing;
  final ValueChanged<TaxInvoicePaperType> onPaperTypeChanged;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: AppBorderRadius.radiusMD,
                  ),
                  child: const Icon(
                    Icons.print_rounded,
                    size: 18,
                    color: AppColors.primaryDeep,
                  ),
                ),
                const SizedBox(width: AppSpacing.smMd),
                Text('Print receipt', style: AppTypography.subtitle),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdownField<TaxInvoicePaperType>(
              label: 'Paper format',
              value: paperType,
              enabled: !printing,
              items: [
                for (final pt in TaxInvoicePaperType.values)
                  DropdownMenuItem(value: pt, child: Text(pt.label)),
              ],
              onChanged: (pt) {
                if (pt != null) onPaperTypeChanged(pt);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            BrandActionButton(
              label: 'Print Invoice',
              icon: Icons.print_rounded,
              loading: printing,
              onPressed: onPrint,
            ),
          ],
        ),
      ),
    );
  }
}

class _NewBillButton extends StatelessWidget {
  const _NewBillButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: AppBorderRadius.radiusL,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        hoverColor: AppColors.primarySoft,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.smMd),
          decoration: BoxDecoration(
            borderRadius: AppBorderRadius.radiusL,
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_shopping_cart_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Start a new bill',
                style: AppTypography.label.copyWith(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final SaleItemModel item;

  @override
  Widget build(BuildContext context) {
    final qty = item.quantity % 1 == 0
        ? item.quantity.toInt().toString()
        : item.quantity.toStringAsFixed(2);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: AppBorderRadius.radiusSM,
          ),
          child: Text(
            'x$qty',
            style: AppTypography.priceSmall.copyWith(
              fontSize: 12,
              color: AppColors.primaryDeep,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.smMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.productName ?? 'Product #${item.productId}',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${formatMoneyAmount(item.rate)}'
                '${item.unitSymbol != null ? ' per ${item.unitSymbol}' : ' each'}',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          formatMoneyAmount(item.lineTotal),
          style: AppTypography.priceSmall,
        ),
      ],
    );
  }
}
