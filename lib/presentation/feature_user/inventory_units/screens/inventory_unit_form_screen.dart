import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../../../../providers/providers_user/inventory_units_provider.dart';
import '../widgets/inventory_unit_form.dart';

/// Full-page add/edit screen — pushed on top of [InventoryUnitsScreen]
/// rather than shown as a dialog, matching the pattern used for staff and
/// mart forms.
///
/// Edit mode prefers [initialUnit] (handed over by the list screen, which
/// already has the record — avoids a redundant fetch) and only falls back
/// to `GET /inventory/units/{id}` when it's missing, e.g. a direct/refreshed
/// URL on web where nothing was handed over.
class InventoryUnitFormScreen extends ConsumerStatefulWidget {
  const InventoryUnitFormScreen({super.key, this.unitId, this.initialUnit});

  /// Null for "add a new unit".
  final int? unitId;

  /// The unit record to prefill with, if the caller already has it.
  final InventoryUnitModel? initialUnit;

  bool get isEditing => unitId != null;

  @override
  ConsumerState<InventoryUnitFormScreen> createState() => _InventoryUnitFormScreenState();
}

class _InventoryUnitFormScreenState extends ConsumerState<InventoryUnitFormScreen> {
  late Future<InventoryUnitModel?> _unitFuture = _resolveUnit();

  Future<InventoryUnitModel?> _resolveUnit() async {
    final id = widget.unitId;
    if (id == null) return null;
    return widget.initialUnit ?? ref.read(inventoryUnitsRemoteDataSourceProvider).getById(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.isEditing ? 'Edit unit' : 'Add unit'),
      ),
      body: FutureBuilder<InventoryUnitModel?>(
        future: _unitFuture,
        builder: (context, snapshot) {
          if (widget.isEditing && snapshot.connectionState != ConnectionState.done) {
            return const AppLoader();
          }
          if (widget.isEditing && snapshot.hasError) {
            return AppEmptyState.error(
              message: 'Could not load this unit.',
              onAction: () => setState(() => _unitFuture = _resolveUnit()),
            );
          }
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: InventoryUnitForm(unit: snapshot.data),
              ),
            ),
          );
        },
      ),
    );
  }
}
