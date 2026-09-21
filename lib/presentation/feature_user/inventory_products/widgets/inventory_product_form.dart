import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../data/models/models_user/inventory_units_model.dart';
import '../../../shared/widgets/section_ui.dart';
import '../controllers/inventory_products_controller.dart';

/// Add/edit form for one product. Calls [Navigator.pop] with `true` when
/// the save succeeds, so the caller (`InventoryProductFormScreen`) can show
/// a snackbar with a context that's guaranteed to still be mounted.
///
/// Plain content — no page chrome of its own. Hosted by
/// `InventoryProductFormScreen` rather than a dialog, for the same reason
/// as `StaffForm`/`AdminForm`.
///
/// Category and base unit are only ever shown on create — the backend
/// fixes both at creation and won't accept them in an edit request, so
/// [product] (when editing) only needs the fields that *are* editable plus
/// enough of the fixed ones to display for context.
class InventoryProductForm extends ConsumerStatefulWidget {
  const InventoryProductForm({super.key, this.product});

  /// Null for "add a new product"; the product being edited otherwise.
  final ProductDetailModel? product;

  bool get isEditing => product != null;

  @override
  ConsumerState<InventoryProductForm> createState() =>
      _InventoryProductFormState();
}

class _InventoryProductFormState extends ConsumerState<InventoryProductForm> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.product?.name);
  late final _productCode = TextEditingController(
    text: widget.product?.productCode,
  );
  late final _baseCode = TextEditingController(text: widget.product?.baseCode);
  late final _description = TextEditingController(
    text: widget.product?.description,
  );
  late final _brand = TextEditingController(text: widget.product?.brand);
  late final _image = TextEditingController(text: widget.product?.image);

  InventoryCategoryModel? _category;
  InventoryUnitModel? _baseUnit;
  bool _active = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _active = widget.product?.active ?? true;
    if (!widget.isEditing) {
      ref
          .read(inventoryProductsControllerProvider.notifier)
          .ensureUnitOptionsLoaded();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _productCode.dispose();
    _baseCode.dispose();
    _description.dispose();
    _brand.dispose();
    _image.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = ref.read(inventoryProductsControllerProvider.notifier);

    if (!widget.isEditing) {
      final category = _category;
      final baseUnit = _baseUnit;
      if (category == null || baseUnit == null) {
        setState(() => _errorMessage = 'Category and base unit are required');
        return;
      }
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      if (widget.isEditing) {
        await controller.updateProduct(
          widget.product!.id,
          UpdateProductRequest(
            name: _name.text.trim(),
            productCode: _emptyToNull(_productCode.text),
            baseCode: _emptyToNull(_baseCode.text),
            description: _emptyToNull(_description.text),
            brand: _emptyToNull(_brand.text),
            image: _emptyToNull(_image.text),
            active: _active,
          ),
        );
      } else {
        await controller.createProduct(
          CreateProductRequest(
            name: _name.text.trim(),
            productCode: _emptyToNull(_productCode.text),
            baseCode: _emptyToNull(_baseCode.text),
            description: _emptyToNull(_description.text),
            brand: _emptyToNull(_brand.text),
            image: _emptyToNull(_image.text),
            categoryId: _category!.id,
            baseUnitId: _baseUnit!.id,
          ),
        );
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
    final categoryOptions = ref.watch(
      inventoryProductsControllerProvider.select((s) => s.categoryOptions),
    );
    // A product's base unit must be its measurement type's reference unit
    // (e.g. grams, not kilograms) — everything else (purchase/selling
    // units) is expressed as a conversion against it, so letting a
    // non-reference unit be picked here would break that relationship.
    final baseUnitOptions = ref
        .watch(inventoryProductsControllerProvider.select((s) => s.unitOptions))
        .where((unit) => unit.referenceUnit)
        .toList();

    return Form(
      key: _formKey,
      child: SectionPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionPanelHeader(
              icon: widget.isEditing
                  ? Icons.edit_note_rounded
                  : Icons.add_box_rounded,
              eyebrow: widget.isEditing ? 'EDIT PRODUCT' : 'NEW PRODUCT',
              subtitle: widget.isEditing
                  ? widget.product?.name ?? 'Update this product'
                  : 'Add a product to the catalogue',
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildFields(categoryOptions, baseUnitOptions),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surfaceSunken,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppFormError(message: _errorMessage),
                  if (_errorMessage != null)
                    const SizedBox(height: AppSpacing.sm),
                  BrandActionButton(
                    label: widget.isEditing ? 'Save changes' : 'Add product',
                    icon: Icons.check_circle_outline_rounded,
                    loading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFields(
    List<InventoryCategoryModel> categoryOptions,
    List<InventoryUnitModel> baseUnitOptions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isEditing) ...[
          _SectionLabel('Fixed at creation'),
          _ReadOnlyRow(
            label: 'Category',
            value: widget.product?.categoryName ?? 'Not set',
            icon: Icons.category_outlined,
          ),
          _ReadOnlyRow(
            label: 'Base unit',
            value: widget.product?.baseUnit == null
                ? 'Not set'
                : '${widget.product!.baseUnit!.name} (${widget.product!.baseUnit!.symbol})',
            icon: Icons.straighten_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel('Details'),
        ] else ...[
          _SectionLabel('Category & base unit'),
          AppSearchableDropdownField<InventoryCategoryModel>(
            label: 'Category',
            selectedItem: _category,
            items: categoryOptions,
            itemLabel: (c) => c.name,
            hint: 'Select a category',
            onChanged: (value) => setState(() => _category = value),
            validator: (value) => value == null ? 'Category is required' : null,
          ),
          const SizedBox(height: AppSpacing.smMd),
          AppSearchableDropdownField<InventoryUnitModel>(
            label: 'Base unit',
            selectedItem: _baseUnit,
            items: baseUnitOptions,
            itemLabel: (u) => '${u.name} (${u.symbol})',
            hint: 'Select a unit',
            onChanged: (value) => setState(() => _baseUnit = value),
            validator: (value) =>
                value == null ? 'Base unit is required' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel('Details'),
        ],
        AppTextField(
          controller: _name,
          label: 'Name',
          enabled: !_submitting,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
        ),
        const SizedBox(height: AppSpacing.smMd),
        AppTextField(
          controller: _productCode,
          label: 'Product code',
          enabled: !_submitting,
        ),
        const SizedBox(height: AppSpacing.smMd),
        AppTextField(
          controller: _baseCode,
          label: 'Base code',
          enabled: !_submitting,
        ),
        const SizedBox(height: AppSpacing.smMd),
        AppTextField(controller: _brand, label: 'Brand', enabled: !_submitting),
        const SizedBox(height: AppSpacing.smMd),
        AppTextField.multiline(
          controller: _description,
          label: 'Description',
          enabled: !_submitting,
        ),
        const SizedBox(height: AppSpacing.smMd),
        AppTextField(
          controller: _image,
          label: 'Image URL',
          hint: 'https://…',
          keyboardType: TextInputType.url,
          enabled: !_submitting,
        ),
        if (widget.isEditing) ...[
          const SizedBox(height: AppSpacing.smMd),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppBorderRadius.radiusL,
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.radiusL,
              ),
              title: Text(
                'Active',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                _active
                    ? 'Shown on the till and in listings.'
                    : 'Hidden from the till and listings.',
                style: AppTypography.caption,
              ),
              value: _active,
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _active = value),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text.toUpperCase(), style: AppTypography.eyebrow),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.smMd),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.iconInactive),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
