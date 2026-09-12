import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/sale_model.dart';
import '../controllers/sale_detail_controller.dart';
import '../widgets/sale_badges.dart';
import '../widgets/sale_take_payment_dialog.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime? date) {
  if (date == null) return '---';
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// Opens the native browser print dialog for the given PDF bytes.
Future<void> _openPdfInBrowser(List<int> bytes, String filename) async {
  await Printing.layoutPdf(
    onLayout: (format) async => Uint8List.fromList(bytes),
    name: filename,
  );
}

/// One bill''s detail page: its record, customer details, and every line
/// item — read-only apart from taking a payment against it, since a rung-up
/// bill is otherwise immutable (the backend exposes no edit/remove for it).
class SaleDetailScreen extends ConsumerStatefulWidget {
  const SaleDetailScreen({super.key, required this.saleId});

  final int saleId;

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  bool _downloadingInvoice = false;
  bool _downloadingReceipt = false;

  Future<void> _takePayment(SaleDetailModel sale) async {
    final result = await showSaleTakePaymentDialog(
      context,
      saleId: widget.saleId,
      dueAmount: sale.dueAmount,
    );
    if (result == true && context.mounted) {
      AppSnackBar.success(context, 'Payment recorded.');
    }
  }

  Future<void> _printInvoice() async {
    setState(() => _downloadingInvoice = true);
    try {
      final bytes = await ref
          .read(saleDetailControllerProvider(widget.saleId).notifier)
          .downloadInvoice();
      final sale = ref.read(saleDetailControllerProvider(widget.saleId)).sale;
      final filename = 'invoice-${sale?.invoiceNumber ?? widget.saleId}.pdf';
      await _openPdfInBrowser(bytes, filename);
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    } catch (e, st) {
      debugPrint('Invoice error: $e\n$st');
      if (mounted) AppSnackBar.error(context, 'Could not print invoice: $e');
    } finally {
      if (mounted) setState(() => _downloadingInvoice = false);
    }
  }

  Future<void> _printReceipt() async {
    setState(() => _downloadingReceipt = true);
    try {
      final bytes = await ref
          .read(saleDetailControllerProvider(widget.saleId).notifier)
          .downloadReceipt();
      final sale = ref.read(saleDetailControllerProvider(widget.saleId)).sale;
      final filename = 'receipt-${sale?.invoiceNumber ?? widget.saleId}.pdf';
      await _openPdfInBrowser(bytes, filename);
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    } catch (e, st) {
      debugPrint('Receipt error: $e\n$st');
      if (mounted) AppSnackBar.error(context, 'Could not print receipt: $e');
    } finally {
      if (mounted) setState(() => _downloadingReceipt = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleDetailControllerProvider(widget.saleId));
    final sale = state.sale;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to sales',
          onPressed: () {
            // POS replaces its root route with this detail page on success,
            // so there is no page to pop in that case. Detail pages opened
            // from Sales History retain their normal pushed-route back flow.
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.sales);
            }
          },
        ),
        title: Text(sale?.invoiceNumber ?? 'Sale'),
        actions: [
          // A4 invoice
          _downloadingInvoice
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'Print A4 invoice',
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: sale == null ? null : _printInvoice,
                ),
          // Till receipt
          _downloadingReceipt
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'Print receipt',
                  icon: const Icon(Icons.receipt_outlined),
                  onPressed: sale == null ? null : _printReceipt,
                ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(context, state, sale),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SaleDetailState state,
    SaleDetailModel? sale,
  ) {
    if (state.isLoading && sale == null) {
      return const AppLoader();
    }

    if (state.error != null && sale == null) {
      return AppEmptyState.error(
        message: state.error,
        onAction: () => ref
            .read(saleDetailControllerProvider(widget.saleId).notifier)
            .refresh(),
      );
    }

    if (sale == null) return const SizedBox.shrink();

    final status = PaymentStatus.fromApiValue(sale.paymentStatus);
    final canTakePayment = status != PaymentStatus.paid;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sale.invoiceNumber,
                            style: AppTypography.title,
                          ),
                        ),
                        PaymentStatusBadge(status: sale.paymentStatus),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _formatDate(sale.soldAt),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.smMd),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.smMd),
                    _InfoRow(
                      label: 'Customer',
                      value: sale.customerName ?? '---',
                    ),
                    if (sale.customerPhone != null)
                      _InfoRow(label: 'Phone', value: sale.customerPhone!),
                    if (sale.customerPan != null)
                      _InfoRow(label: 'PAN', value: sale.customerPan!),
                    _InfoRow(
                      label: 'Payment method',
                      value: formatPaymentMethod(sale.paymentMethod),
                    ),
                    _InfoRow(
                      label: 'Tax scheme',
                      value: formatTaxScheme(sale.taxScheme),
                    ),
                    if (sale.remark != null && sale.remark!.isNotEmpty)
                      _InfoRow(label: 'Remark', value: sale.remark!),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items', style: AppTypography.subtitle),
                    const SizedBox(height: AppSpacing.smMd),
                    if (sale.items.isEmpty)
                      Text(
                        'No items on this bill.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      )
                    else
                      for (var i = 0; i < sale.items.length; i++) ...[
                        if (i > 0) const Divider(height: AppSpacing.lg),
                        _ItemRow(item: sale.items[i]),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TotalRow(label: 'Subtotal', value: sale.subTotal),
                    _TotalRow(label: 'Discount', value: -sale.discountAmount),
                    _TotalRow(
                      label: 'Taxable amount',
                      value: sale.taxableAmount,
                    ),
                    _TotalRow(label: 'VAT', value: sale.vatAmount),
                    const Divider(height: AppSpacing.lg),
                    _TotalRow(
                      label: 'Net total',
                      value: sale.netTotal,
                      emphasize: true,
                    ),
                    const SizedBox(height: AppSpacing.smMd),
                    _TotalRow(label: 'Paid', value: sale.paidAmount),
                    if (sale.changeAmount > 0)
                      _TotalRow(
                        label: 'Change given',
                        value: sale.changeAmount,
                      ),
                    if (sale.dueAmount > 0)
                      _TotalRow(label: 'Due', value: sale.dueAmount),
                    if (canTakePayment) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppButton.expanded(
                        label: 'Take payment',
                        onPressed: () => _takePayment(sale),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'A4 Invoice',
                            variant: AppButtonVariant.secondary,
                            leading: _downloadingInvoice
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.picture_as_pdf_outlined,
                                    size: 16,
                                  ),
                            isLoading: _downloadingInvoice,
                            onPressed: _downloadingInvoice
                                ? null
                                : _printInvoice,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.smMd),
                        Expanded(
                          child: AppButton(
                            label: 'Receipt',
                            variant: AppButtonVariant.secondary,
                            leading: _downloadingReceipt
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.receipt_outlined, size: 16),
                            isLoading: _downloadingReceipt,
                            onPressed: _downloadingReceipt
                                ? null
                                : _printReceipt,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName ?? 'Product #${item.productId}',
                style: AppTypography.subtitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${formatMoneyAmount(item.quantity)}'
                '${item.unitSymbol != null ? ' ${item.unitSymbol}' : ''}'
                ' x ${formatMoneyAmount(item.rate)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Text(formatMoneyAmount(item.lineTotal), style: AppTypography.subtitle),
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
