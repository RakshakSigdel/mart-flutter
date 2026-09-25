import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/core.dart';
import '../../../../data/models/models_shared/commerce_model.dart';
import '../../../../data/models/models_user/return_note_model.dart';

class ReturnNoteCard extends StatelessWidget {
  const ReturnNoteCard({
    super.key,
    required this.note,
    required this.kind,
    this.compact = false,
  });
  final ReturnNoteModel note;
  final ReturnKind kind;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: InkWell(
      onTap: compact
          ? () => context.push(
              kind == ReturnKind.sale
                  ? Routes.salesReturnDetail(note.id)
                  : Routes.purchaseReturnDetail(note.id),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(note.number, style: AppTypography.subtitle),
                ),
                Text(
                  formatMoneyAmount(note.netTotal),
                  style: AppTypography.subtitle,
                ),
              ],
            ),
            Text(
              '${note.billNumber}  •  ${note.partyName ?? ''}  •  ${note.date == null ? '' : formatAppDate(note.date!)}',
              style: AppTypography.bodySmall,
            ),
            if (!compact) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Reason: ${note.reason}'),
              if (note.taxScheme != null)
                Text('Tax scheme: ${formatTaxScheme(note.taxScheme)}'),
              if (note.nepaliDate != null && note.nepaliDate!.isNotEmpty)
                Text('Nepali date: ${note.nepaliDate}'),
              if (note.fiscalYear != null && note.fiscalYear!.isNotEmpty)
                Text('Fiscal year: ${note.fiscalYear}'),
              if (note.partyPan != null && note.partyPan!.isNotEmpty)
                Text('Customer PAN: ${note.partyPan}'),
              if (note.remark != null && note.remark!.isNotEmpty)
                Text('Remark: ${note.remark}'),
              if (kind == ReturnKind.sale && note.refundAmount != null)
                Text('Refund: ${formatMoneyAmount(note.refundAmount!)}'),
              for (final line in note.items)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${line.productName}: ${formatMoneyAmount(line.quantity)} ${line.unitSymbol ?? ''} × ${formatMoneyAmount(line.rate)} = ${formatMoneyAmount(line.lineTotal)}',
                  ),
                ),
              const Divider(),
              Text(
                'Subtotal ${formatMoneyAmount(note.subTotal)}  •  Discount ${formatMoneyAmount(note.discountAmount)}  •  Taxable ${formatMoneyAmount(note.taxableAmount)}  •  VAT ${formatMoneyAmount(note.vatAmount)}',
                style: AppTypography.bodySmall,
              ),
              if (note.syncWithIrd != null)
                Text(
                  'IRD sync: ${note.syncWithIrd! ? 'Yes' : 'No'}',
                  style: AppTypography.bodySmall,
                ),
            ],
          ],
        ),
      ),
    ),
  );
}
