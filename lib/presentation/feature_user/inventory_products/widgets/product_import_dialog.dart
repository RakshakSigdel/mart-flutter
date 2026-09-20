import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../providers/providers_user/inventory_products_provider.dart';

/// Dry-runs a CSV first, preserving the selected file and its complete error
/// table so a shop can correct its spreadsheet in one pass.
class ProductImportDialog extends ConsumerStatefulWidget {
  const ProductImportDialog({super.key});
  @override
  ConsumerState<ProductImportDialog> createState() =>
      _ProductImportDialogState();
}

class _ProductImportDialogState extends ConsumerState<ProductImportDialog> {
  PlatformFile? _file;
  ProductImportResponse? _report;
  String? _error;
  bool _busy = false;
  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result != null && mounted)
      setState(() {
        _file = result.files.single;
        _report = null;
        _error = null;
      });
  }

  Future<void> _run(bool dryRun) async {
    final file = _file;
    if (file?.bytes == null) {
      setState(() => _error = 'Choose a CSV file first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(inventoryProductsRemoteDataSourceProvider)
          .importCsv(file!.bytes!, file.name, dryRun: dryRun);
      if (!mounted) return;
      setState(() => _report = result);
      if (!dryRun && result.isClean) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Import products from CSV'),
    content: SizedBox(
      width: 720,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _file == null ? 'Choose a CSV file (up to 10 MB).' : _file!.name,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: _file == null ? 'Choose CSV' : 'Choose another CSV',
              variant: AppButtonVariant.secondary,
              onPressed: _busy ? null : _pick,
            ),
            if (_report != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                '${_report!.rows} rows checked; ${_report!.errors.length} issue(s).',
                style: AppTypography.body,
              ),
            ],
            if (_report?.errors.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.sm),
              _errors(_report!.errors),
            ],
            AppFormError(message: _error),
          ],
        ),
      ),
    ),
    actions: [
      AppButton(
        label: 'Close',
        variant: AppButtonVariant.secondary,
        onPressed: _busy ? null : () => Navigator.of(context).pop(),
      ),
      if (_report?.isClean == true)
        AppButton(
          label: 'Import ${_report!.rows} products',
          isLoading: _busy,
          onPressed: _busy ? null : () => _run(false),
        )
      else
        AppButton(
          label: 'Check file',
          isLoading: _busy,
          onPressed: _busy ? null : () => _run(true),
        ),
    ],
  );
  Widget _errors(List<ProductImportError> errors) => SizedBox(
    height: 260,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Line')),
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Problem')),
        ],
        rows: [
          for (final e in errors)
            DataRow(
              cells: [
                DataCell(Text(e.line.toString())),
                DataCell(Text(e.product ?? '—')),
                DataCell(Text(e.message)),
              ],
            ),
        ],
      ),
    ),
  );
}
