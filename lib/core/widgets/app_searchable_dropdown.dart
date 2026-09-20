import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

// ─── Searchable dropdown ──────────────────────────────────────────────────────
//
// CONCEPT: AppSearchableDropdownField<T> works exactly like AppDropdownField<T>
// but adds a search box inside the popup.
//
// T is the data type of each item (e.g. StaffMember, Category, TableModel).
//
// [items]              — the full list of T (no pagination)
// [asyncItems]         — async fetch given a search string (single page, no pagination)
// [pagedAsyncItems]    — async fetch with pagination: (filter, page, pageSize) => List<T>
//                        Use this for large server-side lists. Enables infinite scroll.
// [selectedItem]       — the currently selected T (or null)
// [onChanged]          — called when the user picks an item
// [itemLabel]          — converts T to the string shown in the list and searched
// [label]              — optional field label above the dropdown
// [hint]               — placeholder text when nothing is selected
// [searchHint]         — placeholder inside the search box
// [pageSize]           — items per page when using pagedAsyncItems (default: 20)

class AppSearchableDropdownField<T> extends StatelessWidget {
  final String? label;
  final T? selectedItem;
  final List<T>? items;
  final Future<List<T>> Function(String)? asyncItems;

  /// Paginated async loader: called with (filter, page, pageSize).
  /// Use this instead of [asyncItems] to enable infinite scroll.
  final Future<List<T>> Function(String filter, int page, int pageSize)?
  pagedAsyncItems;
  final int pageSize;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabel;
  final String? hint;
  final String searchHint;
  final String? Function(T?)? validator;
  final bool Function(T)? itemDisabled;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool showClearButton;
  final IconData? actionIcon;
  final VoidCallback? onActionPressed;
  final String? actionTooltip;

  const AppSearchableDropdownField({
    super.key,
    this.label,
    required this.selectedItem,
    this.items,
    this.asyncItems,
    this.pagedAsyncItems,
    this.pageSize = 20,
    required this.onChanged,
    required this.itemLabel,
    this.hint,
    this.searchHint = 'Search...',
    this.validator,
    this.itemDisabled,
    this.focusNode,
    this.autofocus = false,
    this.showClearButton = false,
    this.actionIcon,
    this.onActionPressed,
    this.actionTooltip,
  }) : assert(
         items != null || asyncItems != null || pagedAsyncItems != null,
         'Either items, asyncItems, or pagedAsyncItems must be provided',
       );

  // ── Shared border decoration ───────────────────────────────────────────────

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: AppBorderRadius.radiusL,
    borderSide: BorderSide(color: color),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optional label
        if (label != null) ...[
          Text(label!, style: AppTypography.fieldLabel),
          const SizedBox(height: 8),
        ],

        // CONCEPT: DropdownSearch<T>
        // - items: the full list — the package filters it as the user types
        // - itemAsString: tells the package what text represents each T,
        //   used for both display and search filtering
        // - compareFn: tells the package how to match selectedItem to an
        //   item in the list — without this, selection highlight breaks
        Stack(
          children: [
            DropdownSearch<T>(
          // Use loadProps for paged fetching; fall back to asyncItems or local list
          items: (filter, loadProps) {
            if (pagedAsyncItems != null) {
              final skip = loadProps?.skip ?? 0;
              final take = loadProps?.take ?? pageSize;
              final page = skip ~/ take;
              return pagedAsyncItems!(filter, page, take);
            }
            if (asyncItems != null) return asyncItems!(filter);
            return items!;
          },
          selectedItem: selectedItem,
          onSelected: onChanged,
          itemAsString: itemLabel,
          // Only apply local filter when using a static list
          filterFn:
              (items != null && asyncItems == null && pagedAsyncItems == null)
              ? (item, filter) =>
                    itemLabel(item).toLowerCase().contains(filter.toLowerCase())
              : null,
          compareFn: (a, b) => itemLabel(a) == itemLabel(b),
          validator: validator,
          clickProps: ClickProps(
            focusNode: focusNode,
            autofocus: autofocus,
          ),
          suffixProps: DropdownSuffixProps(
            clearButtonProps: ClearButtonProps(isVisible: showClearButton),
          ),

          // ── Closed state (what the user sees before opening) ─────────────
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              contentPadding: EdgeInsets.fromLTRB(
                16,
                12,
                actionIcon == null ? 16 : 64,
                12,
              ),
              border: _border(AppColors.border),
              enabledBorder: _border(AppColors.border),
              focusedBorder: _border(AppColors.primaryDeep),
              errorBorder: _border(AppColors.error),
              filled: true,
              fillColor: AppColors.card,
            ),
          ),

          // ── Popup (the dropdown panel that opens) ─────────────────────────
          popupProps: PopupProps.menu(
            showSearchBox: true,
            disabledItemFn: itemDisabled,
            // Enable infinite scroll only when pagedAsyncItems is provided
            infiniteScrollProps: pagedAsyncItems != null
                ? InfiniteScrollProps(loadProps: LoadProps(take: pageSize))
                : null,

            searchFieldProps: TextFieldProps(
              autofocus: true,
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: _border(AppColors.border),
                enabledBorder: _border(AppColors.border),
                focusedBorder: _border(AppColors.primaryDeep),
                filled: true,
                fillColor: AppColors.card,
              ),
            ),

            constraints: const BoxConstraints(maxHeight: 300),
            menuProps: MenuProps(
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.radiusL,
              ),
              backgroundColor: AppColors.card,
              elevation: 8,
            ),

            itemBuilder: (context, item, isDisabled, isSelected) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.smMd,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primarySoft : Colors.transparent,
              ),
              child: Opacity(
                opacity: isDisabled ? 0.5 : 1.0,
                child: Text(
                  itemLabel(item),
                  style: AppTypography.body.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    decoration: isDisabled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),

            emptyBuilder: (context, searchEntry) => Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  'No results for "$searchEntry"',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
            ),
            if (actionIcon != null)
              Positioned(
                right: 40,
                top: 0,
                bottom: 0,
                child: IconButton(
                  onPressed: onActionPressed,
                  icon: Icon(actionIcon, size: 20),
                  tooltip: actionTooltip,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Usage ────────────────────────────────────────────────────────────────────
//
// Standard dropdown (no search) — unchanged:
// AppDropdownField<String>(
//   label: 'Payment Method',
//   value: _paymentMethod,
//   hint: 'Select method',
//   items: const [
//     DropdownMenuItem(value: 'CASH', child: Text('Cash')),
//     DropdownMenuItem(value: 'FONEPAY', child: Text('Fonepay')),
//   ],
//   onChanged: (val) => setState(() => _paymentMethod = val),
// )
//
// Searchable dropdown — for long lists:
// AppSearchableDropdownField<StaffMember>(
//   label: 'Assign Staff',
//   selectedItem: _selectedStaff,
//   hint: 'Select a staff member',
//   searchHint: 'Search by name...',
//   items: staffList,
//   itemLabel: (staff) => '${staff.username} (${staff.role.label})',
//   onChanged: (val) => setState(() => _selectedStaff = val),
// )
//
// With validation:
// AppSearchableDropdownField<Category>(
//   label: 'Category',
//   selectedItem: _selectedCategory,
//   items: categories,
//   itemLabel: (cat) => cat.name,
//   onChanged: (val) => setState(() => _selectedCategory = val),
//   validator: (val) => val == null ? 'Please select a category' : null,
// )
