import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/return_note_model.dart';
import '../../../../providers/providers_user/return_note_provider.dart';
import '../../../feature_shared/auth/controller/auth_controller.dart';
import 'return_note_card.dart';
import 'nepali_date_input.dart';

class ReturnableLine {
  const ReturnableLine(this.id, this.name, this.quantity, this.unit);
  final int id;
  final String name;
  final double quantity;
  final String? unit;
}

class ReturnsForBill extends ConsumerStatefulWidget {
  const ReturnsForBill({
    super.key,
    required this.kind,
    required this.billId,
    required this.lines,
  });
  final ReturnKind kind;
  final int billId;
  final List<ReturnableLine> lines;

  @override
  ConsumerState<ReturnsForBill> createState() => _ReturnsForBillState();
}

class _ReturnsForBillState extends ConsumerState<ReturnsForBill> {
  List<ReturnNoteModel>? _notes;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notes = await ref
          .read(returnNoteRemoteDataSourceProvider)
          .byOriginal(widget.kind, widget.billId);
      if (mounted) setState(() => _notes = notes);
    } on ApiException catch (e) {
      if (e.type == ApiFailureType.unauthorized) {
        await ref.read(authControllerProvider.notifier).logout();
      }
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load returns.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final notes = _notes;
    if (notes == null) return;
    final returned = <int, double>{};
    for (final note in notes) {
      for (final item in note.items) {
        returned.update(
          item.originalItemId,
          (old) => old + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }
    final available = widget.lines
        .map(
          (line) => ReturnableLine(
            line.id,
            line.name,
            (line.quantity - (returned[line.id] ?? 0))
                .clamp(0, line.quantity)
                .toDouble(),
            line.unit,
          ),
        )
        .where((line) => line.quantity > 0)
        .toList();
    if (available.isEmpty) return;
    final created = await showAppDialog<ReturnNoteModel>(
      context: context,
      title: widget.kind == ReturnKind.sale
          ? 'Create credit note'
          : 'Create debit note',
      content: _ReturnForm(
        kind: widget.kind,
        billId: widget.billId,
        lines: available,
      ),
    );
    if (created != null && mounted) {
      AppSnackBar.success(
        context,
        '${widget.kind.noteLabel} ${created.number} created.',
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = _notes;
    final hasAvailable =
        notes != null &&
        widget.lines.any((line) {
          final used = notes
              .expand((note) => note.items)
              .where((item) => item.originalItemId == line.id)
              .fold<double>(0, (sum, item) => sum + item.quantity);
          return line.quantity - used > 0.000001;
        });
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.kind.title, style: AppTypography.subtitle),
              ),
              IconButton(
                tooltip: 'Refresh returns',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (widget.lines.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton.expanded(
              label: widget.kind == ReturnKind.sale
                  ? 'Return sold goods'
                  : 'Return goods to vendor',
              onPressed: !_loading && _error == null && hasAvailable
                  ? _create
                  : null,
            ),
          ],
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          if (!_loading && _error == null && notes != null) ...[
            if (notes.isEmpty) const Text('No returns for this bill.'),
            for (final note in notes)
              ReturnNoteCard(note: note, kind: widget.kind),
            if (!hasAvailable && widget.lines.isNotEmpty)
              const Text('All items on this bill have already been returned.'),
          ],
        ],
      ),
    );
  }
}

class _ReturnForm extends ConsumerStatefulWidget {
  const _ReturnForm({
    required this.kind,
    required this.billId,
    required this.lines,
  });
  final ReturnKind kind;
  final int billId;
  final List<ReturnableLine> lines;

  @override
  ConsumerState<_ReturnForm> createState() => _ReturnFormState();
}

class _ReturnFormState extends ConsumerState<_ReturnForm> {
  final _reason = TextEditingController();
  final _remark = TextEditingController();
  final _nepaliDate = TextEditingController();
  final _quantities = <int, TextEditingController>{};
  DateTime _date = DateTime.now();
  String? _error;
  bool _saving = false;

  Future<void> _pickNepaliDate() async {
    final selected = await showNepaliDatePicker(
      context: context,
      initialDate:
          parseReturnNepaliDate(_nepaliDate.text) ?? NepaliDateTime.now(),
      firstDate: firstReturnNepaliDate,
      lastDate: lastReturnNepaliDate,
      helpText: 'Select Nepali return date',
    );
    if (selected != null && mounted) {
      _nepaliDate.text = formatReturnNepaliDate(selected);
      setState(() => _error = null);
    }
  }

  @override
  void initState() {
    super.initState();
    for (final line in widget.lines) {
      _quantities[line.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    _remark.dispose();
    _nepaliDate.dispose();
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final quantities = <ReturnQuantity>[];
    for (final line in widget.lines) {
      final raw = _quantities[line.id]!.text.trim();
      if (raw.isEmpty) continue;
      final quantity = double.tryParse(raw);
      if (quantity == null ||
          !quantity.isFinite ||
          quantity <= 0 ||
          quantity > line.quantity + 0.000001) {
        setState(
          () => _error =
              'Enter a quantity between 0 and ${formatMoneyAmount(line.quantity)} for ${line.name}.',
        );
        return;
      }
      quantities.add(ReturnQuantity(line.id, quantity));
    }
    if (_reason.text.trim().isEmpty || quantities.isEmpty) {
      setState(
        () => _error = 'Enter a reason and at least one return quantity.',
      );
      return;
    }
    final typedNepaliDate = _nepaliDate.text.trim();
    final parsedNepaliDate = typedNepaliDate.isEmpty
        ? null
        : parseReturnNepaliDate(typedNepaliDate);
    if (widget.kind == ReturnKind.sale &&
        typedNepaliDate.isNotEmpty &&
        parsedNepaliDate == null) {
      setState(
        () => _error =
            'Enter a valid Nepali date (YYYY-MM-DD) or select one from the calendar.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final note = await ref
          .read(returnNoteRemoteDataSourceProvider)
          .create(
            widget.kind,
            CreateReturnRequest(
              originalId: widget.billId,
              reason: _reason.text.trim(),
              date: widget.kind == ReturnKind.purchase ? _date : null,
              nepaliDate: parsedNepaliDate == null
                  ? null
                  : formatReturnNepaliDate(parsedNepaliDate),
              remark: _remark.text.trim(),
              items: quantities,
            ),
          );
      if (mounted) Navigator.of(context).pop(note);
    } on ApiException catch (e) {
      if (e.type == ApiFailureType.unauthorized) {
        await ref.read(authControllerProvider.notifier).logout();
      }
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted)
        setState(
          () => _error = 'Could not create the return. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Enter quantities in the same units as the original bill. Available quantities include earlier returns.',
        style: AppTypography.bodySmall,
      ),
      const SizedBox(height: AppSpacing.md),
      for (final line in widget.lines) ...[
        AppTextField(
          controller: _quantities[line.id],
          label: line.name,
          hint: 'Up to ${formatMoneyAmount(line.quantity)} ${line.unit ?? ''}',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      AppTextField(
        controller: _reason,
        label: 'Reason',
        hint: 'Why are these goods returned?',
      ),
      const SizedBox(height: AppSpacing.sm),
      if (widget.kind == ReturnKind.purchase)
        AppDateField(
          label: 'Return date',
          value: _date,
          onChanged: (value) {
            if (value != null) setState(() => _date = value);
          },
        ),
      if (widget.kind == ReturnKind.sale)
        AppTextField(
          controller: _nepaliDate,
          label: 'Nepali date (optional)',
          hint: 'YYYY-MM-DD',
          helperText: 'Type a B.S. date or choose it from the calendar.',
          keyboardType: TextInputType.datetime,
          suffixIcon: Icons.calendar_month_outlined,
          onSuffixTap: _pickNepaliDate,
        ),
      const SizedBox(height: AppSpacing.sm),
      AppTextField.multiline(controller: _remark, label: 'Remark (optional)'),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(_error!, style: const TextStyle(color: AppColors.error)),
        ),
      const SizedBox(height: AppSpacing.md),
      AppButton.expanded(
        label: 'Create ${widget.kind.noteLabel.toLowerCase()}',
        onPressed: _saving ? null : _submit,
        isLoading: _saving,
      ),
    ],
  );
}
