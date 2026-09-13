import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The standard text input.
///
/// Borders, fill, radius and error styling all come from
/// `inputDecorationTheme` in [AppTheme] — this widget only adds the label
/// above the field, the optional password toggle, and the sizing rules.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.focusNode,
    this.initialValue,
    this.autofillHints,
  }) : assert(
         controller == null || initialValue == null,
         'Provide either a controller or an initialValue, not both.',
       );

  /// A multi-line input sized for notes, addresses and remarks.
  const AppTextField.multiline({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.maxLength,
    this.focusNode,
    this.initialValue,
    this.minLines = 3,
    this.maxLines = 6,
  }) : prefixIcon = null,
       suffixIcon = null,
       onSuffixTap = null,
       keyboardType = TextInputType.multiline,
       textInputAction = TextInputAction.newline,
       inputFormatters = null,
       onSubmitted = null,
       obscureText = false,
       autofocus = false,
       autofillHints = null;

  final TextEditingController? controller;
  final String? label;
  final String? hint;

  /// Small helper line under the field. Hidden while an error is shown.
  final String? helperText;

  final IconData? prefixIcon;

  /// Ignored when [obscureText] is true — the visibility toggle takes the slot.
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;

  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Renders a password field with a show/hide toggle.
  final bool obscureText;

  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final String? initialValue;
  final Iterable<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      initialValue: widget.initialValue,
      focusNode: widget.focusNode,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      obscureText: _obscured,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      autofillHints: widget.autofillHints,
      maxLines: _obscured ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      style: AppTypography.body.copyWith(
        color: widget.enabled ? AppColors.textPrimary : AppColors.textMuted,
      ),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        hintText: widget.hint,
        helperText: widget.helperText,
        counterText: '', // the maxLength counter is noise in these layouts
        filled: true,
        fillColor: widget.enabled ? AppColors.card : AppColors.surfaceSunken,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 20)
            : null,
        suffixIcon: _buildSuffix(),
      ),
    );

    if (widget.label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label!, style: AppTypography.fieldLabel),
        const SizedBox(height: AppSpacing.sm),
        field,
      ],
    );
  }

  Widget? _buildSuffix() {
    if (widget.obscureText) {
      return IconButton(
        onPressed: () => setState(() => _obscured = !_obscured),
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
        ),
        tooltip: _obscured ? 'Show' : 'Hide',
      );
    }
    if (widget.suffixIcon == null) return null;
    if (widget.onSuffixTap == null) {
      return Icon(widget.suffixIcon, size: 20);
    }
    return IconButton(
      onPressed: widget.onSuffixTap,
      icon: Icon(widget.suffixIcon, size: 20),
    );
  }
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// AppTextField(
//   controller: _emailController,
//   label: 'Email',
//   hint: 'you@example.com',
//   prefixIcon: Icons.mail_outline,
//   keyboardType: TextInputType.emailAddress,
//   validator: (v) => (v == null || v.isEmpty) ? 'Email is required' : null,
// )
//
// // Password with a built-in show/hide toggle:
// AppTextField(
//   controller: _passwordController,
//   label: 'Password',
//   obscureText: true,
// )
//
// // Notes / address:
// AppTextField.multiline(
//   controller: _notesController,
//   label: 'Delivery notes',
//   hint: 'Ring the bell twice',
// )
