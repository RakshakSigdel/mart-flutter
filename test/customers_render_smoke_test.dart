// Render guard for the customer + credit screens at each breakpoint.
//
// The credit panel stacks meters, invoice rows and a totals footer inside one
// card, so a spacing or type-scale change can start overflowing at one width
// while looking fine at another. These pump each piece and fail on any layout
// exception.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sts_retail/core/core.dart';
import 'package:sts_retail/data/datasource/datasource_user/customer_datasource.dart';
import 'package:sts_retail/data/models/models_user/customer_model.dart';
import 'package:sts_retail/presentation/feature_user/customers/screens/customer_detail_screen.dart';
import 'package:sts_retail/presentation/feature_user/customers/screens/customers_screen.dart';
import 'package:sts_retail/providers/providers_user/customer_provider.dart';
import 'package:sts_retail/presentation/feature_user/customers/widgets/customer_credit_panel.dart';
import 'package:sts_retail/presentation/feature_user/customers/widgets/customer_settle_dialog.dart';
import 'package:sts_retail/presentation/feature_user/customers/widgets/customers_list_card.dart';
import 'package:sts_retail/presentation/feature_user/customers/widgets/customers_table.dart';

CustomerModel _customer({double creditLimit = 5000}) => CustomerModel.fromJson({
  'id': 1,
  'name': 'Sita Kumari Shrestha',
  'phone': '9800000000',
  'email': 'sita.shrestha@example.com',
  'panNumber': '301234567',
  'address': 'Ward 4, Lalitpur, Bagmati Province',
  'creditLimit': creditLimit,
  'active': true,
});

CustomerOutstandingModel _outstanding({
  double total = 3200,
  double limit = 5000,
  int invoices = 3,
}) => CustomerOutstandingModel.fromJson({
  'customerId': 1,
  'customerName': 'Sita Kumari Shrestha',
  'creditLimit': limit,
  'totalOutstanding': total,
  'availableCredit': (limit - total).clamp(0, limit),
  'unpaidInvoiceCount': invoices,
  'unpaidSales': [
    for (var i = 0; i < invoices; i++)
      {
        'id': i + 1,
        'invoiceNumber': 'INV-00${i + 1}',
        'soldAt': DateTime.now()
            .subtract(Duration(days: 40 - (i * 18)))
            .toIso8601String(),
        'netTotal': 1500.0,
        'paidAmount': i.isEven ? 300.0 : 0.0,
        'dueAmount': i.isEven ? 1200.0 : 1500.0,
        'paymentStatus': 'UNPAID',
      },
  ],
});

Widget _wrap(Size size, Widget child) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: SizedBox(width: size.width, height: size.height, child: child),
    ),
  ),
);

/// Serves the customer endpoints the screens hit on first build, so the
/// screens can be pumped without a backend.
Dio _fakeDio() {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final Object data = options.path.contains('outstanding')
            ? {
                'customerId': 1,
                'customerName': 'Sita Kumari Shrestha',
                'creditLimit': 5000.0,
                'totalOutstanding': 3200.0,
                'availableCredit': 1800.0,
                'unpaidInvoiceCount': 2,
                'unpaidSales': [
                  {
                    'id': 1,
                    'invoiceNumber': 'INV-001',
                    'soldAt': DateTime.now()
                        .subtract(const Duration(days: 33))
                        .toIso8601String(),
                    'netTotal': 2000.0,
                    'paidAmount': 300.0,
                    'dueAmount': 1700.0,
                    'paymentStatus': 'PARTIAL',
                  },
                  {
                    'id': 2,
                    'invoiceNumber': 'INV-002',
                    'soldAt': DateTime.now()
                        .subtract(const Duration(days: 4))
                        .toIso8601String(),
                    'netTotal': 1500.0,
                    'paidAmount': 0.0,
                    'dueAmount': 1500.0,
                    'paymentStatus': 'UNPAID',
                  },
                ],
              }
            : options.path.endsWith('/customers')
            ? {
                'content': [
                  {
                    'id': 1,
                    'name': 'Sita Kumari Shrestha',
                    'phone': '9800000000',
                    'email': 'sita.shrestha@example.com',
                    'creditLimit': 5000.0,
                    'active': true,
                  },
                  {
                    'id': 2,
                    'name': 'Hari Bahadur',
                    'creditLimit': 0.0,
                    'active': false,
                  },
                ],
                'pageNumber': 1,
                'totalPages': 3,
                'totalElements': 24,
              }
            : {
                'id': 1,
                'name': 'Sita Kumari Shrestha',
                'phone': '9800000000',
                'email': 'sita.shrestha@example.com',
                'panNumber': '301234567',
                'address': 'Ward 4, Lalitpur',
                'creditLimit': 5000.0,
                'active': true,
              };
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'success': true, 'data': data},
          ),
        );
      },
    ),
  );
  return dio;
}

Widget _screenHarness(Size size, Widget child) => ProviderScope(
  overrides: [
    customerRemoteDataSourceProvider.overrideWithValue(
      CustomerRemoteDataSource(_fakeDio()),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    // The list screen is embedded in the admin shell, which supplies the
    // Scaffold it relies on; the detail screen brings its own.
    home: Scaffold(
      body: SizedBox(width: size.width, height: size.height, child: child),
    ),
  ),
);

void main() {
  for (final entry in {
    'desktop': const Size(1440, 900),
    'tablet': const Size(820, 700),
    'phone': const Size(420, 780),
  }.entries) {
    Future<void> pump(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(entry.value, child));
      await tester.pumpAndSettle();
    }

    testWidgets('credit panel renders with a balance at ${entry.key}', (
      tester,
    ) async {
      await pump(
        tester,
        SingleChildScrollView(
          child: CustomerCreditPanel(
            outstanding: _outstanding(),
            onSettle: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('CREDIT ACCOUNT'), findsOneWidget);
      expect(find.text('Settle balance'), findsOneWidget);
    });

    testWidgets('credit panel renders over the limit at ${entry.key}', (
      tester,
    ) async {
      await pump(
        tester,
        SingleChildScrollView(
          child: CustomerCreditPanel(
            outstanding: _outstanding(total: 7400, limit: 5000),
            onSettle: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Over the credit limit'), findsOneWidget);
    });

    testWidgets('credit panel renders when settled at ${entry.key}', (
      tester,
    ) async {
      await pump(
        tester,
        SingleChildScrollView(
          child: CustomerCreditPanel(
            outstanding: _outstanding(total: 0, invoices: 0),
            onSettle: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('All settled'), findsOneWidget);
      expect(find.text('Settle balance'), findsNothing);
    });

    testWidgets('settle dialog renders at ${entry.key}', (tester) async {
      await pump(
        tester,
        const SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md),
          child: CustomerSettleDialog(customerId: 1, outstandingBalance: 3200),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Full balance'), findsOneWidget);
      expect(find.text('Settle in full'), findsOneWidget);
    });

    testWidgets('customer card renders at ${entry.key}', (tester) async {
      await pump(
        tester,
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: CustomerListCard(
            customer: _customer(),
            isBusy: false,
            onAction: (_) {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Sita Kumari Shrestha'), findsOneWidget);
    });
  }

  testWidgets('customers table renders on a wide viewport', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _wrap(
        const Size(1440, 900),
        SingleChildScrollView(
          child: CustomersTable(
            customers: [_customer(), _customer(creditLimit: 0)],
            busyIds: const {},
            onAction: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('CUSTOMER'), findsOneWidget);
    expect(find.text('No credit'), findsOneWidget);
  });

  for (final entry in {
    'desktop': const Size(1440, 900),
    'phone': const Size(420, 780),
  }.entries) {
    testWidgets('customers list screen renders at ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _screenHarness(entry.value, const CustomersScreen()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('CUSTOMERS'), findsOneWidget);
      expect(find.textContaining('Sita'), findsWidgets);
    });

    testWidgets('customer detail screen renders at ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _screenHarness(entry.value, const CustomerDetailScreen(customerId: 1)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('CREDIT ACCOUNT'), findsOneWidget);
      expect(find.text('CUSTOMER'), findsOneWidget);
    });
  }

  testWidgets('tapping a table row opens the customer', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    CustomerModel? opened;
    await tester.pumpWidget(
      _wrap(
        const Size(1440, 900),
        SingleChildScrollView(
          child: CustomersTable(
            customers: [_customer()],
            busyIds: const {},
            onAction: (customer, _) => opened = customer,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sita Kumari Shrestha'));
    await tester.pumpAndSettle();

    expect(opened?.name, 'Sita Kumari Shrestha');
  });
}
