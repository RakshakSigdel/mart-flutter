import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// A yes/no confirmation for an action that isn't instantly undoable
/// (retiring a product, removing a purchase/selling unit). Returns `true`
/// if confirmed, `null`/`false` otherwise — the caller performs the actual
/// action after awaiting this, so a thrown [ApiException] surfaces exactly
/// where the caller already handles it.
Future<bool?> showInventoryProductConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) {
  return showAppDialog<bool>(
    context: context,
    title: title,
    content: _ConfirmContent(
      message: message,
      confirmLabel: confirmLabel,
      destructive: destructive,
    ),
  );
}

class _ConfirmContent extends StatelessWidget {
  const _ConfirmContent({
    required this.message,
    required this.confirmLabel,
    required this.destructive,
  });

  final String message;
  final String confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Cancel',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(
              child: AppButton(
                label: confirmLabel,
                variant: destructive
                    ? AppButtonVariant.danger
                    : AppButtonVariant.primary,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
