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
import '../../inventory_categories/widgets/inventory_category_thumbnail.dart';
import '../models/pos_cart_item.dart';
import '../../../shared/widgets/section_ui.dart';

/// Step 0 of the POS flow — product browsing and cart management.
///
/// Two panels, each a floating card on the page gradient:
///   Cart   – running sale, inline quantity steppers, dark totals footer
///   Browse – search, category grid, then products in the chosen category
///
/// Wide viewports put them side by side; narrower ones stack browse on top
/// of the cart so the totals and the pay button stay on screen.
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
  final _searchFocus = FocusNode(debugLabel: 'pos-search');
  bool _searchLoading = false;
  OverlayEntry? _searchOverlay;
  final _searchKey = GlobalKey();
  final _searchLayerLink = LayerLink();

  // ── Category browsing ─────────────────────────────────────────────────────
  List<InventoryCategoryModel> _categories = [];
  int? _selectedCategoryId;
  bool _categoriesLoading = true;

  // ── Product grid ──────────────────────────────────────────────────────────
  List<ProductModel> _gridProducts = [];
  bool _gridLoading = false;
  int _gridRequestId = 0;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChanged);
    _loadCategories();
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_onSearchFocusChanged);
    _searchFocus.dispose();
    _searchController.dispose();
    _closeSearchOverlay();
    super.dispose();
  }

  void _onSearchFocusChanged() => setState(() {});

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
    final requestId = ++_gridRequestId;
    setState(() => _gridLoading = true);
    try {
      final page = await ref
          .read(inventoryProductsRemoteDataSourceProvider)
          .list(active: true, categoryId: categoryId, size: 50);
      if (mounted && requestId == _gridRequestId) {
        setState(() {
          _gridProducts = page.content;
          _gridLoading = false;
        });
      }
    } catch (_) {
      if (mounted && requestId == _gridRequestId) {
        setState(() => _gridLoading = false);
      }
    }
  }

  void _onCategorySelected(int? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    if (categoryId == null) {
      ++_gridRequestId;
      setState(() {
        _selectedCategoryId = null;
        _gridProducts = [];
        _gridLoading = false;
      });
      return;
    }
    setState(() => _selectedCategoryId = categoryId);
    _loadGridProducts(categoryId: categoryId);
  }

  // ── Search overlay ────────────────────────────────────────────────────────

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      _closeSearchOverlay();
      setState(() {});
      return;
    }
    setState(() => _searchLoading = true);
    try {
      final page = await ref
          .read(inventoryProductsRemoteDataSourceProvider)
          .list(search: query.trim(), active: true, size: 20);
      if (!mounted) return;
      setState(() => _searchLoading = false);
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
        offset: Offset(0, size.height + AppSpacing.sm),
        child: Align(
          alignment: Alignment.topLeft,
          child: _SearchResults(
            width: size.width,
            products: products,
            onTap: _onSearchProductTapped,
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
        title: Text('Choose a unit', style: AppTypography.title),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(productName, style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.smMd),
              for (final u in units)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _UnitOption(
                    unit: u,
                    onTap: () => Navigator.of(ctx).pop(u),
                  ),
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
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: GestureDetector(
        onTap: _closeSearchOverlay,
        behavior: HitTestBehavior.translucent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = AppBreakpoints.isDesktop(width);
            final compact = AppBreakpoints.isPhone(width);
            final gutter = compact ? AppSpacing.sm : AppSpacing.md;

            final cartPanel = _CartPanel(
              cart: widget.cart,
              selectedIndex: widget.selectedCartIndex,
              subtotal: _subtotal,
              compact: compact,
              onRowSelected: widget.onCartRowSelected,
              onItemUpdated: widget.onCartItemUpdated,
              onItemRemoved: widget.onCartItemRemoved,
              onProceed: widget.onProceedToPayment,
            );

            final browsePanel = _BrowsePanel(
              searchKey: _searchKey,
              searchLink: _searchLayerLink,
              searchController: _searchController,
              searchFocus: _searchFocus,
              searchLoading: _searchLoading,
              onSearchChanged: _onSearchChanged,
              onSearchCleared: () {
                _searchController.clear();
                _closeSearchOverlay();
                setState(() {});
              },
              categories: _categories,
              categoriesLoading: _categoriesLoading,
              selectedCategoryId: _selectedCategoryId,
              onCategorySelected: _onCategorySelected,
              products: _gridProducts,
              gridLoading: _gridLoading,
              compact: compact,
              onProductTapped: _onProductTileTapped,
            );

            if (isWide) {
              return Padding(
                padding: EdgeInsets.all(gutter),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: cartPanel),
                    SizedBox(width: gutter),
                    Expanded(flex: 4, child: browsePanel),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.all(gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: browsePanel),
                  SizedBox(height: gutter),
                  Expanded(flex: 4, child: cartPanel),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart panel
// ─────────────────────────────────────────────────────────────────────────────

class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.cart,
    required this.selectedIndex,
    required this.subtotal,
    required this.compact,
    required this.onRowSelected,
    required this.onItemUpdated,
    required this.onItemRemoved,
    required this.onProceed,
  });

  final List<PosCartItem> cart;
  final int? selectedIndex;
  final double subtotal;
  final bool compact;
  final ValueChanged<int> onRowSelected;
  final void Function(int index, PosCartItem updated) onItemUpdated;
  final void Function(int index) onItemRemoved;
  final VoidCallback onProceed;

  double get _units => cart.fold(0.0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CartHeader(lines: cart.length, units: _units),
          Expanded(
            child: cart.isEmpty
                ? const _EmptyCart()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.smMd,
                      AppSpacing.sm,
                      AppSpacing.smMd,
                      AppSpacing.md,
                    ),
                    child: _CartTable(
                      cart: cart,
                      selectedIndex: selectedIndex,
                      compact: compact,
                      onRowSelected: onRowSelected,
                      onItemUpdated: onItemUpdated,
                      onItemRemoved: onItemRemoved,
                    ),
                  ),
          ),
          _TotalsFooter(
            lines: cart.length,
            subtotal: subtotal,
            compact: compact,
            onProceed: onProceed,
          ),
        ],
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader({required this.lines, required this.units});

  final int lines;
  final double units;

  /// Whole counts read as "3 units", fractional ones keep their decimals.
  String get _unitLabel {
    final value = units % 1 == 0
        ? units.toInt().toString()
        : units.toStringAsFixed(2);
    return '$value ${units == 1 ? 'unit' : 'units'}';
  }

  @override
  Widget build(BuildContext context) {
    return SectionPanelHeader(
      icon: Icons.receipt_long_rounded,
      eyebrow: 'CURRENT SALE',
      subtitle: lines == 0
          ? 'Nothing added yet'
          : '$lines ${lines == 1 ? 'line' : 'lines'} · $_unitLabel',
      trailing: SectionBadge(label: '$lines'),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return CenterOrScroll(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                gradient: AppGradients.softPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 30,
                color: AppColors.primaryDeep,
              ),
            ),
            const SizedBox(height: AppSpacing.smMd),
            Text('Ready to scan', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Scan a barcode, tap a product, or search\nto start this bill.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart table
// ─────────────────────────────────────────────────────────────────────────────

class _CartTable extends StatelessWidget {
  const _CartTable({
    required this.cart,
    required this.selectedIndex,
    required this.compact,
    required this.onRowSelected,
    required this.onItemUpdated,
    required this.onItemRemoved,
  });

  final List<PosCartItem> cart;
  final int? selectedIndex;
  final bool compact;
  final ValueChanged<int> onRowSelected;
  final void Function(int index, PosCartItem updated) onItemUpdated;
  final void Function(int index) onItemRemoved;

  Map<int, TableColumnWidth> _columnWidths() {
    final widths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(4), // selection bar
      1: const FlexColumnWidth(3), // product
      2: const FixedColumnWidth(106), // qty stepper
    };
    var column = 3;
    if (!compact) widths[column++] = const FixedColumnWidth(84); // rate
    widths[column++] = const FixedColumnWidth(92); // amount
    widths[column] = const FixedColumnWidth(34); // remove
    return widths;
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: _columnWidths(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const SizedBox.shrink(),
            _th('Product'),
            _th('Qty', align: TextAlign.center),
            if (!compact) _th('Rate', align: TextAlign.right),
            _th('Amount', align: TextAlign.right),
            const SizedBox.shrink(),
          ],
        ),
        for (var i = 0; i < cart.length; i++)
          TableRow(
            // No borderRadius here: a BoxDecoration with a one-sided (non
            // uniform) border asserts if it is also given a radius.
            decoration: BoxDecoration(
              color: i == selectedIndex ? AppColors.primarySoft : null,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
              ),
            ),
            children: [
              // Accent bar marking the highlighted row.
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.fill,
                child: i == selectedIndex
                    ? Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppBorderRadius.radiusFull,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onRowSelected(i),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.smMd,
                    AppSpacing.xs,
                    AppSpacing.smMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cart[i].productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _metaLine(cart[i]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ),
              _QtyStepper(
                item: cart[i],
                onChanged: (updated) => onItemUpdated(i, updated),
              ),
              if (!compact)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    formatMoneyAmount(cart[i].rate),
                    textAlign: TextAlign.right,
                    style: AppTypography.priceSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  formatMoneyAmount(cart[i].lineTotal),
                  textAlign: TextAlign.right,
                  style: AppTypography.priceSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 15),
                color: AppColors.textMuted,
                hoverColor: AppColors.errorSoft,
                tooltip: 'Remove',
                onPressed: () => onItemRemoved(i),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _metaLine(PosCartItem item) {
    final unit = item.sellingUnitLabel;
    if (compact) {
      final rate = 'Rs. ${formatMoneyAmount(item.rate)}';
      return unit.isEmpty ? rate : '$unit · $rate';
    }
    return unit.isEmpty ? 'Each' : unit;
  }

  Widget _th(String label, {TextAlign align = TextAlign.left}) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.sm,
      AppSpacing.xs,
      AppSpacing.xs,
      AppSpacing.sm,
    ),
    child: Text(
      label.toUpperCase(),
      textAlign: align,
      style: AppTypography.eyebrow.copyWith(
        fontSize: 10,
        letterSpacing: 0.8,
        color: AppColors.textMuted,
      ),
    ),
  );
}

/// Pill-shaped quantity control: minus, inline editable value, plus.
class _QtyStepper extends StatefulWidget {
  const _QtyStepper({required this.item, required this.onChanged});

  final PosCartItem item;
  final ValueChanged<PosCartItem> onChanged;

  @override
  State<_QtyStepper> createState() => _QtyStepperState();
}

class _QtyStepperState extends State<_QtyStepper> {
  late final TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _format(widget.item.quantity));
  }

  @override
  void didUpdateWidget(_QtyStepper old) {
    super.didUpdateWidget(old);
    if (!_editing && old.item.quantity != widget.item.quantity) {
      _ctrl.text = _format(widget.item.quantity);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _format(double qty) => qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2);

  void _commit() {
    final qty = double.tryParse(_ctrl.text.trim()) ?? widget.item.quantity;
    final clamped = qty < 0.01 ? 0.01 : qty;
    _ctrl.text = _format(clamped);
    widget.onChanged(widget.item.copyWith(quantity: clamped));
    setState(() => _editing = false);
  }

  void _step(double delta) {
    final next = widget.item.quantity + delta;
    if (next < 0.01) return;
    widget.onChanged(widget.item.copyWith(quantity: next));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceSunken,
          borderRadius: AppBorderRadius.radiusFull,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: Icons.remove_rounded,
              tooltip: 'Decrease',
              onTap: () => _step(-1),
            ),
            SizedBox(
              width: 38,
              child: TextField(
                controller: _ctrl,
                textAlign: TextAlign.center,
                style: AppTypography.priceSmall,
                cursorColor: AppColors.primaryDeep,
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onTap: () => setState(() => _editing = true),
                onEditingComplete: _commit,
                onTapOutside: (_) => _commit(),
              ),
            ),
            _StepButton(
              icon: Icons.add_rounded,
              tooltip: 'Increase',
              onTap: () => _step(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.card,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.primarySoft,
          splashColor: AppColors.primary.withValues(alpha: 0.25),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(icon, size: 15, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Totals footer
// ─────────────────────────────────────────────────────────────────────────────

class _TotalsFooter extends StatelessWidget {
  const _TotalsFooter({
    required this.lines,
    required this.subtotal,
    required this.compact,
    required this.onProceed,
  });

  final int lines;
  final double subtotal;
  final bool compact;
  final VoidCallback onProceed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: AppShadows.bottomBar,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AMOUNT DUE',
                      style: AppTypography.eyebrow.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Rs. ${formatMoneyAmount(subtotal)}',
                        style: AppTypography.metric,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    '$lines ${lines == 1 ? 'item' : 'items'}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          BrandActionButton(label: 'Proceed to Payment', onPressed: onProceed),
          if (!compact) ...[
            const SizedBox(height: AppSpacing.smMd),
            const Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                KeyHint(keyLabel: 'Enter', action: 'Pay'),
                KeyHint(keyLabel: 'Up / Down', action: 'Pick row'),
                KeyHint(keyLabel: '+ / -', action: 'Quantity'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Browse panel
// ─────────────────────────────────────────────────────────────────────────────

class _BrowsePanel extends StatelessWidget {
  const _BrowsePanel({
    required this.searchKey,
    required this.searchLink,
    required this.searchController,
    required this.searchFocus,
    required this.searchLoading,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.categories,
    required this.categoriesLoading,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.products,
    required this.gridLoading,
    required this.compact,
    required this.onProductTapped,
  });

  final GlobalKey searchKey;
  final LayerLink searchLink;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final bool searchLoading;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final List<InventoryCategoryModel> categories;
  final bool categoriesLoading;
  final int? selectedCategoryId;
  final void Function(int? categoryId) onCategorySelected;
  final List<ProductModel> products;
  final bool gridLoading;
  final bool compact;
  final Future<void> Function(ProductModel) onProductTapped;

  @override
  Widget build(BuildContext context) {
    final selectedCategory = categories
        .where((category) => category.id == selectedCategoryId)
        .firstOrNull;
    final Widget content;
    if (selectedCategoryId == null) {
      if (categoriesLoading) {
        content = const Center(child: CircularProgressIndicator());
      } else if (categories.isEmpty) {
        content = const CenterOrScroll(
          child: AppEmptyState(
            icon: Icons.category_outlined,
            title: 'No categories yet',
            message: 'Add a category to browse its products.',
            compact: true,
          ),
        );
      } else {
        content = _CategoryGrid(
          categories: categories,
          compact: compact,
          onSelected: (categoryId) => onCategorySelected(categoryId),
        );
      }
    } else if (gridLoading) {
      content = const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        ),
      );
    } else if (products.isEmpty) {
      content = const CenterOrScroll(
        child: AppEmptyState.noResults(
          title: 'No products here',
          message: 'Go back to categories or search by name.',
          compact: true,
        ),
      );
    } else {
      content = _ProductGrid(
        products: products,
        compact: compact,
        onTap: onProductTapped,
      );
    }
    return SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.smMd,
            ),
            child: _SearchField(
              fieldKey: searchKey,
              link: searchLink,
              controller: searchController,
              focusNode: searchFocus,
              loading: searchLoading,
              onChanged: onSearchChanged,
              onCleared: onSearchCleared,
            ),
          ),
          if (selectedCategoryId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => onCategorySelected(null),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Categories'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      selectedCategory?.name ?? 'Products',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTypography.subtitle,
                    ),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.smMd,
              ),
              child: Text('Categories', style: AppTypography.subtitle),
            ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.fieldKey,
    required this.link,
    required this.controller,
    required this.focusNode,
    required this.loading,
    required this.onChanged,
    required this.onCleared,
  });

  final GlobalKey fieldKey;
  final LayerLink link;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final ValueChanged<String> onChanged;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    return CompositedTransformTarget(
      link: link,
      child: AnimatedContainer(
        key: fieldKey,
        duration: AppAnimations.fast,
        curve: AppAnimations.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppBorderRadius.radiusL,
          border: Border.all(
            color: focused ? AppColors.primary : AppColors.border,
            width: focused ? 1.5 : 1,
          ),
          boxShadow: focused ? AppShadows.focus : AppShadows.none,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppBorderRadius.radiusMD,
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryDeep,
                      ),
                    )
                  : const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.primaryDeep,
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                style: AppTypography.body,
                cursorColor: AppColors.primaryDeep,
                decoration: InputDecoration(
                  hintText: 'Search products by name...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                onChanged: onChanged,
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.textMuted,
                tooltip: 'Clear',
                visualDensity: VisualDensity.compact,
                onPressed: onCleared,
              ),
          ],
        ),
      ),
    );
  }
}

/// Search results dropdown anchored under the search field.
class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.width,
    required this.products,
    required this.onTap,
  });

  final double width;
  final List<ProductModel> products;
  final Future<void> Function(ProductModel) onTap;

  @override
  Widget build(BuildContext context) {
    return AppScaleIn(
      from: 0.98,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppBorderRadius.radiusL,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.floating,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              itemCount: products.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (ctx, i) {
                final p = products[i];
                return InkWell(
                  onTap: () => onTap(p),
                  hoverColor: AppColors.primarySoft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.smMd,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        _Initial(name: p.name, size: 34),
                        const SizedBox(width: AppSpacing.smMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (p.categoryName != null)
                                Text(
                                  p.categoryName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption,
                                ),
                            ],
                          ),
                        ),
                        if (p.sellingPrice != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Rs. ${formatMoneyAmount(p.sellingPrice)}',
                            style: AppTypography.priceSmall,
                          ),
                        ],
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(
                          Icons.add_circle_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category tiles
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.compact,
    required this.onSelected,
  });

  final List<InventoryCategoryModel> categories;
  final bool compact;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.smMd),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: compact ? 124 : 152,
        mainAxisSpacing: AppSpacing.smMd,
        crossAxisSpacing: AppSpacing.smMd,
        childAspectRatio: 0.75,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return AppStaggered(
          index: index,
          child: _CategoryTile(
            category: category,
            compact: compact,
            onTap: () => onSelected(category.id),
          ),
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.compact,
    required this.onTap,
  });

  final InventoryCategoryModel category;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: category.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.radiusL,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppBorderRadius.radiusL,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InventoryCategoryThumbnail(
                  imageUrl: category.image,
                  size: compact ? 64 : 88,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product grid
// ─────────────────────────────────────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.compact,
    required this.onTap,
  });

  final List<ProductModel> products;
  final bool compact;
  final Future<void> Function(ProductModel) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.smMd),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: compact ? 124 : 152,
        mainAxisSpacing: AppSpacing.smMd,
        crossAxisSpacing: AppSpacing.smMd,
        childAspectRatio: 0.84,
      ),
      itemCount: products.length,
      itemBuilder: (ctx, i) => AppStaggered(
        index: i,
        child: _ProductTile(
          product: products[i],
          onTap: () => onTap(products[i]),
        ),
      ),
    );
  }
}

class _ProductTile extends StatefulWidget {
  const _ProductTile({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AppPressable(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.standard,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppBorderRadius.radiusL,
            border: Border.all(
              color: _hovered ? AppColors.primary : AppColors.border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered ? AppShadows.card : AppShadows.soft,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.image != null
                        ? Image.network(
                            product.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _Initial(name: product.name),
                          )
                        : _Initial(name: product.name),
                    Positioned(
                      right: AppSpacing.xs,
                      bottom: AppSpacing.xs,
                      child: AnimatedOpacity(
                        duration: AppAnimations.fast,
                        opacity: _hovered ? 1 : 0.85,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.button,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 17,
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.smMd,
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.sellingPrice == null
                                ? 'No price'
                                : 'Rs. ${formatMoneyAmount(product.sellingPrice)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.priceSmall.copyWith(
                              fontSize: 13,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ),
                        if (product.sellingUnitSymbol != null)
                          Text(
                            '/${product.sellingUnitSymbol}',
                            style: AppTypography.caption,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Initial-letter placeholder used wherever a product has no image.
class _Initial extends StatelessWidget {
  const _Initial({required this.name, this.size});

  final String name;

  /// When null the placeholder fills its parent (grid tile); otherwise it is
  /// a fixed square (search result row).
  final double? size;

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.softPrimary,
        borderRadius: size == null ? null : AppBorderRadius.radiusMD,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTypography.title.copyWith(
          fontSize: size == null ? 30 : 16,
          color: AppColors.primaryDeep,
        ),
      ),
    );
  }
}

/// One row in the "which unit?" dialog.
class _UnitOption extends StatelessWidget {
  const _UnitOption({required this.unit, required this.onTap});

  final ProductSellingUnitModel unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppBorderRadius.radiusMD,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.primarySoft,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.smMd,
            vertical: AppSpacing.smMd,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  unit.unit.name,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Rs. ${formatMoneyAmount(unit.sellingPrice)}',
                style: AppTypography.priceSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
