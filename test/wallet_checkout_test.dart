import 'dart:async';

import 'package:dio/dio.dart';
import 'package:faskhaninja/helpers/networking/api_helper.dart';
import 'package:faskhaninja/view/layout/wallet/controller/wallet_controller.dart';
import 'package:faskhaninja/view/layout/wallet/model/wallet_checkout.dart';
import 'package:faskhaninja/view/layout/wallet/model/wallet_checkout_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _CheckoutService extends WalletCheckoutService {
  final requests = <Completer<ApiResponse>>[];
  final cancellations = <CancelToken>[];
  bool throwOnCreate = false;

  @override
  Future<ApiResponse> create({
    required dynamic amount,
    required String paymentMethod,
    required CancelToken cancelToken,
    required Duration timeout,
    required String sessionToken,
    required bool Function() canSendRequest,
  }) {
    if (throwOnCreate) throw StateError('synthetic request error');
    cancellations.add(cancelToken);
    final completer = Completer<ApiResponse>();
    requests.add(completer);
    return completer.future;
  }
}

ApiResponse _success({dynamic data, String? message}) => ApiResponse(
  state: ResponseState.complete,
  data: {
    'data':
        data ??
        {
          'link': 'https://accept.paymob.com/unifiedcheckout/?test=synthetic',
          'order_id': 42,
        },
    if (message != null) 'message': message,
  },
);

void main() {
  test(
    'duplicate submit creates one checkout and keeps amount and method',
    () async {
      final service = _CheckoutService();
      final controller = WalletController(
        checkoutService: service,
        readCheckoutSession: () => 'synthetic-account',
      );
      addTearDown(controller.dispose);
      controller.chargeAmountEc.text = '50';
      controller.setSelectedPayment('online');
      final pending = controller.chargingWallet(amount: '50');
      expect(controller.isCreatingCheckout, isTrue);
      expect(await controller.chargingWallet(amount: '100'), isNull);
      controller.setSelectedPayment('v_cash');
      expect(controller.selectedPayment, 'online');
      expect(service.requests, hasLength(1));
      service.requests.single.complete(_success());

      final checkout = await pending;
      expect(checkout?.orderId, 42);
      expect(checkout?.url, startsWith('https://accept.paymob.com/'));
      expect(controller.isCreatingCheckout, isFalse);
      expect(controller.checkoutError, isNull);
      expect(controller.chargeAmountEc.text, '50');
      expect(controller.selectedPayment, 'online');
    },
  );

  test(
    'missing email numeric payload is a visible error without throwing',
    () async {
      final service = _CheckoutService();
      final controller = WalletController(
        checkoutService: service,
        readCheckoutSession: () => 'synthetic-account',
      )..setSelectedPayment('online');
      addTearDown(controller.dispose);
      final pending = controller.chargingWallet(amount: '50');
      service.requests.single.complete(
        _success(data: 50, message: 'Please update your email address'),
      );

      expect(await pending, isNull);
      expect(
        controller.checkoutError?.type,
        WalletCheckoutErrorType.invalidResponse,
      );
      expect(
        controller.checkoutError?.message,
        'Please update your email address',
      );
      expect(controller.isCreatingCheckout, isFalse);
    },
  );

  test(
    'untrusted and malformed checkout links never become a payment route',
    () async {
      final service = _CheckoutService();
      final controller = WalletController(
        checkoutService: service,
        readCheckoutSession: () => 'synthetic-account',
      )..setSelectedPayment('online');
      addTearDown(controller.dispose);
      for (final link in [
        'http://accept.paymob.com/checkout',
        'https://paymob.com.example.test/checkout',
        'https://user@accept.paymob.com/checkout',
        'https://accept.paymob.com:444/checkout',
        'javascript:alert(1)',
        '',
        null,
      ]) {
        final pending = controller.chargingWallet(amount: '50');
        service.requests.last.complete(_success(data: {'link': link}));
        expect(await pending, isNull);
        expect(
          controller.checkoutError?.type,
          WalletCheckoutErrorType.invalidResponse,
        );
        expect(controller.isCreatingCheckout, isFalse);
      }
    },
  );

  test(
    'timeouts and thrown errors release busy state without retrying',
    () async {
      final service = _CheckoutService();
      final controller = WalletController(
        checkoutService: service,
        readCheckoutSession: () => 'synthetic-account',
      )..setSelectedPayment('v_cash');
      addTearDown(controller.dispose);
      final pending = controller.chargingWallet(amount: '50');
      service.requests.single.complete(
        ApiResponse(
          state: ResponseState.error,
          data: null,
          failure: ApiFailureKind.timeout,
        ),
      );
      expect(await pending, isNull);
      expect(controller.checkoutError?.type, WalletCheckoutErrorType.timedOut);
      expect(controller.checkoutError?.outcomeUncertain, isTrue);
      expect(controller.isCreatingCheckout, isFalse);
      expect(service.requests, hasLength(1));

      service.throwOnCreate = true;
      expect(await controller.chargingWallet(amount: '50'), isNull);
      expect(
        controller.checkoutError?.type,
        WalletCheckoutErrorType.unavailable,
      );
      expect(controller.isCreatingCheckout, isFalse);
    },
  );

  test(
    'changed account or disposed controller cannot return old checkout',
    () async {
      final service = _CheckoutService();
      String? session = 'account-a';
      final controller = WalletController(
        checkoutService: service,
        readCheckoutSession: () => session,
      )..setSelectedPayment('online');
      final pending = controller.chargingWallet(amount: '50');
      session = 'account-b';
      service.requests.last.complete(_success());
      expect(await pending, isNull);
      expect(controller.isCreatingCheckout, isFalse);

      final beforeReset = controller.chargingWallet(amount: '50');
      controller.initialWallet();
      expect(service.cancellations.last.isCancelled, isTrue);
      service.requests.last.complete(_success());
      expect(await beforeReset, isNull);

      final beforeDisposal = controller.chargingWallet(amount: '50');
      controller.dispose();
      expect(service.cancellations.last.isCancelled, isTrue);
      service.requests.last.complete(_success());
      expect(await beforeDisposal, isNull);
    },
  );

  test(
    'cancelled old request cannot clear a newer request busy state',
    () async {
      final service = _CheckoutService();
      final controller = WalletController(
        checkoutService: service,
        readCheckoutSession: () => 'synthetic-account',
      )..setSelectedPayment('online');
      addTearDown(controller.dispose);
      final oldRequest = controller.chargingWallet(amount: '50');
      controller.cancelCheckoutCreation();
      expect(service.cancellations.first.isCancelled, isTrue);
      final newRequest = controller.chargingWallet(amount: '50');
      service.requests.first.complete(_success());
      expect(await oldRequest, isNull);
      expect(controller.isCreatingCheckout, isTrue);
      service.requests.last.complete(_success());
      expect(await newRequest, isA<WalletCheckout>());
      expect(controller.isCreatingCheckout, isFalse);
    },
  );

  test('backend diagnostics are not exposed as user error messages', () {
    for (final message in [
      '<html>upstream failure</html>',
      'https://accept.paymob.com/?clientSecret=synthetic',
      'Bearer synthetic-token',
      'x' * 241,
    ]) {
      expect(WalletCheckoutError.safeMessage({'message': message}), isNull);
    }
  });
}
