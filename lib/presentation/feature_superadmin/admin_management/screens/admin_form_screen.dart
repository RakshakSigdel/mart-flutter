import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_superadmin/admin_model.dart';
import '../../../../providers/providers_superadmin/admin_provider.dart';
import '../widgets/admin_form.dart';

/// Full-page create/edit screen — pushed on top of [AdminManagementScreen]
/// rather than shown as a dialog, since the form has too many fields for a
/// modal/bottom-sheet to stay comfortable.
///
/// Edit mode prefers [initialAdmin] (handed over by the list screen, which
/// already has the record — avoids a redundant fetch) and only falls back to
/// `GET /superadmin/admins/{id}` when it's missing, e.g. a direct/refreshed
/// URL on web where nothing was handed over.
class AdminFormScreen extends ConsumerStatefulWidget {
  const AdminFormScreen({super.key, this.adminId, this.initialAdmin});

  /// Null for "create a new mart".
  final String? adminId;

  /// The mart record to prefill with, if the caller already has it.
  final AdminModel? initialAdmin;

  bool get isEditing => adminId != null;

  @override
  ConsumerState<AdminFormScreen> createState() => _AdminFormScreenState();
}

class _AdminFormScreenState extends ConsumerState<AdminFormScreen> {
  late Future<AdminModel?> _adminFuture = _resolveAdmin();

  Future<AdminModel?> _resolveAdmin() async {
    final id = widget.adminId;
    if (id == null) return null;
    return widget.initialAdmin ?? ref.read(adminRemoteDataSourceProvider).getById(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.isEditing ? 'Edit mart' : 'New mart'),
      ),
      body: FutureBuilder<AdminModel?>(
        future: _adminFuture,
        builder: (context, snapshot) {
          if (widget.isEditing && snapshot.connectionState != ConnectionState.done) {
            return const AppLoader();
          }
          if (widget.isEditing && snapshot.hasError) {
            return AppEmptyState.error(
              message: 'Could not load this mart.',
              onAction: () => setState(() => _adminFuture = _resolveAdmin()),
            );
          }
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: AdminForm(admin: snapshot.data),
              ),
            ),
          );
        },
      ),
    );
  }
}
