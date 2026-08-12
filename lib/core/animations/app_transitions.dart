import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'animation_constants.dart';

// ─── Entrance animations ──────────────────────────────────────────────────────

/// Fades [child] in once, when it is first built.
///
/// Use for anything that appears after data loads — a card, a section, an
/// empty state. Pair with [delay] (or [AppStaggered]) to cascade a list.
class AppFadeIn extends StatefulWidget {
  const AppFadeIn({
    super.key,
    required this.child,
    this.duration = AppAnimations.normal,
    this.delay = Duration.zero,
    this.curve = AppAnimations.enter,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  @override
  State<AppFadeIn> createState() => _AppFadeInState();
}

class _AppFadeInState extends State<AppFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
      if (!mounted) return;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: widget.curve),
      child: widget.child,
    );
  }
}

/// Fades [child] in while it settles into place from [direction].
///
/// The travel distance is a fraction of the child's own size
/// ([AppAnimations.slideInOffset]) so it reads as a settle, not a slide.
class AppFadeSlideIn extends StatefulWidget {
  const AppFadeSlideIn({
    super.key,
    required this.child,
    this.duration = AppAnimations.normal,
    this.delay = Duration.zero,
    this.curve = AppAnimations.enter,
    this.direction = AxisDirection.up,
    this.offset = AppAnimations.slideInOffset,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  /// Where the child travels *towards*. [AxisDirection.up] starts below its
  /// final position and rises into it — the usual list/card entrance.
  final AxisDirection direction;

  /// Travel distance as a fraction of the child's own width/height.
  final double offset;

  @override
  State<AppFadeSlideIn> createState() => _AppFadeSlideInState();
}

class _AppFadeSlideInState extends State<AppFadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  Offset get _begin => switch (widget.direction) {
    AxisDirection.up => Offset(0, widget.offset),
    AxisDirection.down => Offset(0, -widget.offset),
    AxisDirection.left => Offset(widget.offset, 0),
    AxisDirection.right => Offset(-widget.offset, 0),
  };

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
      if (!mounted) return;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: _begin, end: Offset.zero)
            .animate(animation),
        child: widget.child,
      ),
    );
  }
}

/// Wraps one item of a list so it enters after the items above it.
///
/// The delay is `index * ` [AppAnimations.staggerStep], capped by [maxIndex]
/// so a long list does not leave the last rows waiting seconds to appear.
///
/// ```dart
/// ListView.builder(
///   itemBuilder: (context, index) => AppStaggered(
///     index: index,
///     child: ProductTile(products[index]),
///   ),
/// )
/// ```
class AppStaggered extends StatelessWidget {
  const AppStaggered({
    super.key,
    required this.index,
    required this.child,
    this.step = AppAnimations.staggerStep,
    this.maxIndex = 10,
    this.direction = AxisDirection.up,
  });

  final int index;
  final Widget child;
  final Duration step;

  /// Items past this index all share the same delay.
  final int maxIndex;

  final AxisDirection direction;

  @override
  Widget build(BuildContext context) {
    final effectiveIndex = index.clamp(0, maxIndex);
    return AppFadeSlideIn(
      delay: step * effectiveIndex,
      direction: direction,
      child: child,
    );
  }
}

/// Scales [child] up from [from] while fading it in — for badges, dialogs
/// and anything that should "pop" rather than drift into place.
class AppScaleIn extends StatelessWidget {
  const AppScaleIn({
    super.key,
    required this.child,
    this.duration = AppAnimations.fast,
    this.from = 0.92,
    this.curve = AppAnimations.emphasized,
  });

  final Widget child;
  final Duration duration;
  final double from;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: from + (1 - from) * t, child: child),
      ),
      child: child,
    );
  }
}

// ─── Interaction animations ───────────────────────────────────────────────────

/// Shrinks [child] slightly while pressed, then springs back on release.
///
/// Use on tappable surfaces that already carry their own visuals (product
/// cards, tiles) where an ink ripple would be lost under the content.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration duration;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: AppAnimations.standard,
        child: widget.child,
      ),
    );
  }
}

/// Cross-fades between whatever [child] currently is, keyed by its widget key.
///
/// Use when a region swaps content in place — loading → loaded, or a value
/// that changes (a cart count, a status pill).
class AppSwitcher extends StatelessWidget {
  const AppSwitcher({
    super.key,
    required this.child,
    this.duration = AppAnimations.fast,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final Duration duration;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppAnimations.enter,
      switchOutCurve: AppAnimations.exit,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: alignment,
        children: [...previousChildren, ?currentChild],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Expands/collapses [child] vertically — for "show more" sections,
/// filter panels, and expandable order rows.
class AppExpandable extends StatelessWidget {
  const AppExpandable({
    super.key,
    required this.expanded,
    required this.child,
    this.duration = AppAnimations.normal,
  });

  final bool expanded;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: AppAnimations.emphasized,
      alignment: Alignment.topCenter,
      child: expanded
          ? child
          : const SizedBox(width: double.infinity, height: 0),
    );
  }
}

// ─── Loading animations ───────────────────────────────────────────────────────

/// A shimmering placeholder block, sized to whatever it is given.
///
/// Build skeleton screens out of these rather than showing a spinner over a
/// blank page — the layout stays stable when the real content arrives.
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
    this.child,
  });

  /// A circular shimmer — for avatar placeholders.
  const AppShimmer.circle({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = null,
      child = null;

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  /// When given, the shimmer sweeps across this widget's shape instead of a
  /// plain rectangle.
  final Widget? child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCircle =
        widget.child == null &&
        widget.borderRadius == null &&
        widget.width == widget.height;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Slide the highlight band from fully off the left to fully off the
        // right. Rebuilding the gradient each frame is cheap — it is three
        // stops — and keeps the sweep independent of the widget's width.
        final t = _controller.value * 2 - 1;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1 + t, 0),
            end: Alignment(1 + t, 0),
            colors: const [
              AppColors.skeletonBase,
              AppColors.skeletonHighlight,
              AppColors.skeletonBase,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: child,
        );
      },
      child:
          widget.child ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.skeletonBase,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle
                  ? null
                  : (widget.borderRadius ?? AppBorderRadius.radiusSM),
            ),
          ),
    );
  }
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// // Section that fades in once data lands:
// AppFadeIn(child: OrderSummary(order: order))
//
// // Staggered list:
// ListView.builder(
//   itemBuilder: (_, i) => AppStaggered(index: i, child: ProductTile(items[i])),
// )
//
// // Tappable product card with a press response:
// AppPressable(onTap: _open, child: AppCard(child: ...))
//
// // Value that changes in place (keys drive the cross-fade):
// AppSwitcher(child: Text('$count', key: ValueKey(count)))
//
// // Skeleton row while loading:
// Row(children: [
//   const AppShimmer.circle(size: 40),
//   const SizedBox(width: 12),
//   const Expanded(child: AppShimmer(height: 14)),
// ])
