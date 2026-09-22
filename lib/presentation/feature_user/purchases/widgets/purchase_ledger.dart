import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/purchase_model.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Purchases as a running ledger rather than a grid of cells.
///
/// Money spent is a story told by day, so bills are grouped under the date
/// they arrived, each group carrying its own spend — the question a mart
/// owner actually asks of this screen ("what did this week cost me?") is
/// answered by scrolling, without any filtering or arithmetic.
class PurchaseLedger extends StatelessWidget {
  const PurchaseLedger({
    super.key,
    required this.purchases,
    required this.onOpen,
  });

  final List<PurchaseModel> purchases;
  final ValueChanged<PurchaseModel> onOpen;

  /// Groups in the order the backend returned them, so paging stays stable.
  List<_DayGroup> get _groups {
    final groups = <_DayGroup>[];
    for (final purchase in purchases) {
      final date = purchase.purchaseDate ?? purchase.createdAt;
      final key = date == null
          ? 'undated'
          : '${date.year}-${date.month}-${date.day}';
      if (groups.isNotEmpty && groups.last.key == key) {
        groups.last.purchases.add(purchase);
      } else {
        groups.add(_DayGroup(key: key, date: date, purchases: [purchase]));
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    // Measured once here rather than per entry: each entry sits inside an
    // IntrinsicHeight (for the rail), which cannot contain a LayoutBuilder.
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          itemCount: groups.length,
          itemBuilder: (context, index) => AppStaggered(
            index: index,
            child: _DaySection(
              group: groups[index],
              compact: compact,
              onOpen: onOpen,
            ),
          ),
        );
      },
    );
  }
}

class _DayGroup {
  _DayGroup({required this.key, required this.date, required this.purchases});

  final String key;
  final DateTime? date;
  final List<PurchaseModel> purchases;

  double get spend =>
      purchases.fold(0, (sum, purchase) => sum + purchase.netTotal);

  String get label {
    final date = this.date;
    if (date == null) return 'Undated';
    final now = DateTime.now();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(date.year, date.month, date.day)).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '${_weekdays[date.weekday - 1]}, ${date.day} '
        '${_months[date.month - 1]} ${date.year}';
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.group,
    required this.compact,
    required this.onOpen,
  });

  final _DayGroup group;
  final bool compact;
  final ValueChanged<PurchaseModel> onOpen;

  @override
  Widget build(BuildContext context) {
    final count = group.purchases.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          // A long date and a large sum cannot share one line on a phone,
          // so the spend drops beneath the date there instead of squeezing.
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DayLabel(label: group.label),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _DaySpend(spend: group.spend),
                        _DayCount(count: count),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Flexible(child: _DayLabel(label: group.label)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Container(height: 1, color: AppColors.border),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _DaySpend(spend: group.spend),
                    _DayCount(count: count),
                  ],
                ),
        ),
        for (var i = 0; i < group.purchases.length; i++)
          _LedgerEntry(
            purchase: group.purchases[i],
            compact: compact,
            isLast: i == group.purchases.length - 1,
            onTap: () => onOpen(group.purchases[i]),
          ),
      ],
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppTypography.labelSmall.copyWith(
      fontSize: 13,
      color: AppColors.textPrimary,
    ),
  );
}

class _DaySpend extends StatelessWidget {
  const _DaySpend({required this.spend});

  final double spend;

  @override
  Widget build(BuildContext context) => Text(
    'Rs. ${formatMoneyAmount(spend)}',
    style: AppTypography.priceSmall.copyWith(color: AppColors.primaryDeep),
  );
}

class _DayCount extends StatelessWidget {
  const _DayCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Text(
    ' · $count bill${count == 1 ? '' : 's'}',
    style: AppTypography.caption,
  );
}

/// One bill, hung off the day's timeline rail.
class _LedgerEntry extends StatefulWidget {
  const _LedgerEntry({
    required this.purchase,
    required this.compact,
    required this.isLast,
    required this.onTap,
  });

  final PurchaseModel purchase;
  final bool compact;
  final bool isLast;
  final VoidCallback onTap;

  @override
  State<_LedgerEntry> createState() => _LedgerEntryState();
}

class _LedgerEntryState extends State<_LedgerEntry> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final purchase = widget.purchase;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Rail(hovered: _hovered, isLast: widget.isLast),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: AppPressable(
                  onTap: widget.onTap,
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    curve: AppAnimations.standard,
                    padding: const EdgeInsets.all(AppSpacing.smMd),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: AppBorderRadius.radiusL,
                      border: Border.all(
                        color: _hovered ? AppColors.primary : AppColors.border,
                      ),
                      boxShadow: _hovered ? AppShadows.card : AppShadows.none,
                    ),
                    child: widget.compact
                        ? _CompactEntry(purchase: purchase)
                        : _WideEntry(purchase: purchase),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The vertical thread that ties a day's bills together.
class _Rail extends StatelessWidget {
  const _Rail({required this.hovered, required this.isLast});

  final bool hovered;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          AnimatedContainer(
            duration: AppAnimations.fast,
            width: hovered ? 12 : 9,
            height: hovered ? 12 : 9,
            decoration: BoxDecoration(
              color: hovered ? AppColors.primary : AppColors.borderStrong,
              shape: BoxShape.circle,
            ),
          ),
          if (!isLast)
            Expanded(child: Container(width: 2, color: AppColors.border)),
        ],
      ),
    );
  }
}

class _WideEntry extends StatelessWidget {
  const _WideEntry({required this.purchase});

  final PurchaseModel purchase;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                purchase.vendorName?.isNotEmpty == true
                    ? purchase.vendorName!
                    : 'Unnamed supplier',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  _BillChip(billNumber: purchase.billNumber),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${purchase.itemCount} '
                    'item${purchase.itemCount == 1 ? '' : 's'}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (purchase.paymentMethod != null)
          AppBadge(
            label: formatPaymentMethod(purchase.paymentMethod),
            tone: AppBadgeTone.neutral,
          ),
        const SizedBox(width: AppSpacing.md),
        _Amount(purchase: purchase),
      ],
    );
  }
}

class _CompactEntry extends StatelessWidget {
  const _CompactEntry({required this.purchase});

  final PurchaseModel purchase;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                purchase.vendorName?.isNotEmpty == true
                    ? purchase.vendorName!
                    : 'Unnamed supplier',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _Amount(purchase: purchase),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _BillChip(billNumber: purchase.billNumber),
            Text(
              '${purchase.itemCount} '
              'item${purchase.itemCount == 1 ? '' : 's'}',
              style: AppTypography.caption,
            ),
            if (purchase.paymentMethod != null)
              AppBadge(
                label: formatPaymentMethod(purchase.paymentMethod),
                tone: AppBadgeTone.neutral,
              ),
          ],
        ),
      ],
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this.purchase});

  final PurchaseModel purchase;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Rs. ${formatMoneyAmount(purchase.netTotal)}',
          style: AppTypography.priceSmall.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          purchase.discountAmount > 0
              ? 'less Rs. ${formatMoneyAmount(purchase.discountAmount)}'
              : 'incl. VAT ${formatMoneyAmount(purchase.vatAmount)}',
          style: AppTypography.caption,
        ),
      ],
    );
  }
}

class _BillChip extends StatelessWidget {
  const _BillChip({required this.billNumber});

  final String billNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: AppBorderRadius.radiusXS,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        billNumber.isEmpty ? 'No bill no.' : billNumber,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
