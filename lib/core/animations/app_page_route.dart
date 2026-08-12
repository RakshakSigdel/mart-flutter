import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'animation_constants.dart';

class AppOpenContainer extends StatelessWidget {
  const AppOpenContainer({
    super.key,
    required this.closedBuilder,
    required this.openBuilder,
    this.openColor,
    this.closedElevation = 0,
    this.openElevation = 0,
    this.closedShape,
  });

  final CloseContainerBuilder closedBuilder;
  final OpenContainerBuilder openBuilder;
  final Color? openColor;
  final double closedElevation;
  final double openElevation;
  final ShapeBorder? closedShape;

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionDuration: AppAnimations.slow,
      transitionType: ContainerTransitionType.fadeThrough,
      openColor: openColor ?? AppColors.background,
      closedColor: Colors.transparent,
      closedElevation: closedElevation,
      openElevation: openElevation,
      closedShape:
          closedShape ??
          RoundedRectangleBorder(borderRadius: AppBorderRadius.radiusXL),
      openBuilder: openBuilder,
      closedBuilder: closedBuilder,
    );
  }
}

class AppPageRoute {
  AppPageRoute._();

  // Default transition for most routes
  static Page<T> fadeThrough<T>(GoRouterState state, Widget child) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppAnimations.normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
    );
  }

  // For detail screens that slide in from the right
  static Page<T> sharedAxisHorizontal<T>(GoRouterState state, Widget child) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppAnimations.normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
    );
  }

  /// For drilling *into* a hierarchy in place — steps of a checkout flow,
  /// wizard pages, tabs that own their own routes.
  static Page<T> sharedAxisVertical<T>(GoRouterState state, Widget child) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppAnimations.normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          child: child,
        );
      },
    );
  }

  /// For zooming into a child of the current screen — a product opened from
  /// a grid tile when an [AppOpenContainer] is not practical.
  static Page<T> scaled<T>(GoRouterState state, Widget child) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppAnimations.normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          child: child,
        );
      },
    );
  }

  /// Full-screen sheets: slides up from the bottom edge and back down.
  static Page<T> slideUp<T>(GoRouterState state, Widget child) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppAnimations.normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: AppAnimations.emphasized),
          ),
          child: child,
        );
      },
    );
  }

  /// No animation at all — for the splash route and for redirect targets
  /// where a transition would just look like a flicker.
  static Page<T> none<T>(GoRouterState state, Widget child) {
    return NoTransitionPage<T>(key: state.pageKey, child: child);
  }
}

// ─── Usage ─────────────────────────────────────────────────────────────────
//
// GoRoute(
//   path: Routes.productDetail,
//   pageBuilder: (context, state) =>
//       AppPageRoute.sharedAxisHorizontal(state, const ProductDetailScreen()),
// )
//
// // Card that expands into a full screen:
// AppOpenContainer(
//   closedBuilder: (context, open) => ProductTile(onTap: open),
//   openBuilder: (context, close) => ProductDetailScreen(),
// )
