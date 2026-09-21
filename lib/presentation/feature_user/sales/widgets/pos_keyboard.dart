import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/core.dart';

/// POS arrows run before EditableText/Scrollable shortcuts. Only the focused
/// POS route participates; dialogs and other shell branches own their keys.
class PosKeyboardNavigation extends StatefulWidget {
  const PosKeyboardNavigation({
    super.key,
    required this.scope,
    required this.child,
    this.enabled = true,
  });
  final FocusScopeNode scope;
  final Widget child;
  final bool enabled;
  @override
  State<PosKeyboardNavigation> createState() => _PosKeyboardNavigationState();
}

class _PosKeyboardNavigationState extends State<PosKeyboardNavigation> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addEarlyKeyEventHandler(_handleKey);
    FocusManager.instance.addListener(_revealFocus);
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(_handleKey);
    FocusManager.instance.removeListener(_revealFocus);
    super.dispose();
  }

  void _revealFocus() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || !focus.ancestors.contains(widget.scope)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || focus != FocusManager.instance.primaryFocus) return;
      final context = focus.context;
      if (context != null && context.mounted) {
        Scrollable.ensureVisible(context, alignment: 0.45);
      }
    });
  }

  KeyEventResult _handleKey(KeyEvent event) {
    final focus = FocusManager.instance.primaryFocus;
    if (!widget.enabled ||
        !TickerMode.valuesOf(context).enabled ||
        focus == null ||
        !focus.ancestors.contains(widget.scope) ||
        ModalRoute.of(context)?.isCurrent == false ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent))
      return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isShiftPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed)
      return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowLeft) {
      focus.previousFocus();
    } else if (key == LogicalKeyboardKey.arrowDown) {
      focus.nextFocus();
    } else if (key == LogicalKeyboardKey.arrowRight) {
      // Key repeat may move between fields, but must never repeatedly add,
      // delete, expand or submit records.
      final target = focus.context;
      final action = target == null
          ? null
          : Actions.maybeFind<ActivateIntent>(target);
      if (action != null && action.isEnabled(const ActivateIntent())) {
        if (event is KeyDownEvent)
          Actions.invoke(target!, const ActivateIntent());
      } else {
        focus.nextFocus();
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => FocusScope(
    node: widget.scope,
    child: FocusTraversalGroup(
      policy: OrderedTraversalPolicy(secondary: ReadingOrderTraversalPolicy()),
      child: widget.child,
    ),
  );
}

/// Searchable POS picker with an explicit result cursor, independent of list
/// scrolling. The same control handles products, customers, units and payment.
class PosPicker<T> extends StatefulWidget {
  const PosPicker({
    super.key,
    required this.label,
    required this.selectedItem,
    required this.itemLabel,
    required this.onChanged,
    this.items,
    this.search,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.onBarcode,
    this.onScan,
  });
  final String label;
  final T? selectedItem;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final List<T>? items;
  final Future<List<T>> Function(String)? search;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String>? onBarcode;
  final VoidCallback? onScan;
  @override
  State<PosPicker<T>> createState() => _PosPickerState<T>();
}

class _PosPickerState<T> extends State<PosPicker<T>> {
  final _ownFocus = FocusNode();
  FocusNode get _focus => widget.focusNode ?? _ownFocus;
  bool _open = false;
  @override
  void dispose() {
    _ownFocus.dispose();
    super.dispose();
  }

  Future<void> _show() async {
    if (_open || !widget.enabled) return;
    _open = true;
    final result = await showDialog<_PosChoice<T>>(
      context: context,
      builder: (_) => _PosPickerDialog<T>(
        label: widget.label,
        items: widget.items,
        search: widget.search,
        itemLabel: widget.itemLabel,
        barcode: widget.onBarcode != null,
      ),
    );
    if (!mounted) return;
    _open = false;
    // Restore the closed picker before callbacks focus a dependent field.
    _focus.requestFocus();
    if (result?.item != null) widget.onChanged(result!.item as T);
    if (result?.barcode != null) widget.onBarcode?.call(result!.barcode!);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(widget.label, style: AppTypography.fieldLabel),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              focusNode: _focus,
              autofocus: widget.autofocus,
              onPressed: widget.enabled ? _show : null,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.focused)
                      ? AppColors.primarySoft
                      : AppColors.card,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.selectedItem == null
                            ? 'Choose / search...'
                            : widget.itemLabel(widget.selectedItem as T),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
          if (widget.onScan != null)
            IconButton(
              tooltip: 'Scan barcode',
              onPressed: widget.enabled ? widget.onScan : null,
              icon: const Icon(Icons.qr_code_scanner),
            ),
        ],
      ),
    ],
  );
}

class _PosChoice<T> {
  const _PosChoice({this.item, this.barcode});
  final T? item;
  final String? barcode;
}

class _PosPickerDialog<T> extends StatefulWidget {
  const _PosPickerDialog({
    required this.label,
    required this.items,
    required this.search,
    required this.itemLabel,
    required this.barcode,
  });
  final String label;
  final List<T>? items;
  final Future<List<T>> Function(String)? search;
  final String Function(T) itemLabel;
  final bool barcode;
  @override
  State<_PosPickerDialog<T>> createState() => _PosPickerDialogState<T>();
}

class _PosPickerDialogState<T> extends State<_PosPickerDialog<T>> {
  final _query = TextEditingController();
  final _scroll = ScrollController();
  late final _searchFocus = FocusNode(onKeyEvent: _key);
  List<T> _items = [];
  int _highlight = -1, _generation = 0;
  Timer? _debounce;
  bool _loading = true;
  String? _error;
  bool get _hasBarcode => widget.barcode && _query.text.trim().isNotEmpty;
  int get _count => _items.length + (_hasBarcode ? 1 : 0);
  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _searchFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    ++_generation; // Invalidate previous requests immediately, even during debounce.
    setState(() {
      _highlight = -1;
      _loading = true;
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 200), () => _load(value));
  }

  Future<void> _load(String value) async {
    final generation = ++_generation;
    try {
      final items = widget.search != null
          ? await widget.search!(value)
          : (widget.items ?? [])
                .where(
                  (item) => widget
                      .itemLabel(item)
                      .toLowerCase()
                      .contains(value.toLowerCase()),
                )
                .toList();
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
        _highlight = -1;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = [];
        _loading = false;
        _error = 'Could not load options. Change the search to retry.';
      });
    }
  }

  void _move(int delta) {
    if (_loading || _count == 0) return;
    setState(() => _highlight = (_highlight + delta).clamp(-1, _count - 1));
    if (_scroll.hasClients && _highlight >= 0) {
      final top = _highlight * 52.0;
      final bottom = top + 52;
      final offset = top < _scroll.offset
          ? top
          : bottom > _scroll.offset + _scroll.position.viewportDimension
          ? bottom - _scroll.position.viewportDimension
          : _scroll.offset;
      _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
    }
  }

  void _choose(int index) {
    if (_loading || index < 0 || index >= _count) return;
    Navigator.of(context).pop(
      index < _items.length
          ? _PosChoice<T>(item: _items[index])
          : _PosChoice<T>(barcode: _query.text.trim()),
    );
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent)
      return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isShiftPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed)
      return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (event is KeyDownEvent) _choose(_highlight < 0 ? 0 : _highlight);
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.escape) {
      if (event is KeyDownEvent) Navigator.of(context).pop();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.label),
    content: SizedBox(
      width: 540,
      height: 380,
      child: Column(
        children: [
          TextField(
            controller: _query,
            focusNode: _searchFocus,
            autofocus: true,
            onChanged: _changed,
            decoration: const InputDecoration(
              labelText: 'Search',
              helperText:
                  'Up/Down: options · Right/Enter: select · Left/Esc: close',
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _count == 0
                ? Center(child: Text(_error ?? 'No matches'))
                : ListView.builder(
                    controller: _scroll,
                    itemExtent: 52,
                    itemCount: _count,
                    itemBuilder: (context, index) => Semantics(
                      selected: index == _highlight,
                      child: Material(
                        color: index == _highlight
                            ? AppColors.primarySoft
                            : Colors.transparent,
                        child: ListTile(
                          selected: index == _highlight,
                          title: Text(
                            index < _items.length
                                ? widget.itemLabel(_items[index])
                                : 'Look up barcode: ${_query.text.trim()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _choose(index),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
    ],
  );
}
