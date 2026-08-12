import 'package:flutter/material.dart';

import '../animations/app_transitions.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A centered brand spinner with an optional caption.
///
/// Prefer a skeleton ([AppListSkeleton], [AppCardSkeleton]) when the shape of
/// the incoming content is known — the layout then does not jump when it
/// arrives. Use this spinner for short, shape-less waits.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.message, this.size = 28});

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.smMd),
            Text(
              message!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Blocks the screen while an action completes — submitting an order,
/// signing in. Show it with [showAppLoadingOverlay] and dismiss by popping.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: ColoredBox(
        color: AppColors.modalBarrier,
        child: Center(
          child: AppScaleIn(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppBorderRadius.radiusXL,
              ),
              child: AppLoader(message: message),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a blocking [AppLoadingOverlay]. Dismiss with `Navigator.pop(context)`
/// — ideally from a `finally` block so a thrown error cannot strand it.
Future<void> showAppLoadingOverlay(BuildContext context, {String? message}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    builder: (_) => AppLoadingOverlay(message: message),
  );
}

/// A skeleton standing in for one card of content.
class AppCardSkeleton extends StatelessWidget {
  const AppCardSkeleton({super.key, this.lines = 3, this.hasThumbnail = true});

  final int lines;
  final bool hasThumbnail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.mdLg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppBorderRadius.radiusXL,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasThumbnail) ...[
            AppShimmer(
              width: 56,
              height: 56,
              borderRadius: AppBorderRadius.radiusMD,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    // Ragged widths read as text; equal bars read as a table.
                    widthFactor: i == 0 ? 0.6 : (i.isEven ? 0.9 : 0.75),
                    child: const AppShimmer(height: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A column of [AppCardSkeleton]s — the default "list is loading" view.
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({
    super.key,
    this.itemCount = 5,
    this.lines = 2,
    this.hasThumbnail = true,
    this.padding,
  });

  final int itemCount;
  final int lines;
  final bool hasThumbnail;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.smMd),
      itemBuilder: (_, _) =>
          AppCardSkeleton(lines: lines, hasThumbnail: hasThumbnail),
    );
  }
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// // Short, shape-less wait:
// const AppLoader(message: 'Loading orders…')
//
// // List placeholder that matches the real layout:
// const AppListSkeleton(itemCount: 6)
//
// // Blocking action:
// showAppLoadingOverlay(context, message: 'Placing order…');
// try {
//   await api.placeOrder();
// } finally {
//   if (context.mounted) Navigator.pop(context);
// }
