import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/staff_model.dart';
import '../../../../providers/providers_user/staff_provider.dart';
import '../widgets/staff_form.dart';

/// Full-page hire/edit screen — pushed on top of [StaffManagementScreen]
/// rather than shown as a dialog, since the form has too many fields for a
/// modal/bottom-sheet to stay comfortable.
///
/// Edit mode prefers [initialStaff] (handed over by the list screen, which
/// already has the record — avoids a redundant fetch) and only falls back to
/// `GET /admin/staff/{id}` when it's missing, e.g. a direct/refreshed URL on
/// web where nothing was handed over.
class StaffFormScreen extends ConsumerStatefulWidget {
  const StaffFormScreen({super.key, this.staffId, this.initialStaff});

  /// Null for "hire a new staff member".
  final String? staffId;

  /// The staff record to prefill with, if the caller already has it.
  final StaffModel? initialStaff;

  bool get isEditing => staffId != null;

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen> {
  late Future<StaffModel?> _staffFuture = _resolveStaff();

  Future<StaffModel?> _resolveStaff() async {
    final id = widget.staffId;
    if (id == null) return null;
    return widget.initialStaff ?? ref.read(staffRemoteDataSourceProvider).getById(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.isEditing ? 'Edit staff' : 'Hire staff'),
      ),
      body: FutureBuilder<StaffModel?>(
        future: _staffFuture,
        builder: (context, snapshot) {
          if (widget.isEditing && snapshot.connectionState != ConnectionState.done) {
            return const AppLoader();
          }
          if (widget.isEditing && snapshot.hasError) {
            return AppEmptyState.error(
              message: 'Could not load this staff member.',
              onAction: () => setState(() => _staffFuture = _resolveStaff()),
            );
          }
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: StaffForm(staff: snapshot.data),
              ),
            ),
          );
        },
      ),
    );
  }
}
