import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Shows an [AppModal] as a bottom sheet or center dialog.
/// Matches the web `<Modal />` component in structure, padding, and style.
///
/// Prefer this over [showDialog] directly so all modals share the same look.
Future<T?> showAppModal<T>({
  required BuildContext context,
  required Widget content,
  String? title,
  bool dismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.modalBarrier,
    builder: (sheetContext) => AppModal(
      title: title,
      onClose: () => Navigator.of(sheetContext).pop(),
      child: content,
    ),
  );
}

/// Shows [AppModal] as a centered dialog (matches the web behavior exactly).
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required Widget content,
  String? title,
  bool dismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierColor: AppColors.modalBarrier,
    builder: (dialogContext) => AppModal(
      title: title,
      onClose: () => Navigator.of(dialogContext).pop(),
      child: content,
    ),
  );
}

/// The modal surface widget.
/// Can be used standalone inside [showDialog] or via [showAppModal].
///
/// Matches the web Modal component:
///   - backdrop: black/45, backdrop-blur
///   - surface: rounded-[1.25rem], white, shadow-2xl
///   - header: border-b, title + close button
///   - content: max-h-[82vh], scrollable, px-5 py-5
class AppModal extends StatelessWidget {
  const AppModal({
    super.key,
    required this.child,
    required this.onClose,
    this.title,
    this.maxHeight,
  });

  final Widget child;
  final VoidCallback onClose;

  /// Optional title shown in the header with a close button.
  /// When null, a floating close button is shown in the top-right corner.
  final String? title;

  /// Maximum height of the scrollable content area.
  /// Defaults to 82% of screen height (matches web max-h-[82vh]).
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final contentMaxHeight = maxHeight ?? screenHeight * 0.82;

    return Center(
      child: Material(
        color: AppColors.card,
        borderRadius: AppBorderRadius.radiusXL,
        elevation: 0,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.smMd),
          constraints: const BoxConstraints(maxWidth: 512), // matches max-w-lg
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppBorderRadius.radiusXL,
            boxShadow: AppShadows.modal,
          ),
          child: ClipRRect(
            borderRadius: AppBorderRadius.radiusXL,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                if (title != null)
                  _ModalHeader(title: title!, onClose: onClose),

                // Floating close button (when no title)
                if (title == null)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        right: AppSpacing.md,
                      ),
                      child: _CloseButton(onClose: onClose),
                    ),
                  ),

                // Scrollable content
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: contentMaxHeight),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.mdLg),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.mdLg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTypography.subtitle)),
          const SizedBox(width: AppSpacing.sm),
          _CloseButton(onClose: onClose),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppBorderRadius.radiusMD,
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          onClose();
        },
        borderRadius: AppBorderRadius.radiusMD,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(Icons.close, size: 20, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// // As a dialog (centered, matches web exactly):
// showAppDialog(
//   context: context,
//   title: 'Add Player',
//   content: AddPlayerForm(onSubmit: _submit),
// )
//
// // As a bottom sheet (better UX on mobile):
// showAppModal(
//   context: context,
//   title: 'Filter',
//   content: FilterOptions(onApply: _applyFilters),
// )
//
// // Getting the result back:
// final result = await showAppDialog<Player>(
//   context: context,
//   title: 'Select Club',
//   content: ClubPickerModal(onSelect: (club) => Navigator.pop(context, club)),
// );
// if (result != null) { ... }
//
// // Without a title (floating close button):
// showAppDialog(
//   context: context,
//   content: PlayerDetailCard(player: player),
// )
