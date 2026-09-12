import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/data/models/models_shared/commerce_model.dart';
import 'package:sts_retail/data/models/models_user/customer_model.dart';

void main() {
  test('parses outstanding invoices and balances', () {
    final outstanding = CustomerOutstandingModel.fromJson({
      'customerId': 4,
      'customerName': 'Asha',
      'creditLimit': 5000,
      'totalOutstanding': 1250.5,
      'availableCredit': 3749.5,
      'unpaidInvoiceCount': 1,
      'unpaidSales': [
        {
          'id': 22,
          'invoiceNumber': 'INV-22',
          'soldAt': '2026-09-12T04:52:40.711Z',
          'netTotal': 1500,
          'paidAmount': 249.5,
          'dueAmount': 1250.5,
          'paymentStatus': 'PARTIALLY_PAID',
        },
      ],
    });

    expect(outstanding.totalOutstanding, 1250.5);
    expect(outstanding.unpaidSales.single.invoiceNumber, 'INV-22');
    expect(outstanding.unpaidSales.single.dueAmount, 1250.5);
  });

  test('settlement request serializes amount, payment method and remark', () {
    expect(
      const SettleCustomerCreditRequest(
        amount: 500,
        paymentMethod: PaymentMethod.bankTransfer,
        remark: 'Receipt 98',
      ).toJson(),
      {
        'amount': 500.0,
        'paymentMethod': 'BANK_TRANSFER',
        'remark': 'Receipt 98',
      },
    );
  });
}
