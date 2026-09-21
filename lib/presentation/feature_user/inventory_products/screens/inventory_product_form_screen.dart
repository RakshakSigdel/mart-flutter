import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../providers/providers_user/inventory_products_provider.dart';
import '../widgets/inventory_product_form.dart';
import '../widgets/quick_product_form.dart';

/// Full-page add/edit screen — pushed on top of [InventoryProductsScreen]
/// rather than shown as a dialog, matching the pattern used for every
/// other top-level entity form this app has.
///
/// Unlike staff/mart/category/unit edit screens, this always fetches the
/// full record via `GET /inventory/products/{id}` rather than accepting a
/// prefill from the caller — the list only ever has [ProductModel]
/// summaries, which don't carry `baseUnit`, and the edit form needs that
/// to show the "fixed at creation" fields for context.
class InventoryProductFormScreen extends ConsumerStatefulWidget {
  const InventoryProductFormScreen({super.key, this.productId});

  /// Null for "add a new product".
  final int? productId;

  bool get isEditing => productId != null;

  @override
  ConsumerState<InventoryProductFormScreen> createState() =>
      _InventoryProductFormScreenState();
}

class _InventoryProductFormScreenState
    extends ConsumerState<InventoryProductFormScreen> {
  late Future<ProductDetailModel?> _productFuture = _resolveProduct();

  Future<ProductDetailModel?> _resolveProduct() async {
    final id = widget.productId;
    if (id == null) return null;
    return ref.read(inventoryProductsRemoteDataSourceProvider).getById(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.isEditing ? 'Edit product' : 'Add product'),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: FutureBuilder<ProductDetailModel?>(
          future: _productFuture,
          builder: (context, snapshot) {
            if (widget.isEditing &&
                snapshot.connectionState != ConnectionState.done) {
              return const AppLoader();
            }
            if (widget.isEditing && snapshot.hasError) {
              return AppEmptyState.error(
                message: 'Could not load this product.',
                onAction: () =>
                    setState(() => _productFuture = _resolveProduct()),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) => Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(
                    AppBreakpoints.isPhone(constraints.maxWidth)
                        ? AppSpacing.sm
                        : AppSpacing.md,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: widget.isEditing
                        ? InventoryProductForm(product: snapshot.data)
                        : const QuickProductForm(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
