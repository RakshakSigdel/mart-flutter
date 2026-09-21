import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/core.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/inventory_products_model.dart';
import '../../../../data/models/models_user/sale_model.dart';
import '../../../../providers/providers_user/inventory_products_provider.dart';
import '../controllers/sales_controller.dart';
import '../models/pos_cart_item.dart';
import '../widgets/pos_payment_step.dart';
import '../widgets/pos_print_step.dart';
import '../widgets/pos_product_selection.dart';

/// Top-level POS screen managing the 3-step flow:
///   0 - Product Selection
///   1 - Payment
///   2 - Print Receipt
///
/// Registers a global hardware-keyboard listener that detects USB/Bluetooth
/// barcode scanners (which type characters fast and finish with Enter). When
/// barcode input is detected, the product is fetched and added to the cart
/// regardless of which step is currently active.
///
/// The same listener also drives keyboard-only cart editing while on the
/// product-selection step (and no text field has focus): Up/Down move the
/// highlighted cart row, +/- adjust its quantity, and Enter (with nothing
/// scanned) jumps to Payment.
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => PosScreenState();
}

class PosScreenState extends ConsumerState<PosScreen> {
  int _step = 0;

  // -- Cart state ------------------------------------------------------------
  final List<PosCartItem> _cart = [];

  /// The highlighted cart row — the most recently added/changed item by
  /// default, or one picked with the up/down arrow keys.
  int? _selectedCartIndex;

  // -- Barcode scanner detection ---------------------------------------------
  // USB/BT scanners act as keyboards: they type characters fast (< 80 ms
  // between keystrokes) then press Enter. We accumulate chars while they
  // arrive quickly, then on Enter we treat the buffer as a barcode.
  final StringBuffer _barcodeBuffer = StringBuffer();
  Timer? _barcodeTimer;
  bool _scanningBarcode = false;
  static const _barcodeGapMs = 80;

  // -- Created sale (set after step 1 completes) -----------------------------
  SaleDetailModel? _createdSale;

  // -- Handler reference for removal -----------------------------------------
  late final KeyEventCallback _keyHandler;

  @override
  void initState() {
    super.initState();
    _keyHandler = _handleKeyEvent;
    HardwareKeyboard.instance.addHandler(_keyHandler);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keyHandler);
    _barcodeTimer?.cancel();
    super.dispose();
  }

  // -- Barcode detection logic -----------------------------------------------

  bool _handleKeyEvent(KeyEvent event) {
    // Only act on key-down events; ignore ups and repeats for barcode.
    if (event is! KeyDownEvent) return false;

    final logical = event.logicalKey;

    // Enter / newline = end of barcode sequence, or — with nothing scanned —
    // "proceed to payment" while browsing products.
    if (logical == LogicalKeyboardKey.enter ||
        logical == LogicalKeyboardKey.numpadEnter) {
      final code = _barcodeBuffer.toString().trim();
      _barcodeBuffer.clear();
      _barcodeTimer?.cancel();
      _barcodeTimer = null;
      if (code.isNotEmpty) {
        _onBarcodeScanned(code);
        return true; // consumed
      }
      if (_step == 0 && !_isEditingText()) {
        _goToPayment();
        return true;
      }
      return false;
    }

    // Up/Down walk the highlighted cart row while browsing products; +/-
    // adjust that row's quantity, mirroring the on-row buttons.
    if (_step == 0 && !_isEditingText()) {
      if (logical == LogicalKeyboardKey.arrowUp) {
        _moveCartSelection(-1);
        return true;
      }
      if (logical == LogicalKeyboardKey.arrowDown) {
        _moveCartSelection(1);
        return true;
      }
      if (logical == LogicalKeyboardKey.numpadAdd || event.character == '+') {
        _adjustSelectedCartQuantity(1);
        return true;
      }
      if (logical == LogicalKeyboardKey.numpadSubtract ||
          event.character == '-') {
        _adjustSelectedCartQuantity(-1);
        return true;
      }
    }

    // Accumulate printable characters
    final char = event.character;
    if (char != null && char.isNotEmpty) {
      _barcodeBuffer.write(char);
      // Reset the gap timer - if no more chars arrive in 80 ms, clear buffer
      _barcodeTimer?.cancel();
      _barcodeTimer = Timer(const Duration(milliseconds: _barcodeGapMs), () {
        // Slow typing - not a scanner, discard
        _barcodeBuffer.clear();
      });
      // Don't consume - let the char reach any focused TextField too
      return false;
    }

    return false;
  }

  /// Whether a text field currently has focus — arrow/enter/+/- shortcuts
  /// stand down so normal typing (e.g. the search box) isn't hijacked.
  bool _isEditingText() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return false;
    return focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void _moveCartSelection(int delta) {
    if (_cart.isEmpty) return;
    setState(() {
      final current = _selectedCartIndex;
      _selectedCartIndex = current == null
          ? (delta > 0 ? 0 : _cart.length - 1)
          : (current + delta).clamp(0, _cart.length - 1);
    });
  }

  void _adjustSelectedCartQuantity(double delta) {
    final index = _selectedCartIndex;
    if (index == null || index < 0 || index >= _cart.length) return;
    final item = _cart[index];
    final newQty = item.quantity + delta;
    if (newQty < 0.01) return;
    setState(() => _cart[index] = item.copyWith(quantity: newQty));
  }

  Future<void> _onBarcodeScanned(String barcode) async {
    if (_scanningBarcode) return;
    setState(() => _scanningBarcode = true);
    try {
      final unit = await ref
          .read(inventoryProductsRemoteDataSourceProvider)
          .getByBarcode(barcode);
      if (!mounted) return;
      _addUnitToCart(unit);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        e.statusCode == 404
            ? 'No product found for barcode "$barcode"'
            : e.message,
      );
    } finally {
      if (mounted) setState(() => _scanningBarcode = false);
    }
  }

  // -- Cart helpers ----------------------------------------------------------

  void _addUnitToCart(ProductSellingUnitModel unit) {
    final productId = unit.productId;
    if (productId == null) return;
    setState(() {
      final idx = _cart.indexWhere(
        (i) => i.productId == productId && i.sellingUnitId == unit.id,
      );
      if (idx >= 0) {
        _cart[idx] = _cart[idx].copyWith(quantity: _cart[idx].quantity + 1);
        _selectedCartIndex = idx;
      } else {
        _cart.add(
          PosCartItem(
            productId: productId,
            productName: unit.productName ?? 'Product #$productId',
            sellingUnitId: unit.id,
            sellingUnitLabel: unit.unit.symbol.isNotEmpty
                ? unit.unit.symbol
                : unit.unit.name,
            rate: unit.sellingPrice ?? 0,
          ),
        );
        _selectedCartIndex = _cart.length - 1;
      }
    });
  }

  void _updateCartItem(int index, PosCartItem updated) {
    setState(() {
      _cart[index] = updated;
      _selectedCartIndex = index;
    });
  }

  void _selectCartRow(int index) {
    setState(() => _selectedCartIndex = index);
  }

  void _removeCartItem(int index) {
    setState(() {
      _cart.removeAt(index);
      final selected = _selectedCartIndex;
      if (_cart.isEmpty) {
        _selectedCartIndex = null;
      } else if (selected != null && selected >= _cart.length) {
        _selectedCartIndex = _cart.length - 1;
      } else if (selected != null && selected > index) {
        _selectedCartIndex = selected - 1;
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _createdSale = null;
      _selectedCartIndex = null;
      _step = 0;
    });
  }

  // -- Step navigation -------------------------------------------------------

  void _goToPayment() {
    if (_cart.isEmpty) {
      AppSnackBar.error(context, 'Add at least one product before paying.');
      return;
    }
    setState(() => _step = 1);
  }

  Future<void> _onBillSaved(SaleDetailModel sale) async {
    setState(() {
      _createdSale = sale;
      _step = 2;
    });
  }

  // -- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IndexedStack(
          index: _step,
          children: [
            PosProductSelection(
              cart: _cart,
              selectedCartIndex: _selectedCartIndex,
              onCartRowSelected: _selectCartRow,
              onCartItemUpdated: _updateCartItem,
              onCartItemRemoved: _removeCartItem,
              onAddUnitToCart: _addUnitToCart,
              onProceedToPayment: _goToPayment,
            ),
            PosPaymentStep(
              cart: _cart,
              onBack: () => setState(() => _step = 0),
              onBillSaved: _onBillSaved,
              active: _step == 1,
            ),
            PosPrintStep(sale: _createdSale, onNewBill: _clearCart),
          ],
        ),
        if (_scanningBarcode)
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Looking up barcode...',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
