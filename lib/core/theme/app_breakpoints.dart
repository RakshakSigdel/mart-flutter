import 'package:flutter/widgets.dart';

/// Responsive width breakpoints for the AYGH design system.
/// All screens/widgets that adapt layout by available width must read
/// their thresholds from here instead of inlining raw numbers.
class AppBreakpoints {
  AppBreakpoints._();

  /// Below this width: single-column / stacked phone layout.
  static const double tablet = 600.0;

  /// Below this width (and >= [tablet]): tablet layout.
  /// At or above this width: desktop layout.
  static const double desktop = 1000.0;

  /// Minimum content width for two dashboard report cards with return metrics.
  static const double reportCardsTwoColumn = 1100.0;

  /// Wide desktop / large monitor layout.
  static const double desktopLarge = 1400.0;

  /// Max width for centered page content (nav bars, page bodies) on very
  /// wide screens, so layouts don't stretch edge-to-edge.
  static const double contentMaxWidth = 1200.0;

  static bool isPhone(double width) => width < tablet;

  static bool isTablet(double width) => width >= tablet && width < desktop;

  static bool isDesktop(double width) => width >= desktop;
}

/// Resolves a value based on the current [width] against the three
/// standard breakpoints. Prefer this over ad-hoc `if (width > ...)` chains
/// so every screen shares the same thresholds.
T responsiveValue<T>({
  required double width,
  required T phone,
  T? tablet,
  T? desktop,
}) {
  if (width >= AppBreakpoints.desktop) return desktop ?? tablet ?? phone;
  if (width >= AppBreakpoints.tablet) return tablet ?? phone;
  return phone;
}

/// Builds different widgets per breakpoint using the current [BuildContext]
/// width (via [MediaQuery]). Use [LayoutBuilder] instead when the available
/// width should come from the parent constraints rather than the screen.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) phone;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppBreakpoints.desktop) {
      return (desktop ?? tablet ?? phone)(context);
    }
    if (width >= AppBreakpoints.tablet) {
      return (tablet ?? phone)(context);
    }
    return phone(context);
  }
}
