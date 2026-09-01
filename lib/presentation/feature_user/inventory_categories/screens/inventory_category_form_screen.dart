import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';
import '../../../../providers/providers_user/inventory_categories_provider.dart';
import '../widgets/inventory_category_form.dart';

/// Full-page add/edit screen — pushed on top of [InventoryCategoriesScreen]
/// rather than shown as a dialog, matching the pattern used for staff, mart
/// and unit forms.
///
/// Edit mode prefers [initialCategory] (handed over by the list screen,
/// which already has the record — avoids a redundant fetch) and only falls
/// back to `GET /inventory/categories/{id}` when it's missing, e.g. a
/// direct/refreshed URL on web where nothing was handed over. That fetch
/// returns the full detail shape, but only the shared summary fields
/// (name/description/image) are used here — unit policy is the detail
/// screen's job.
class InventoryCategoryFormScreen extends ConsumerStatefulWidget {
  const InventoryCategoryFormScreen({super.key, this.categoryId, this.initialCategory});

  /// Null for "add a new category".
  final int? categoryId;

  /// The category record to prefill with, if the caller already has it.
  final InventoryCategoryModel? initialCategory;

  bool get isEditing => categoryId != null;

  @override
  ConsumerState<InventoryCategoryFormScreen> createState() =>
      _InventoryCategoryFormScreenState();
}

class _InventoryCategoryFormScreenState extends ConsumerState<InventoryCategoryFormScreen> {
  late Future<InventoryCategoryModel?> _categoryFuture = _resolveCategory();

  Future<InventoryCategoryModel?> _resolveCategory() async {
    final id = widget.categoryId;
    if (id == null) return null;
    if (widget.initialCategory != null) return widget.initialCategory;
    final detail = await ref.read(inventoryCategoriesRemoteDataSourceProvider).getById(id);
    return detail.summary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.isEditing ? 'Edit category' : 'Add category'),
      ),
      body: FutureBuilder<InventoryCategoryModel?>(
        future: _categoryFuture,
        builder: (context, snapshot) {
          if (widget.isEditing && snapshot.connectionState != ConnectionState.done) {
            return const AppLoader();
          }
          if (widget.isEditing && snapshot.hasError) {
            return AppEmptyState.error(
              message: 'Could not load this category.',
              onAction: () => setState(() => _categoryFuture = _resolveCategory()),
            );
          }
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: InventoryCategoryForm(category: snapshot.data),
              ),
            ),
          );
        },
      ),
    );
  }
}
