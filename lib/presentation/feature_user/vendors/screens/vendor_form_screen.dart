import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/vendor_model.dart';
import '../../../../providers/providers_user/vendor_provider.dart';
import '../widgets/vendor_form.dart';

/// Full-page add/edit screen — pushed on top of [VendorsScreen] rather
/// than shown as a dialog, matching the pattern used for staff/unit/
/// category/mart forms.
///
/// Edit mode prefers [initialVendor] (handed over by whichever screen
/// already has the record — the vendors list or the vendor detail page)
/// and only falls back to `GET /vendors/{id}` when it's missing, e.g. a
/// direct/refreshed URL on web where nothing was handed over.
class VendorFormScreen extends ConsumerStatefulWidget {
  const VendorFormScreen({super.key, this.vendorId, this.initialVendor});

  /// Null for "add a new vendor".
  final int? vendorId;

  /// The vendor record to prefill with, if the caller already has it.
  final VendorModel? initialVendor;

  bool get isEditing => vendorId != null;

  @override
  ConsumerState<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends ConsumerState<VendorFormScreen> {
  late Future<VendorModel?> _vendorFuture = _resolveVendor();

  Future<VendorModel?> _resolveVendor() async {
    final id = widget.vendorId;
    if (id == null) return null;
    return widget.initialVendor ??
        ref.read(vendorRemoteDataSourceProvider).getById(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.isEditing ? 'Edit vendor' : 'Add vendor'),
      ),
      body: FutureBuilder<VendorModel?>(
        future: _vendorFuture,
        builder: (context, snapshot) {
          if (widget.isEditing &&
              snapshot.connectionState != ConnectionState.done) {
            return const AppLoader();
          }
          if (widget.isEditing && snapshot.hasError) {
            return AppEmptyState.error(
              message: 'Could not load this vendor.',
              onAction: () => setState(() => _vendorFuture = _resolveVendor()),
            );
          }
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: VendorForm(vendor: snapshot.data),
              ),
            ),
          );
        },
      ),
    );
  }
}
