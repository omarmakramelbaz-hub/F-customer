import 'dart:async';

import 'package:flutter/foundation.dart';

import '../hive/hive_methods.dart';
import '../networking/api_helper.dart';
import '../networking/urls.dart';

enum PaymentConfirmation { waiting, confirmed, failed }

typedef PaymentConfirmationReader = Future<PaymentConfirmation> Function(
    int id);

/// Reads the authenticated order only; it never changes a payment or order.
class OrderPaymentConfirmation {
  OrderPaymentConfirmation() : _session = HiveMethods.getToken();

  final String? _session;

  Future<PaymentConfirmation> read(int orderId) async {
    if (_session == null ||
        HiveMethods.getToken() != _session ||
        orderId <= 0) {
      return PaymentConfirmation.waiting;
    }
    final response =
        await ApiHelper.instance.get('${Urls.detailsOrders}/$orderId');
    if (HiveMethods.getToken() != _session ||
        response.state != ResponseState.complete ||
        response.data is! Map) {
      return PaymentConfirmation.waiting;
    }
    return fromOrder(response.data['data'], orderId);
  }

  static PaymentConfirmation fromOrder(dynamic data, int orderId) {
    if (orderId <= 0 ||
        data is! Map ||
        int.tryParse('${data['id']}') != orderId ||
        data['type'] != 'current' ||
        !const ['online', 'v_cash'].contains(data['payment_type'])) {
      return PaymentConfirmation.waiting;
    }
    // Prefer explicit receipt fields if supplied by a newer server.
    for (final key in ['payment_confirmed', 'is_paid', 'payment_status']) {
      if (!data.containsKey(key)) continue;
      final value = '${data[key]}'.toLowerCase();
      if (const ['true', '1', 'paid', 'succeeded', 'success', 'completed']
          .contains(value)) {
        return PaymentConfirmation.confirmed;
      }
      if (const ['failed', 'declined', 'refunded', 'voided'].contains(value)) {
        return PaymentConfirmation.failed;
      }
      return PaymentConfirmation.waiting;
    }
    // Legacy restaurant checkout creates these orders with status=null.
    // RestaurantOrderPayment sets pending only after authenticated Paymob inquiry;
    // staff then advance the existing order without a client payment write.
    return const [
      'pending',
      'new_order',
      'another_delegate',
      'accepted',
      'shipped',
      'completed'
    ].contains(data['status'])
        ? PaymentConfirmation.confirmed
        : PaymentConfirmation.waiting;
  }
}

class PaymentConfirmationMonitor extends ChangeNotifier {
  PaymentConfirmationMonitor({
    required this.orderId,
    required this.read,
    this.interval = const Duration(seconds: 3),
  });

  final int orderId;
  final PaymentConfirmationReader read;
  final Duration interval;
  PaymentConfirmation result = PaymentConfirmation.waiting;
  Timer? _timer;
  bool _active = false;
  bool _checking = false;
  bool _disposed = false;
  int _generation = 0;

  void resume() {
    if (_disposed || _active) return;
    _active = true;
    unawaited(checkNow());
  }

  void pause() {
    _active = false;
    _generation++;
    _timer?.cancel();
  }

  Future<void> checkNow() async {
    if (_disposed ||
        !_active ||
        _checking ||
        result != PaymentConfirmation.waiting) {
      return;
    }
    _timer?.cancel();
    _checking = true;
    final generation = _generation;
    try {
      final next = await read(orderId);
      if (_disposed || !_active || generation != _generation) return;
      if (next != PaymentConfirmation.waiting) {
        result = next;
        notifyListeners();
      }
    } catch (_) {
      // A timeout or offline response is not a declined payment.
    } finally {
      _checking = false;
      if (!_disposed && _active && result == PaymentConfirmation.waiting) {
        _timer = Timer(interval, () => unawaited(checkNow()));
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    pause();
    super.dispose();
  }
}
