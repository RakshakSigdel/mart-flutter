import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';

/// Renders a unit's `measurementType` as a plain (unfilled) [AppBadge] —
/// every type reads the same way, there's no success/warning/error axis.
class MeasurementTypeBadge extends StatelessWidget {
  const MeasurementTypeBadge({super.key, required this.type});

  final UnitMeasurementType? type;

  @override
  Widget build(BuildContext context) {
    return AppBadge(label: type?.label ?? 'Unknown', tone: AppBadgeTone.neutral);
  }
}

/// Marks a unit as system-seeded — shown only when true, since "not system"
/// (i.e. mart-defined) is the common case and doesn't need a badge of its
/// own.
class SystemUnitBadge extends StatelessWidget {
  const SystemUnitBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppBadge(
      label: 'System',
      tone: AppBadgeTone.info,
      icon: Icons.verified_outlined,
    );
  }
}

/// Marks the unit its measurement type's others convert against — shown
/// only when true, for the same reason as [SystemUnitBadge].
class ReferenceUnitBadge extends StatelessWidget {
  const ReferenceUnitBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppBadge(
      label: 'Reference',
      tone: AppBadgeTone.tertiary,
      icon: Icons.star_outline_rounded,
    );
  }
}
