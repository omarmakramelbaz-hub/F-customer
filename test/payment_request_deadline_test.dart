import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:faskhaninja/helpers/networking/api_helper.dart';
import 'package:faskhaninja/helpers/translation/all_translation.dart';
import 'package:faskhaninja/view/layout/wallet/controller/wallet_controller.dart';
import 'package:faskhaninja/view/layout/wallet/model/wallet_checkout_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _PendingAdapter implements HttpClientAdapter {
  int requests = 0;
  final started = Completer<void>();
  final cancelled = Completer<void>();
  final response = Completer<ResponseBody>();
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests++;
    lastRequest = options;
    if (!started.isCompleted) started.complete();
    cancelFuture?.then((_) {
      if (!cancelled.isCompleted) cancelled.complete();
    });
    return response.future;
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('checkout-deadline-');
    Hive.init(directory.path);
    await Hive.openBox<dynamic>('app');
    await GlobalTranslations.setNewLanguage('en', false);
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('deadline includes preflight and cannot send a late POST', () async {
    final preflight = Completer<bool>();
    final adapter = _PendingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = ApiHelper.forTesting(
      dio: dio,
      hasConnection: () => preflight.future,
    );
    final cancellation = CancelToken();
    final response = await api.post(
      'https://example.test/checkout',
      requestTimeout: const Duration(milliseconds: 20),
      cancelToken: cancellation,
    );
    expect(response.failure, ApiFailureKind.timeout);
    expect(cancellation.isCancelled, isTrue);
    expect(adapter.requests, 0);
    preflight.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(adapter.requests, 0);
    dio.close(force: true);
  });

  test(
    'deadline actually cancels an in-flight Dio request without retry',
    () async {
      final adapter = _PendingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final api = ApiHelper.forTesting(
        dio: dio,
        hasConnection: () async => true,
      );
      final response = api.post(
        'https://example.test/checkout',
        requestTimeout: const Duration(milliseconds: 50),
      );
      await adapter.started.future;
      expect((await response).failure, ApiFailureKind.timeout);
      await adapter.cancelled.future.timeout(const Duration(seconds: 1));
      expect(adapter.requests, 1);
      adapter.response.complete(ResponseBody.fromString('{}', 200));
      dio.close(force: true);
    },
  );

  test(
    'closing during preflight returns promptly and never sends POST',
    () async {
      final preflight = Completer<bool>();
      final adapter = _PendingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final api = ApiHelper.forTesting(
        dio: dio,
        hasConnection: () => preflight.future,
      );
      final cancellation = CancelToken();
      final pending = api.post(
        'https://example.test/checkout',
        requestTimeout: const Duration(seconds: 35),
        cancelToken: cancellation,
      );
      cancellation.cancel('synthetic sheet close');
      expect((await pending).failure, ApiFailureKind.cancelled);
      preflight.complete(true);
      await Future<void>.delayed(Duration.zero);
      expect(adapter.requests, 0);
      dio.close(force: true);
    },
  );

  test('ordinary POST keeps status handling and onFinish behavior', () async {
    final adapter = _PendingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = ApiHelper.forTesting(dio: dio, hasConnection: () async => true);
    var finished = 0;
    final pending = api.post(
      'https://example.test/ordinary',
      onFinish: () => finished++,
    );
    await adapter.started.future;
    adapter.response.complete(
      ResponseBody.fromString(
        '{"message":"rejected"}',
        422,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    final response = await pending;
    await Future<void>.delayed(Duration.zero);
    expect(response.state, ResponseState.error);
    expect(response.statusCode, 422);
    expect(response.data['message'], 'rejected');
    expect(finished, 1);
    expect(adapter.requests, 1);
    dio.close(force: true);
  });

  test(
    'account change during preflight cannot create another account checkout',
    () async {
      final preflight = Completer<bool>();
      final adapter = _PendingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final api = ApiHelper.forTesting(
        dio: dio,
        hasConnection: () => preflight.future,
      );
      var session = 'synthetic-account-a';
      final wallet = WalletController(
        checkoutService: WalletCheckoutService(api: api),
        readCheckoutSession: () => session,
      )..setSelectedPayment('online');
      addTearDown(wallet.dispose);
      final pending = wallet.chargingWallet(amount: '50');
      session = 'synthetic-account-b';
      preflight.complete(true);
      expect(await pending, isNull);
      expect(adapter.requests, 0);
      expect(wallet.isCreatingCheckout, isFalse);
      dio.close(force: true);
    },
  );

  test('wallet Authorization remains bound to the captured account token', () async {
    final adapter = _PendingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = ApiHelper.forTesting(dio: dio, hasConnection: () async => true);
    final wallet = WalletController(
      checkoutService: WalletCheckoutService(api: api),
      readCheckoutSession: () => 'synthetic-captured-account',
    )..setSelectedPayment('v_cash');
    addTearDown(wallet.dispose);
    final pending = wallet.chargingWallet(amount: '50');
    await adapter.started.future;
    expect(
      adapter.lastRequest?.headers['Authorization'],
      'Bearer synthetic-captured-account',
    );
    adapter.response.complete(
      ResponseBody.fromString(
        '{"data":{"link":"https://accept.paymob.com/checkout","order_id":42}}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    expect((await pending)?.orderId, 42);
    expect(adapter.requests, 1);
    dio.close(force: true);
  });

  test(
    'stale account 401 cannot trigger the global unauthorized redirect',
    () async {
      final adapter = _PendingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final api = ApiHelper.forTesting(
        dio: dio,
        hasConnection: () async => true,
      );
      var current = true;
      final pending = api.post(
        'https://example.test/checkout',
        requestTimeout: const Duration(seconds: 1),
        canSendRequest: () => current,
      );
      await adapter.started.future;
      current = false;
      adapter.response.complete(
        ResponseBody.fromString(
          '{"message":"unauthorized"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
      final response = await pending;
      expect(response.failure, ApiFailureKind.cancelled);
      expect(response.state, isNot(ResponseState.unauthorized));
      await Future<void>.delayed(Duration.zero);
      expect(adapter.requests, 1);
      dio.close(force: true);
    },
  );

  test('account switch after 401 response suppresses delayed login navigation', () async {
    final adapter = _PendingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = ApiHelper.forTesting(dio: dio, hasConnection: () async => true);
    var current = true;
    final pending = api.post(
      'https://example.test/checkout',
      requestTimeout: const Duration(seconds: 1),
      canSendRequest: () => current,
    );
    await adapter.started.future;
    adapter.response.complete(
      ResponseBody.fromString(
        '{"message":"unauthorized"}',
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    expect((await pending).state, ResponseState.unauthorized);
    current = false;
    // There is deliberately no navigator in this test. A delayed redirect from
    // the obsolete response would throw instead of silently affecting a user.
    await Future<void>.delayed(Duration.zero);
    expect(adapter.requests, 1);
    dio.close(force: true);
  });
}
