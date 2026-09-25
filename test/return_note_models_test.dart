import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/data/models/models_user/return_note_model.dart';

void main() {
  test(
    'sale return request uses sale item identifiers and optional Nepali date',
    () {
      final request = CreateReturnRequest(
        originalId: 12,
        reason: 'Damaged',
        nepaliDate: '2083-06-09',
        items: const [ReturnQuantity(45, 1.5)],
      );
      expect(request.toJson(ReturnKind.sale), {
        'saleId': 12,
        'reason': 'Damaged',
        'nepaliDate': '2083-06-09',
        'items': [
          {'saleItemId': 45, 'quantity': 1.5},
        ],
      });
    },
  );

  test(
    'purchase return request sends a date-only value and purchase item id',
    () {
      final request = CreateReturnRequest(
        originalId: 8,
        reason: 'Expired',
        date: DateTime(2026, 9, 25),
        items: const [ReturnQuantity(66, 2)],
      );
      expect(request.toJson(ReturnKind.purchase), {
        'purchaseId': 8,
        'reason': 'Expired',
        'returnDate': '2026-09-25',
        'items': [
          {'purchaseItemId': 66, 'quantity': 2.0},
        ],
      });
    },
  );

  test('credit note response retains totals and source line identifiers', () {
    final note = ReturnNoteModel.fromJson({
      'id': 3,
      'creditNoteNumber': 'CN-3',
      'saleId': 12,
      'invoiceNumber': 'INV-12',
      'returnedAt': '2026-09-25T08:10:31Z',
      'reason': 'Damaged',
      'customerName': 'Maya',
      'netTotal': 120,
      'refundAmount': 120,
      'items': [
        {
          'saleItemId': 45,
          'productName': 'Tea',
          'quantity': 1.5,
          'rate': 80,
          'lineTotal': 120,
        },
      ],
    }, ReturnKind.sale);
    expect(note.number, 'CN-3');
    expect(note.originalId, 12);
    expect(note.refundAmount, 120);
    expect(note.items.single.originalItemId, 45);
    expect(note.items.single.quantity, 1.5);
  });
}
