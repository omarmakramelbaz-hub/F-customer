import 'package:faskhaninja/helpers/payment/order_payment_confirmation.dart';
import 'package:faskhaninja/view/custom_widgets/custom_payment_web_view/custom_payment_web_view.dart';
import 'package:faskhaninja/view/custom_widgets/custom_payment_web_view/embedded_payment_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Harness {
  final navigator = GlobalKey<NavigatorState>();
  late PaymentBrowserEvents events;
  var state = PaymentConfirmation.waiting;
  var successes = 0;
  var failures = 0;
  var reads = 0;
  var builds = 0;
  final requestedIds = <int>[];

  Future<void> mount(WidgetTester tester, {int? orderId = 42}) async {
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigator,
      home: Scaffold(
        body: Builder(
            builder: (context) => TextButton(
                  child: const Text('checkout'),
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => CustomPaymentWebViewScreen(
                      args: PaymentArgs(
                        url:
                            'https://accept.paymob.com/unifiedcheckout/?clientSecret=synthetic-test',
                        orderId: orderId,
                        onFailed: () => failures++,
                        onSuccess: () {
                          successes++;
                          navigator.currentState!.push(MaterialPageRoute<void>(
                            builder: (_) =>
                                Scaffold(body: Text('tracking-$orderId')),
                          ));
                        },
                      ),
                      confirmationReader: (id) async {
                        requestedIds.add(id);
                        reads++;
                        return state;
                      },
                      browserBuilder: (_, value) {
                        builds++;
                        events = value;
                        return const ColoredBox(
                            key: ValueKey('embedded-browser'),
                            color: Colors.white);
                      },
                    ),
                  )),
                )),
      ),
    ));
    await tester.tap(find.text('checkout'));
    await tester.pump();
    events.progress(1);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets(
      'gateway success hint waits for the server then opens tracking once',
      (tester) async {
    final harness = _Harness();
    await harness.mount(tester);
    final oldEvents = harness.events;
    expect(
        await oldEvents.navigate(
            Uri.parse('https://accept.paymob.com/?success=true'), true),
        isTrue);
    expect(
        await oldEvents.navigate(
            Uri.parse('https://fasakhaninja.com/pay-thanks'), false),
        isTrue);
    expect(harness.successes, 0);

    expect(
        await oldEvents.navigate(
            Uri.parse('https://fasakhaninja.com/pay-thanks'), true),
        isFalse);
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaymentWebViewScreen), findsOneWidget);
    expect(harness.successes, 0);

    harness.state = PaymentConfirmation.confirmed;
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('tracking-42'), findsOneWidget);
    expect(find.byType(CustomPaymentWebViewScreen), findsNothing);
    expect(harness.successes, 1);

    await oldEvents.navigate(
        Uri.parse('https://fasakhaninja.com/pay-thanks'), true);
    await tester.pumpAndSettle();
    expect(harness.successes, 1);
    expect(find.text('tracking-42'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'server confirmation opens tracking even without a readable iframe redirect',
      (tester) async {
    final harness = _Harness();
    await harness.mount(tester);
    harness.state = PaymentConfirmation.confirmed;
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('tracking-42'), findsOneWidget);
    expect(harness.successes, 1);
    expect(harness.failures, 0);
    expect(harness.requestedIds.every((id) => id == 42), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'failure closes only payment; closing or retrying never reports success',
      (tester) async {
    final harness = _Harness();
    await harness.mount(tester);
    harness.events.error();
    await tester.pump();
    expect(find.byKey(const ValueKey('retry-payment')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('retry-payment')));
    await tester.pump();
    expect(harness.events.url.host, 'accept.paymob.com');
    harness.events.progress(1);
    await tester.pumpAndSettle();
    expect(harness.successes, 0);
    expect(harness.failures, 0);
    await harness.events
        .navigate(Uri.parse('https://fasakhaninja.com/pay-false'), true);
    await tester.pumpAndSettle();
    expect(find.text('checkout'), findsOneWidget);
    expect(harness.failures, 1);
    expect(harness.successes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual close cancels polling without inventing a payment result',
      (tester) async {
    final harness = _Harness();
    await harness.mount(tester);
    await tester.tap(find.byKey(const ValueKey('close-payment')));
    await tester.pumpAndSettle();
    final calls = harness.reads;
    harness.state = PaymentConfirmation.confirmed;
    await tester.pump(const Duration(seconds: 6));
    expect(harness.reads, calls);
    expect(harness.successes, 0);
    expect(harness.failures, 0);
  });

  testWidgets('wallet callbacks run after the payment route has been removed',
      (tester) async {
    final harness = _Harness();
    await harness.mount(tester, orderId: null);
    await harness.events
        .navigate(Uri.parse('https://fasakhaninja.com/pay-thanks'), true);
    await tester.pumpAndSettle();
    expect(harness.reads, 0);
    expect(harness.successes, 1);
    expect(find.text('tracking-null'), findsOneWidget);
    expect(find.byType(CustomPaymentWebViewScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
