import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/inventory_categories_model.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../providers/providers_user/inventory_categories_provider.dart';
import '../../../../providers/providers_user/inventory_products_provider.dart';
import '../models/pos_cart_item.dart';

/// Step 0 of the POS flow — product browsing and cart management.
///
/// Layout (two horizontal panels):
///   Left  – cart table + totals bar + "Proceed to Payment" button
///   Right – search bar + wrapping category filter chips + product tile grid
class PosProductSelection extends ConsumerStatefulWidget {
  const PosProductSelection({
    super.key,
    required this.cart,
    required this.selectedCartIndex,
    required this.onCartRowSelected,
    required this.onCartItemUpdated,
    required this.onCartItemRemoved,
    required this.onAddUnitToCart,
    required this.onProceedToPayment,
  });

  final List<PosCartItem> cart;

  /// Index of the highlighted cart row — the most recently added/changed
  /// item, or one the user picked with the up/down arrow keys.
  final int? selectedCartIndex;
  final ValueChanged<int> onCartRowSelected;
  final void Function(int index, PosCartItem updated) onCartItemUpdated;
  final void Function(int index) onCartItemRemoved;
  final void Function(ProductSellingUnitModel unit) onAddUnitToCart;
  final VoidCallback onProceedToPayment;

  @override
  ConsumerState<PosProductSelection> createState() =>
      _PosProductSelectionState();
}

class _PosProductSelectionState extends ConsumerState<PosProductSelection> {
  // ── Search ────────────────────────────────────────────────────────────────
  final _searchController = TextEditingController();
  bool _searchLoading = false;
  List<ProductSellingUnitModel> _searchResults = [];
  OverlayEntry? _searchOverlay;
  final _searchKey = GlobalKey();
  final _searchLayerLink = LayerLink();

  // ── Category filter ───────────────────────────────────────────────────────
  List<InventoryCategoryModel> _categories = [];
  int? _selectedCategoryId;
  bool _categoriesLoading = true;

  // ── Product grid ──────────────────────────────────────────────────────────
  List<ProductModel> _gridProducts = [];
  bool _gridLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadGridProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _closeSearchOverlay();
    super.dispose();
  }

  // ── Category loading ──────────────────────────────────────────────────────

  Future<void> _loadCategories() async {
    try {
      final page = await ref
          .read(inventoryCategoriesRemoteDataSourceProvider)
          .list(size: 100);
      if (mounted) {
        setState(() {
          _categories = page.content;
          _categoriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  // ── Product grid loading ──────────────────────────────────────────────────

  Future<void> _loadGridProducts({int? categoryId}) async {
    setState(() => _gridLoading = true);
    try {
      final page = await ref
          .read(inventoryProductsRemoteDataSourceProvider)
          .list(active: true, categoryId: categoryId, size: 50);
      if (mounted) {
        setState(() {
          _gridProducts = page.content;
          _gridLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _gridLoading = false);
    }
  }

  void _onCategorySelected(int? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _loadGridProducts(categoryId: categoryId);
  }

  // ── Search overlay ────────────────────────────────────────────────────────

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      _closeSearchOverlay();
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searchLoading = true);
    try {
      final page = await ref
          .read(inventoryProductsRemoteDataSourceProvider)
          .list(search: query.trim(), active: true, size: 20);
      if (!mounted) return;
      // Convert ProductModel list to units — we need the unit to add to cart.
      // The product model does not carry units; fetch the first selling unit
      // via getByBarcode is not useful here. Instead show products in the
      // overlay and when tapped, fetch the product's units.
      setState(() {
        _searchLoading = false;
      });
      _showSearchOverlay(page.content);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _searchLoading = false);
        AppSnackBar.error(context, e.message);
      }
    }
  }

  void _showSearchOverlay(List<ProductModel> products) {
    _closeSearchOverlay();
    if (products.isEmpty) return;

    final renderBox =
        _searchKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    // Anchor via a LayerLink rather than raw global coordinates: this screen
    // sits inside the admin shell's own nested Navigator (offset from the
    // window origin by the sidebar/top bar), so `localToGlobal` + `Positioned`
    // inside that Navigator's Overlay would place the dropdown in the wrong
    // spot. The transform follower tracks the field correctly regardless.
    _searchOverlay = OverlayEntry(
      builder: (ctx) => CompositedTransformFollower(
        link: _searchLayerLink,
        showWhenUnlinked: false,
        offset: Offset(0, size.height + 4),
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: size.width,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: products.length,
                  itemBuilder: (ctx, i) {
                    final p = products[i];
                    return ListTile(
                      dense: true,
                      title: Text(p.name),
                      subtitle: p.categoryName != null
                          ? Text(p.categoryName!, style: AppTypography.caption)
                          : null,
                      onTap: () => _onSearchProductTapped(p),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_searchOverlay!);
  }

  void _closeSearchOverlay() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  Future<void> _onSearchProductTapped(ProductModel product) async {
    _closeSearchOverlay();
    _searchController.clear();
    // Fetch the product's selling units so we can add the right unit to cart
    try {
      final units = await ref
          .read(inventoryProductsRemoteDataSourceProvider)
          .sellingUnits(product.id);
      if (!mounted) return;
      if (units.isNotEmpty) {
        widget.onAddUnitToCart(units.first);
      }
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    }
  }

  // ── Product tile tap ──────────────────────────────────────────────────────

  Future<void> _onProductTileTapped(ProductModel product) async {
    try {
      final units = await ref
          .read(inventoryProductsRemoteDataSourceProvider)
          .sellingUnits(product.id);
      if (!mounted) return;
      if (units.isEmpty) {
        AppSnackBar.error(
          context,
          'No selling units configured for "${product.name}".',
        );
        return;
      }
      if (units.length == 1) {
        widget.onAddUnitToCart(units.first);
      } else {
        // Multiple units — show picker dialog
        final chosen = await _showUnitPicker(product.name, units);
        if (chosen != null && mounted) widget.onAddUnitToCart(chosen);
      }
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    }
  }

  Future<ProductSellingUnitModel?> _showUnitPicker(
    String productName,
    List<ProductSellingUnitModel> units,
  ) {
    return showDialog<ProductSellingUnitModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Select unit — $productName'),
        content: SizedBox(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final u in units)
                ListTile(
                  title: Text(u.unit.name),
                  subtitle: Text(formatMoneyAmount(u.sellingPrice)),
                  onTap: () => Navigator.of(ctx).pop(u),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ── Totals ────────────────────────────────────────────────────────────────

  double get _subtotal =>
      widget.cart.fold(0.0, (sum, item) => sum + item.lineTotal);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeSearchOverlay,
      behavior: HitTestBehavior.translucent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left panel: cart ──────────────────────────────────────────────
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cart table
                Expanded(
                  child: widget.cart.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 48,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'No items yet.\nSearch or tap a product to add it.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            0,
                          ),
                          child: _CartTable(
                            cart: widget.cart,
                            selectedIndex: widget.selectedCartIndex,
                            onRowSelected: widget.onCartRowSelected,
                            onItemUpdated: widget.onCartItemUpdated,
                            onItemRemoved: widget.onCartItemRemoved,
                          ),
                        ),
                ),

                // Totals bar + Proceed button
                _TotalsBar(
                  subtotal: _subtotal,
                  onProceed: widget.onProceedToPayment,
                ),
              ],
            ),
          ),

          // Vertical divider
          const VerticalDivider(width: 1),

          // ── Right panel: category browsing ────────────────────────────────
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: CompositedTransformTarget(
                    link: _searchLayerLink,
                    child: TextField(
                      key: _searchKey,
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      style: AppTypography.body,
                      decoration: InputDecoration(
                        hintText: 'Search products by name...',
                        prefixIcon: _searchLoading
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const Icon(Icons.search_rounded, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                tooltip: 'Clear',
                                onPressed: () {
                                  _searchController.clear();
                                  _closeSearchOverlay();
                                  setState(() => _searchResults = []);
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.smMd,
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),

                // Category filter
                if (_categoriesLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: LinearProgressIndicator(),
                  )
                else
                  _CategoryChips(
                    categories: _categories,
                    selectedId: _selectedCategoryId,
                    onSelected: _onCategorySelected,
                  ),

                const Divider(height: 1),

                // Product grid
                Expanded(
                  child: _gridLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _gridProducts.isEmpty
                      ? Center(
                          child: Text(
                            'No products found.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : _ProductGrid(
                          products: _gridProducts,
                          onTap: _onProductTileTapped,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart Table
// ─────────────────────────────────────────────────────────────────────────────

class _CartTable extends StatelessWidget {
  const _CartTable({
    required this.cart,
    required this.selectedIndex,
    required this.onRowSelected,
    required this.onItemUpdated,
    required this.onItemRemoved,
  });

  final List<PosCartItem> cart;
  final int? selectedIndex;
  final ValueChanged<int> onRowSelected;
  final void Function(int index, PosCartItem updated) onItemUpdated;
  final void Function(int index) onItemRemoved;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3), // Product
        1: FixedColumnWidth(92), // Qty
        2: FixedColumnWidth(90), // Unit Price
        3: FixedColumnWidth(90), // Line Total
        4: FixedColumnWidth(40), // Remove
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          children: [
            _th('Product'),
            _th('Qty', center: true),
            _th('Unit Price', center: true),
            _th('Total', center: true),
            const SizedBox.shrink(),
          ],
        ),
        for (var i = 0; i < cart.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i == selectedIndex
                  ? AppColors.primarySoft
                  : (i.isEven ? AppColors.surface : AppColors.background),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onRowSelected(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                    horizontal: AppSpacing.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cart[i].productName, style: AppTypography.body),
                      if (cart[i].sellingUnitLabel.isNotEmpty)
                        Text(
                          cart[i].sellingUnitLabel,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Qty (editable inline)
              _QtyCell(
                item: cart[i],
                onChanged: (updated) => onItemUpdated(i, updated),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  formatMoneyAmount(cart[i].rate),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  formatMoneyAmount(cart[i].lineTotal),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                color: AppColors.error,
                tooltip: 'Remove',
                onPressed: () => onItemRemoved(i),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
      ],
    );
  }

  Widget _th(String label, {bool center = false}) => Padding(
    padding: const EdgeInsets.symmetric(
      vertical: AppSpacing.sm,
      horizontal: AppSpacing.xs,
    ),
    child: Text(
      label,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: AppTypography.caption.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _QtyCell extends StatefulWidget {
  const _QtyCell({required this.item, required this.onChanged});

  final PosCartItem item;
  final ValueChanged<PosCartItem> onChanged;

  @override
  State<_QtyCell> createState() => _QtyCellState();
}

class _QtyCellState extends State<_QtyCell> {
  late final TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.item.quantity.toStringAsFixed(
        widget.item.quantity % 1 == 0 ? 0 : 2,
      ),
    );
  }

  @override
  void didUpdateWidget(_QtyCell old) {
    super.didUpdateWidget(old);
    if (!_editing && old.item.quantity != widget.item.quantity) {
      _ctrl.text = widget.item.quantity.toStringAsFixed(
        widget.item.quantity % 1 == 0 ? 0 : 2,
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit() {
    final qty = double.tryParse(_ctrl.text.trim()) ?? widget.item.quantity;
    final clamped = qty < 0.01 ? 0.01 : qty;
    _ctrl.text = clamped.toStringAsFixed(clamped % 1 == 0 ? 0 : 2);
    widget.onChanged(widget.item.copyWith(quantity: clamped));
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            final newQty = widget.item.quantity - 1;
            if (newQty < 0.01) return;
            widget.onChanged(widget.item.copyWith(quantity: newQty));
          },
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(Icons.remove, size: 14),
          ),
        ),
        SizedBox(
          width: 36,
          child: TextField(
            controller: _ctrl,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              border: InputBorder.none,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onTap: () => setState(() => _editing = true),
            onEditingComplete: _commit,
            onTapOutside: (_) => _commit(),
          ),
        ),
        InkWell(
          onTap: () {
            widget.onChanged(
              widget.item.copyWith(quantity: widget.item.quantity + 1),
            );
          },
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(Icons.add, size: 14),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Totals Bar
// ─────────────────────────────────────────────────────────────────────────────

class _TotalsBar extends StatelessWidget {
  const _TotalsBar({required this.subtotal, required this.onProceed});

  final double subtotal;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.smMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total',
                style: AppTypography.bodySmall.copyWith(color: Colors.white70),
              ),
              Text(
                'Rs. ${formatMoneyAmount(subtotal)}',
                style: AppTypography.title.copyWith(color: Colors.white),
              ),
            ],
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: onProceed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.smMd,
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category chips
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<InventoryCategoryModel> categories;
  final int? selectedId;
  final void Function(int? categoryId) onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          ChoiceChip(
            avatar: const Icon(Icons.apps_rounded, size: 16),
            label: const Text('All'),
            selected: selectedId == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final cat in categories)
            ChoiceChip(
              label: Text(cat.name),
              selected: selectedId == cat.id,
              onSelected: (_) => onSelected(cat.id),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product tile grid
// ─────────────────────────────────────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products, required this.onTap});

  final List<ProductModel> products;
  final Future<void> Function(ProductModel) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 128,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.95,
      ),
      itemCount: products.length,
      itemBuilder: (ctx, i) =>
          _ProductTile(product: products[i], onTap: () => onTap(products[i])),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image or placeholder
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
                child: product.image != null
                    ? Image.network(
                        product.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _ProductInitial(product.name),
                      )
                    : _ProductInitial(product.name),
              ),
            ),
            // Name + price
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (product.sellingPrice != null)
                    Text(
                      'Rs. ${formatMoneyAmount(product.sellingPrice!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductInitial extends StatelessWidget {
  const _ProductInitial(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: AppTypography.title.copyWith(
          color: AppColors.primary,
          fontSize: 28,
        ),
      ),
    );
  }
}
