import 'dart:async';

import 'package:faskhaninja/helpers/payment/order_payment_confirmation.dart';
import 'package:faskhaninja/helpers/payment/payment_navigation_policy.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _order(
        {String? status, String method = 'online', int id = 42}) =>
    {
      'id': id,
      'type': 'current',
      'payment_type': method,
      'status': status,
    };

void main() {
  const waiting = PaymentConfirmation.waiting;
  const paid = PaymentConfirmation.confirmed;

  test('gateway query strings and unrelated pages are not payment receipts',
      () {
    final policy =
        PaymentNavigationPolicy(Uri.parse('https://fasakhaninja.com/api/'));
    for (final url in [
      'https://accept.paymob.com/unifiedcheckout/?success=true',
      'https://other.example/pay-thanks',
      'https://fasakhaninja.com.other.example/pay-thanks',
      'https://fasakhaninja.com/path/pay-thanks',
      'https://fasakhaninja.com/?next=pay-thanks',
      'https://fasakhaninja.com:444/pay-thanks',
      'http://fasakhaninja.com/pay-thanks',
      'https://user@fasakhaninja.com/pay-thanks',
    ]) {
      expect(policy.result(Uri.parse(url)), isNull, reason: url);
    }
    expect(policy.result(Uri.parse('https://fasakhaninja.com/pay-thanks/')),
        PaymentReturn.success);
    expect(policy.result(Uri.parse('https://fasakhaninja.com/pay-false')),
        PaymentReturn.failure);
    expect(
        policy.isCheckoutUrl(
            Uri.parse('https://accept.paymob.com/unifiedcheckout/')),
        isTrue);
    expect(
        policy.isCheckoutUrl(Uri.parse('https://paymob.com.attacker.example/')),
        isFalse);
    expect(policy.canNavigate(Uri.parse('intent://example')), isFalse);
  });

  test('only the exact authenticated online order activation confirms payment',
      () {
    for (final method in ['online', 'v_cash']) {
      expect(OrderPaymentConfirmation.fromOrder(_order(method: method), 42),
          waiting);
      for (final status in ['pending', 'accepted', 'shipped', 'completed']) {
        expect(
            OrderPaymentConfirmation.fromOrder(
                _order(status: status, method: method), 42),
            paid);
      }
    }
    for (final data in [
      null,
      _order(status: 'pending', id: 43),
      _order(status: 'pending', method: 'cash'),
      _order(status: 'pending', method: 'wallet'),
      {..._order(status: 'pending'), 'type': 'wallet'},
      _order(status: 'cancelled'),
      _order(status: 'unknown'),
      {..._order(status: 'pending'), 'payment_status': 'pending'},
      {..._order(status: 'pending'), 'is_paid': false},
    ]) {
      expect(OrderPaymentConfirmation.fromOrder(data, 42), waiting);
    }
    expect(
        OrderPaymentConfirmation.fromOrder(
            {..._order(), 'payment_status': 'paid'}, 42),
        paid);
    expect(
        OrderPaymentConfirmation.fromOrder(
            {..._order(), 'payment_status': 'failed'}, 42),
        PaymentConfirmation.failed);
  });

  testWidgets(
      'polling cannot overlap and notifies once after server confirmation',
      (tester) async {
    final first = Completer<PaymentConfirmation>();
    var calls = 0;
    var notifications = 0;
    final requestedIds = <int>[];
    final monitor = PaymentConfirmationMonitor(
      orderId: 42,
      read: (id) {
        requestedIds.add(id);
        calls++;
        return calls == 1 ? first.future : Future.value(paid);
      },
    )..addListener(() => notifications++);
    monitor.resume();
    await monitor.checkNow();
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 1);
    first.complete(waiting);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(calls, 2);
    expect(monitor.result, paid);
    expect(notifications, 1);
    expect(requestedIds, [42, 42]);
    await tester.pump(const Duration(seconds: 20));
    expect(calls, 2);
    monitor.dispose();
  });

  testWidgets('offline and stale results do not confirm or fail a payment',
      (tester) async {
    final late = Completer<PaymentConfirmation>();
    var calls = 0;
    final monitor = PaymentConfirmationMonitor(
      orderId: 42,
      read: (_) async {
        calls++;
        if (calls == 1) throw StateError('offline');
        return late.future;
      },
    );
    monitor.resume();
    await tester.pump();
    expect(monitor.result, waiting);
    await tester.pump(const Duration(seconds: 4));
    expect(calls, 2);
    monitor.pause();
    late.complete(paid);
    await tester.pump();
    expect(monitor.result, waiting);
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 2);
    monitor.dispose();
  });
}
