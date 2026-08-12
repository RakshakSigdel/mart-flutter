import 'package:flutter/animation.dart';

/// Motion tokens for the Rakshak Mart design system.
///
/// Every animated widget reads its duration and curve from here, so the whole
/// app can be re-timed from one file.
class AppAnimations {
  AppAnimations._();

  // Durations
  /// 100ms — state flips that should feel instant: press, hover, ripple.
  static const Duration instant = Duration(milliseconds: 100);

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);

  /// 700ms — deliberate, once-per-screen motion (splash, hero reveal).
  static const Duration deliberate = Duration(milliseconds: 700);

  // Curves
  static const Curve standard = Curves.easeInOut;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  // Staggered list/grid entrance animations
  /// Extra delay added per item index in a staggered fade/slide-in list.
  static const Duration staggerStep = Duration(milliseconds: 50);

  /// Fractional offset (of the item's own height) used for slide-in-on-load
  /// animations — small enough to read as a settle, not a slide.
  static const double slideInOffset = 0.05;

  /// Delay for the item at [index] in a staggered list, capped at [maxIndex]
  /// so long lists do not leave the last rows waiting.
  static Duration stagger(int index, {int maxIndex = 10}) =>
      staggerStep * index.clamp(0, maxIndex);

  /// Scale applied to a surface while it is pressed.
  static const double pressedScale = 0.97;
}
