import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/customer_model.dart';
import '../../../shared/widgets/section_ui.dart';

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

String _formatDate(DateTime? date) => date == null
    ? 'Date unavailable'
    : '${date.day} ${_months[date.month - 1]} ${date.year}';

/// The customer's credit standing: how much is owed, how much room is left,
/// and every unpaid invoice — oldest first, with its age called out so the
/// cashier knows which debts to chase.
class CustomerCreditPanel extends StatelessWidget {
  const CustomerCreditPanel({
    super.key,
    required this.outstanding,
    required this.onSettle,
  });

  final CustomerOutstandingModel outstanding;
  final VoidCallback onSettle;

  bool get _settled => outstanding.totalOutstanding <= 0;

  bool get _overLimit =>
      outstanding.creditLimit > 0 &&
      outstanding.totalOutstanding > outstanding.creditLimit;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionPanelHeader(
            icon: Icons.account_balance_wallet_rounded,
            eyebrow: 'CREDIT ACCOUNT',
            subtitle: _settled
                ? 'Nothing outstanding'
                : '${outstanding.unpaidInvoiceCount} unpaid '
                      'invoice${outstanding.unpaidInvoiceCount == 1 ? '' : 's'}',
            trailing: SectionBadge(label: '${outstanding.unpaidInvoiceCount}'),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _settled ? const _SettledState() : _buildBalance(),
          ),
          if (!_settled) ...[
            const Divider(height: 1, color: AppColors.border),
            _buildInvoices(),
          ],
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildBalance() {
    return Column(
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
                    'OUTSTANDING',
                    style: AppTypography.eyebrow.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rs. ${formatMoneyAmount(outstanding.totalOutstanding)}',
                      style: AppTypography.metric.copyWith(
                        color: _overLimit
                            ? AppColors.error
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                'of Rs. ${formatMoneyAmount(outstanding.creditLimit)} limit',
                style: AppTypography.caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.smMd),
        _CreditBar(
          used: outstanding.totalOutstanding,
          limit: outstanding.creditLimit,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          outstanding.creditLimit <= 0
              ? 'No credit limit set for this customer.'
              : 'Rs. ${formatMoneyAmount(outstanding.availableCredit)}'
                    ' still available to spend on credit.',
          style: AppTypography.caption,
        ),
        if (_overLimit) ...[
          const SizedBox(height: AppSpacing.smMd),
          _OverLimitNotice(
            amount: outstanding.totalOutstanding - outstanding.creditLimit,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.smMd,
          children: [
            _Stat(
              label: 'Available credit',
              value: 'Rs. ${formatMoneyAmount(outstanding.availableCredit)}',
              tone: outstanding.availableCredit > 0
                  ? AppColors.success
                  : AppColors.textMuted,
            ),
            _Stat(
              label: 'Credit limit',
              value: 'Rs. ${formatMoneyAmount(outstanding.creditLimit)}',
            ),
            _Stat(
              label: 'Unpaid invoices',
              value: '${outstanding.unpaidInvoiceCount}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvoices() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'UNPAID INVOICES',
                style: AppTypography.eyebrow.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('oldest first', style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.smMd),
          for (var i = 0; i < outstanding.unpaidSales.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _InvoiceRow(sale: outstanding.unpaidSales[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSunken,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _settled ? 'BALANCE' : 'TOTAL OUTSTANDING',
                  style: AppTypography.eyebrow.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Rs. ${formatMoneyAmount(outstanding.totalOutstanding)}',
                  style: AppTypography.price.copyWith(
                    color: _settled ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (!_settled) ...[
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: BrandActionButton(
                label: 'Settle balance',
                icon: Icons.payments_rounded,
                onPressed: onSettle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Horizontal meter of credit used against the limit.
class _CreditBar extends StatelessWidget {
  const _CreditBar({required this.used, required this.limit});

  final double used;
  final double limit;

  @override
  Widget build(BuildContext context) {
    final ratio = limit <= 0 ? 1.0 : (used / limit).clamp(0.0, 1.0);
    final color = limit <= 0 || used > limit
        ? AppColors.error
        : ratio > 0.75
        ? AppColors.warning
        : AppColors.success;

    return ClipRRect(
      borderRadius: AppBorderRadius.radiusFull,
      child: Stack(
        children: [
          Container(height: 10, color: AppColors.surfaceSunken),
          FractionallySizedBox(
            widthFactor: ratio == 0 ? 0.02 : ratio,
            child: AnimatedContainer(
              duration: AppAnimations.normal,
              curve: AppAnimations.standard,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppBorderRadius.radiusFull,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverLimitNotice extends StatelessWidget {
  const _OverLimitNotice({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.smMd),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: AppBorderRadius.radiusMD,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Over the credit limit by Rs. ${formatMoneyAmount(amount)}.'
              ' Settle some invoices before selling on credit again.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettledState extends StatelessWidget {
  const _SettledState();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.successSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 26,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'All settled',
                style: AppTypography.subtitle.copyWith(
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'This customer has no unpaid credit balance.',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One unpaid invoice: how old it is, how much is left, and how far the
/// customer has already paid it down.
class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.sale});

  final CustomerOutstandingSale sale;

  int? get _ageInDays => sale.soldAt == null
      ? null
      : DateTime.now().difference(sale.soldAt!).inDays;

  AppBadgeTone get _ageTone {
    final age = _ageInDays;
    if (age == null) return AppBadgeTone.neutral;
    if (age >= 30) return AppBadgeTone.error;
    if (age >= 15) return AppBadgeTone.warning;
    return AppBadgeTone.neutral;
  }

  String get _ageLabel {
    final age = _ageInDays;
    if (age == null) return 'No date';
    if (age <= 0) return 'Today';
    return '$age day${age == 1 ? '' : 's'} old';
  }

  @override
  Widget build(BuildContext context) {
    final paidRatio = sale.netTotal <= 0
        ? 0.0
        : (sale.paidAmount / sale.netTotal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.smMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.radiusMD,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sale.invoiceNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(sale.soldAt),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppBadge(label: _ageLabel, tone: _ageTone),
              const SizedBox(width: AppSpacing.smMd),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rs. ${formatMoneyAmount(sale.dueAmount)}',
                    style: AppTypography.priceSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'of Rs. ${formatMoneyAmount(sale.netTotal)}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ],
          ),
          if (paidRatio > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppBorderRadius.radiusFull,
              child: Stack(
                children: [
                  Container(height: 5, color: AppColors.surfaceSunken),
                  FractionallySizedBox(
                    widthFactor: paidRatio,
                    child: Container(height: 5, color: AppColors.success),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Rs. ${formatMoneyAmount(sale.paidAmount)} already paid',
              style: AppTypography.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTypography.subtitle.copyWith(color: tone)),
      ],
    );
  }
}
