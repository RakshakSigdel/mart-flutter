import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';

/// Sets the level at which a product reads as low. Plain content (no
/// provider of its own) — the caller supplies [onSubmit] so this works the
/// same whether it's triggered from a list row (`StockController`) or the
/// detail screen (`StockDetailController`).
class StockReorderLevelDialog extends StatefulWidget {
  const StockReorderLevelDialog({
    super.key,
    required this.currentLevel,
    required this.onSubmit,
  });

  final double currentLevel;
  final Future<void> Function(double reorderLevel) onSubmit;

  @override
  State<StockReorderLevelDialog> createState() =>
      _StockReorderLevelDialogState();
}

class _StockReorderLevelDialogState extends State<StockReorderLevelDialog> {
  late final _controller = TextEditingController(
    text: formatStockLevelSeed(widget.currentLevel),
  );
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final level = double.tryParse(_controller.text.trim());
    if (level == null || level < 0) {
      setState(() => _errorMessage = 'Enter a non-negative number');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(level);
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
          controller: _controller,
          label: 'Reorder level',
          hint: 'e.g. 10',
          helperText:
              'Reads as low stock once the on-hand quantity falls to or below this.',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          enabled: !_submitting,
          autofocus: true,
        ),
        AppFormError(message: _errorMessage),
        const SizedBox(height: AppSpacing.xl),
        AppButton.expanded(
          label: 'Save',
          isLoading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

/// `0.0` -> `"0"`, `10.5` -> `"10.5"` — a text-field seed, not a display
/// string, so it stays plain rather than going through the same trimming
/// as `formatStockQuantity`.
String formatStockLevelSeed(double value) => value == value.truncateToDouble()
    ? value.truncate().toString()
    : value.toString();

/// Opens [StockReorderLevelDialog] as a centered dialog on wide screens, or
/// a bottom sheet on phone. Resolves `true` once the level is saved.
Future<bool?> showStockReorderLevelDialog(
  BuildContext context, {
  required double currentLevel,
  required Future<void> Function(double reorderLevel) onSubmit,
}) {
  final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
  final content = StockReorderLevelDialog(
    currentLevel: currentLevel,
    onSubmit: onSubmit,
  );

  return isWide
      ? showAppDialog<bool>(
          context: context,
          title: 'Set reorder level',
          content: content,
        )
      : showAppModal<bool>(
          context: context,
          title: 'Set reorder level',
          content: content,
        );
}
