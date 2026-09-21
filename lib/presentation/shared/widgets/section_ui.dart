/// Shared chrome for the POS flow.
///
/// Every step is built from the same three pieces — a floating [SectionPanel], a
/// soft-yellow [SectionPanelHeader] on top of it, and a yellow [BrandActionButton]
/// for the one action that moves the sale forward — so product selection,
/// payment and the receipt all read as one screen.
library;

import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// The floating card every POS panel sits in.
///
/// The fill is a [Material] rather than a plain box so that ink splashes from
/// the controls inside (list tiles, steppers, pills) land on the panel itself
/// instead of being hidden behind it. The outer box carries only the shadow.
class SectionPanel extends StatelessWidget {
  const SectionPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.radiusXL,
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusXL,
          side: const BorderSide(color: AppColors.border),
        ),
        child: child,
      ),
    );
  }
}

/// The soft-yellow header strip that titles a [SectionPanel].
class SectionPanelHeader extends StatelessWidget {
  const SectionPanelHeader({
    super.key,
    required this.icon,
    required this.eyebrow,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.backTooltip = 'Back',
  });

  final IconData icon;

  /// Short all-caps label, e.g. "CURRENT SALE".
  final String eyebrow;
  final String? subtitle;
  final Widget? trailing;

  /// When set, a round back button is shown ahead of the icon.
  final VoidCallback? onBack;
  final String backTooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.smMd,
      ),
      decoration: const BoxDecoration(
        gradient: AppGradients.softPrimary,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            Tooltip(
              message: backTooltip,
              child: Material(
                color: AppColors.card,
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onBack,
                  hoverColor: AppColors.primarySoft,
                  child: const SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.smMd),
          ],
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: AppBorderRadius.radiusMD,
              boxShadow: AppShadows.button,
            ),
            child: Icon(icon, size: 20, color: AppColors.textOnPrimary),
          ),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eyebrow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.eyebrow.copyWith(
                    color: AppColors.primaryDeep,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// A small counter/status pill sized for a [SectionPanelHeader]'s trailing slot.
class SectionBadge extends StatelessWidget {
  const SectionBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppSwitcher(
      child: Container(
        key: ValueKey(label),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smMd,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppBorderRadius.radiusFull,
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Text(
          label,
          style: AppTypography.priceSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// The yellow gradient call-to-action that advances the sale.
class BrandActionButton extends StatelessWidget {
  const BrandActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: AppBorderRadius.radiusL,
        boxShadow: AppShadows.button,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: AppBorderRadius.radiusL,
          splashColor: AppColors.accent.withValues(alpha: 0.08),
          // Keyboard users reach this button by arrow keys, so its focused
          // state has to be visible on the yellow fill.
          focusColor: AppColors.accent.withValues(alpha: 0.14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                else ...[
                  // Flexible + ellipsis: some labels are bilingual and must
                  // never overflow the button on a narrow till screen.
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.label.copyWith(
                        fontSize: 15,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(icon, size: 18, color: AppColors.textOnPrimary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Centers [child] in the space available, but scrolls instead of overflowing
/// when the panel is shorter than the content — stacked phone layouts leave
/// a panel very little height once its header and totals footer are placed.
class CenterOrScroll extends StatelessWidget {
  const CenterOrScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 0,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// The paging footer that closes a [SectionPanel] holding a list or table.
class SectionPaginationBar extends StatelessWidget {
  const SectionPaginationBar({
    super.key,
    required this.pageNumber,
    required this.totalPages,
    required this.totalElements,
    required this.itemNoun,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  /// Already 1-indexed, matching the backend's own paging.
  final int pageNumber;
  final int totalPages;
  final int totalElements;

  /// Singular name of what is being paged, e.g. "product".
  final String itemNoun;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSunken,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              totalPages == 0
                  ? 'No results'
                  : 'Page $pageNumber of $totalPages · $totalElements'
                        ' $itemNoun${totalElements == 1 ? '' : 's'}',
              style: AppTypography.caption,
            ),
          ),
          _PageButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Previous page',
            onPressed: hasPrevious ? onPrevious : null,
          ),
          const SizedBox(width: AppSpacing.xs),
          _PageButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Next page',
            onPressed: hasNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? AppColors.card : AppColors.btnDisabled,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.radiusMD,
          side: BorderSide(
            color: enabled ? AppColors.borderStrong : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          hoverColor: AppColors.primarySoft,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? AppColors.textPrimary
                  : AppColors.btnDisabledText,
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable pill — category filters, quick-cash shortcuts.
///
/// Selected pills take the brand gradient; the rest stay white so a row of
/// them reads as one control with a single active choice.
class BrandPill extends StatelessWidget {
  const BrandPill({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
  });

  final String label;

  /// A null callback renders the pill as disabled.
  final VoidCallback? onTap;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final foreground = selected
        ? AppColors.textOnPrimary
        : enabled
        ? AppColors.textSecondary
        : AppColors.btnDisabledText;

    return AppPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smMd,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.primary : null,
          color: selected
              ? null
              : enabled
              ? AppColors.card
              : AppColors.btnDisabled,
          borderRadius: AppBorderRadius.radiusFull,
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.border,
          ),
          boxShadow: selected ? AppShadows.button : AppShadows.none,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 13,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A keyboard-shortcut hint rendered as a small key cap plus its action.
/// Sized for the totals footers, where the POS shortcuts are advertised.
class KeyHint extends StatelessWidget {
  const KeyHint({super.key, required this.keyLabel, required this.action});

  final String keyLabel;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppBorderRadius.radiusXS,
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Text(
            keyLabel,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(action, style: AppTypography.caption),
      ],
    );
  }
}

/// A label/value line for the totals footers.
class TotalLine extends StatelessWidget {
  const TotalLine({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: emphasize
                    ? AppColors.textSecondary
                    : AppColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.priceSmall.copyWith(
              color: emphasize ? AppColors.primaryDeep : AppColors.textPrimary,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
