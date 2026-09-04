import 'package:flutter/material.dart';

import 'app_text_field.dart';

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

String formatAppDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}

/// A read-only [AppTextField] that opens the platform date picker on tap —
/// the "effective from"/date-filter pattern used across the app's forms,
/// pulled out here once both purchases and sales needed their own
/// from/to date filters.
///
/// No suffix-tap-to-clear: the field is wrapped in [AbsorbPointer] so the
/// whole row opens the picker on tap (rather than only the text), which
/// would also swallow a suffix icon's own tap before it ever reached it.
/// Clear a value by picking a different date, or give the caller its own
/// "Clear filters" affordance instead.
class AppDateField extends StatefulWidget {
  const AppDateField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.hint = 'Select a date',
    this.enabled = true,
    this.firstDate,
    this.lastDate,
  });

  final String? label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String hint;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  late final _controller = TextEditingController(
    text: widget.value == null ? '' : formatAppDate(widget.value!),
  );

  @override
  void didUpdateWidget(AppDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value == null
          ? ''
          : formatAppDate(widget.value!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value ?? now,
      firstDate: widget.firstDate ?? DateTime(now.year - 5),
      lastDate: widget.lastDate ?? DateTime(now.year + 5),
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? _pick : null,
      child: AbsorbPointer(
        child: AppTextField(
          controller: _controller,
          label: widget.label,
          hint: widget.hint,
          readOnly: true,
          enabled: widget.enabled,
          suffixIcon: Icons.calendar_today_outlined,
        ),
      ),
    );
  }
}
