import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';
import '../controllers/inventory_categories_controller.dart';
import 'category_image_search_dialog.dart';
import 'inventory_category_thumbnail.dart';

/// Add/edit form for one category. Calls [Navigator.pop] with `true` when
/// the save succeeds, so the caller (`InventoryCategoryFormScreen`) can show
/// a snackbar with a context that's guaranteed to still be mounted.
///
/// Plain content — no page chrome of its own. Hosted by
/// `InventoryCategoryFormScreen` rather than a dialog, for the same reason
/// as `StaffForm`/`AdminForm`.
class InventoryCategoryForm extends ConsumerStatefulWidget {
  const InventoryCategoryForm({super.key, this.category});

  /// Null for "add a new category"; the category being edited otherwise.
  final InventoryCategoryModel? category;

  bool get isEditing => category != null;

  @override
  ConsumerState<InventoryCategoryForm> createState() =>
      _InventoryCategoryFormState();
}

class _InventoryCategoryFormState extends ConsumerState<InventoryCategoryForm> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.category?.name);
  late final _description = TextEditingController(
    text: widget.category?.description,
  );
  late String? _imageUrl = widget.category?.image;

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    final imageUrl = await showDialog<String>(
      context: context,
      builder: (context) =>
          CategoryImageSearchDialog(initialQuery: _name.text.trim()),
    );
    if (!mounted || imageUrl == null) return;
    setState(() => _imageUrl = imageUrl);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final controller = ref.read(inventoryCategoriesControllerProvider.notifier);
    final request = UpsertInventoryCategoryRequest(
      name: _name.text.trim(),
      description: _emptyToNull(_description.text),
      image: _imageUrl,
    );
    try {
      if (widget.isEditing) {
        await controller.updateCategory(widget.category!.id, request);
      } else {
        await controller.createCategory(request);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static String? _emptyToNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isEditing) ...[
            const Text(
              'Only a category name is needed. You can skip the details below.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.smMd),
          ],
          AppTextField(
            controller: _name,
            label: 'Category name',
            hint: 'e.g. Beverages',
            enabled: !_submitting,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppTextField.multiline(
            controller: _description,
            label: 'Description',
            enabled: !_submitting,
          ),
          const SizedBox(height: AppSpacing.smMd),
          Text('Category image', style: AppTypography.fieldLabel),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              InventoryCategoryThumbnail(imageUrl: _imageUrl, size: 72),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _imageUrl == null
                          ? 'No image selected'
                          : 'Image selected',
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Search for a photo and use it for this category.',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: _imageUrl == null ? 'Find an image' : 'Change image',
                variant: AppButtonVariant.secondary,
                leading: const Icon(Icons.image_search_outlined, size: 18),
                onPressed: _submitting ? null : _chooseImage,
              ),
              if (_imageUrl != null)
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _imageUrl = null),
                  child: const Text('Remove image'),
                ),
            ],
          ),
          AppFormError(message: _errorMessage),
          const SizedBox(height: AppSpacing.xl),
          AppButton.expanded(
            label: widget.isEditing ? 'Save changes' : 'Add category',
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
