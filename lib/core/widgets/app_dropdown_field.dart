import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A plain (non-searchable) dropdown, styled like [AppTextField].
///
/// For long or server-backed lists use `AppSearchableDropdownField` instead —
/// it adds a search box and optional pagination inside the popup.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.validator,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  final String? label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final String? Function(T?)? validator;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final field = DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      focusNode: focusNode,
      autofocus: autofocus,
      style: AppTypography.body,
      // Without this, the closed field's intrinsic width follows the widest
      // item's natural width (Flutter measures every item off-stage for the
      // open/close animation) rather than the space actually available —
      // a long item label then overflows a narrow fixed-width field instead
      // of eliding.
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
      iconEnabledColor: AppColors.iconActive,
      iconDisabledColor: AppColors.iconInactive,
      borderRadius: AppBorderRadius.radiusL,
      dropdownColor: AppColors.card,
      // Borders, fill and radius come from inputDecorationTheme.
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: enabled ? AppColors.card : AppColors.surfaceSunken,
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label!, style: AppTypography.fieldLabel),
        const SizedBox(height: AppSpacing.sm),
        field,
      ],
    );
  }
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// AppDropdownField<String>(
//   label: 'Payment method',
//   value: _paymentMethod,
//   hint: 'Select method',
//   items: const [
//     DropdownMenuItem(value: 'CASH', child: Text('Cash')),
//     DropdownMenuItem(value: 'FONEPAY', child: Text('Fonepay')),
//   ],
//   onChanged: (val) => setState(() => _paymentMethod = val),
//   validator: (val) => val == null ? 'Pick a payment method' : null,
// )
