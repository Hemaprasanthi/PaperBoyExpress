import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperboy/screens/common/upi_payment_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  // A tall screen so the whole payment page is visible without scrolling.
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('shows a QR code and confirming payment reports the UPI reference', (tester) async {
    useTallScreen(tester);
    String? paidRef;
    bool? result;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<bool>(MaterialPageRoute(
                builder: (_) => UpiPaymentScreen(
                  amount: 123.5,
                  description: 'Test order',
                  onPaid: (ref) async => paidRef = ref,
                ),
              ));
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.textContaining('Valid for 15:00'), findsOneWidget);

    await tester.tap(find.text('I\'ve completed the payment'));
    await tester.pumpAndSettle();

    expect(paidRef, startsWith('PBX'));
    expect(result, isTrue);
  });

  testWidgets('a failing payment callback keeps the screen open and shows the error', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(MaterialApp(
      home: UpiPaymentScreen(
        amount: 10,
        description: 'Test',
        onPaid: (_) async => throw Exception('Start date must be after today'),
      ),
    ));

    await tester.tap(find.text('I\'ve completed the payment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Start date must be after today'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
  });
}
