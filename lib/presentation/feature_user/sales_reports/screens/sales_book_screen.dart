import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/report_date_range.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/sales_book_model.dart';
import '../controllers/sales_book_controller.dart';

/// IRD sales book preview and backend-rendered official PDF export.
class SalesBookScreen extends ConsumerStatefulWidget {
  const SalesBookScreen({super.key});

  @override
  ConsumerState<SalesBookScreen> createState() => _SalesBookScreenState();
}

class _SalesBookScreenState extends ConsumerState<SalesBookScreen> {
  bool _downloading = false;

  Future<void> _downloadPdf() async {
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(salesBookControllerProvider.notifier)
          .downloadPdf();
      await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(bytes),
        name: 'ird-sales-book.pdf',
      );
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    } catch (_) {
      if (mounted)
        AppSnackBar.error(context, 'Could not open the sales-book PDF.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(salesBookControllerProvider);
    final report = ref.watch(salesBookProvider(query));
    final controller = ref.read(salesBookControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.contentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('IRD Sales Book', style: AppTypography.heading),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Review bill-level sales records and export the official landscape A4 form.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final filter = AppDropdownField<ReportDateRange>(
                      label: 'Report period',
                      value: query.dateRange,
                      items: [
                        for (final range in ReportDateRange.values)
                          DropdownMenuItem(
                            value: range,
                            child: Text(range.label),
                          ),
                      ],
                      onChanged: (range) {
                        if (range != null) {
                          controller.update(query.copyWith(dateRange: range));
                        }
                      },
                    );
                    final export = AppButton(
                      label: 'Export PDF',
                      leading: const Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 18,
                      ),
                      isLoading: _downloading,
                      onPressed: _downloading ? null : _downloadPdf,
                    );
                    if (constraints.maxWidth < AppBreakpoints.tablet) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          filter,
                          const SizedBox(height: AppSpacing.md),
                          export,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: filter),
                        const SizedBox(width: AppSpacing.md),
                        export,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              report.when(
                loading: () => const AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: AppLoader(),
                  ),
                ),
                error: (error, _) => AppCard(
                  child: AppEmptyState.error(
                    message: error is ApiException
                        ? error.message
                        : 'Could not load the sales book.',
                    onAction: () => ref.invalidate(salesBookProvider(query)),
                  ),
                ),
                data: (book) => _SalesBookCard(book: book),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesBookCard extends StatelessWidget {
  const _SalesBookCard({required this.book});
  final SalesBookModel book;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xxl,
          runSpacing: AppSpacing.sm,
          children: [
            _Meta(
              label: 'Firm',
              value: book.firmName.isEmpty ? '—' : book.firmName,
            ),
            _Meta(label: 'PAN', value: book.pan.isEmpty ? '—' : book.pan),
            _Meta(
              label: 'Period',
              value: book.duration.isEmpty
                  ? '${book.month} ${book.year}'.trim()
                  : book.duration,
            ),
            _Meta(label: 'Bills', value: '${book.rows.length}'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.sm),
        if (book.rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: Text('No sales recorded for this period.')),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: const WidgetStatePropertyAll(
                AppColors.surfaceSunken,
              ),
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Bill no.')),
                DataColumn(label: Text('Buyer')),
                DataColumn(label: Text('Buyer PAN')),
                DataColumn(numeric: true, label: Text('Total sales')),
                DataColumn(numeric: true, label: Text('Non-taxable')),
                DataColumn(numeric: true, label: Text('Export')),
                DataColumn(numeric: true, label: Text('Discount')),
                DataColumn(numeric: true, label: Text('Taxable')),
                DataColumn(numeric: true, label: Text('Tax')),
              ],
              rows: [
                for (final row in book.rows) _row(row),
                DataRow(
                  color: const WidgetStatePropertyAll(AppColors.primarySoft),
                  cells: [
                    const DataCell(Text('')),
                    const DataCell(Text('TOTAL', style: AppTypography.label)),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                    DataCell(_amount(book.total.totalSales, bold: true)),
                    DataCell(_amount(book.total.nonTaxableSales, bold: true)),
                    DataCell(_amount(book.total.exportSales, bold: true)),
                    DataCell(_amount(book.total.discount, bold: true)),
                    DataCell(_amount(book.total.taxableAmount, bold: true)),
                    DataCell(_amount(book.total.tax, bold: true)),
                  ],
                ),
              ],
            ),
          ),
      ],
    ),
  );

  DataRow _row(SalesBookRow row) => DataRow(
    cells: [
      DataCell(Text(row.date.isEmpty ? '—' : row.date)),
      DataCell(Text(row.billNumber.isEmpty ? '—' : row.billNumber)),
      DataCell(Text(row.buyerName.isEmpty ? '—' : row.buyerName)),
      DataCell(Text(row.buyerPan.isEmpty ? '—' : row.buyerPan)),
      DataCell(_amount(row.totalSales)),
      DataCell(_amount(row.nonTaxableSales)),
      DataCell(_amount(row.exportSales)),
      DataCell(_amount(row.discount)),
      DataCell(_amount(row.taxableAmount)),
      DataCell(_amount(row.tax)),
    ],
  );

  Widget _amount(double value, {bool bold = false}) => Text(
    formatMoneyAmount(value),
    style: bold ? AppTypography.label : AppTypography.bodySmall,
  );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTypography.caption),
      const SizedBox(height: AppSpacing.xs),
      Text(value, style: AppTypography.subtitle),
    ],
  );
}
