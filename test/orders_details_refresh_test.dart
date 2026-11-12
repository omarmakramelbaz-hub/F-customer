import 'dart:async';

import 'package:faskhaninja/helpers/networking/api_helper.dart';
import 'package:faskhaninja/view/layout/orders/controller/orders_controller.dart';
import 'package:flutter_test/flutter_test.dart';

ApiResponse _details(int id, String status, {List<dynamic>? items}) =>
    ApiResponse(
      state: ResponseState.complete,
      data: {
        'data': {
          'id': id,
          'status': status,
          if (items != null) 'items': items,
        },
      },
    );

Map<String, dynamic> _item(int productId,
        {String status = 'show', int qty = 2}) =>
    {
      'resturant_product': {'id': productId, 'status': status},
      'product_feature': 5,
      'product_clean': 'extra_clean',
      'qty': qty,
    };

void main() {
  test('successful details and reorder fields become visible together',
      () async {
    final controller = OrdersController(
      detailsLoader: (id) async => _details(id, 'accepted', items: [
        _item(11),
        _item(12, status: 'hide'),
        {'qty': 1},
      ]),
    );
    addTearDown(controller.dispose);
    final states = <ResponseState>[];
    controller.addListener(() {
      states.add(controller.detailsOrdersApiResponse.state);
      if (controller.detailsOrdersApiResponse.state == ResponseState.complete) {
        expect(controller.detailsOrders?.id, 1);
        expect(controller.productId, [11]);
        expect(controller.productFeatureId, [5]);
        expect(controller.productClean, ['extra_clean']);
        expect(controller.productQuantity, [2]);
      }
    });

    await controller.getDetailsOrders(id: 1);

    expect(states, [ResponseState.loading, ResponseState.complete]);
    expect(controller.detailsOrders?.status, 'accepted');
  });

  test('same-order refresh retains confirmed details during loading and error',
      () async {
    var response = Future<ApiResponse>.value(
      _details(1, 'accepted', items: [_item(11)]),
    );
    final controller = OrdersController(detailsLoader: (_) => response);
    addTearDown(controller.dispose);
    await controller.getDetailsOrders(id: 1);
    final knownOrder = controller.detailsOrders;
    final refresh = Completer<ApiResponse>();
    response = refresh.future;

    final request = controller.getDetailsOrders(id: 1);
    expect(controller.detailsOrdersApiResponse.state, ResponseState.loading);
    expect(identical(controller.detailsOrders, knownOrder), isTrue);
    expect(controller.productId, [11]);
    refresh.complete(ApiResponse(state: ResponseState.offline, data: null));
    await request;

    expect(controller.detailsOrdersApiResponse.state, ResponseState.offline);
    expect(identical(controller.detailsOrders, knownOrder), isTrue);
    expect(controller.productId, [11]);
  });

  test('parsing failure preserves the whole confirmed snapshot and marks error',
      () async {
    var response = _details(1, 'accepted', items: [_item(11)]);
    final controller = OrdersController(detailsLoader: (_) async => response);
    addTearDown(controller.dispose);
    await controller.getDetailsOrders(id: 1);
    final knownOrder = controller.detailsOrders;

    response = ApiResponse(
      state: ResponseState.complete,
      data: {
        'data': {
          'id': 1,
          'status': 'shipped',
          'tax': 'malformed amount',
          'items': [_item(99, qty: 5)],
        },
      },
    );
    await controller.getDetailsOrders(id: 1);

    expect(controller.detailsOrdersApiResponse.state, ResponseState.error);
    expect(identical(controller.detailsOrders, knownOrder), isTrue);
    expect(controller.detailsOrders?.status, 'accepted');
    expect(controller.productId, [11]);
    expect(controller.productQuantity, [2]);
  });

  test(
      'overlapping requests for different orders cannot replace the latest target',
      () async {
    final first = Completer<ApiResponse>();
    final second = Completer<ApiResponse>();
    final controller = OrdersController(
      detailsLoader: (id) => id == 1 ? first.future : second.future,
    );
    addTearDown(controller.dispose);

    final firstRequest = controller.getDetailsOrders(id: 1);
    final secondRequest = controller.getDetailsOrders(id: 2);
    second.complete(_details(2, 'shipped', items: [_item(22)]));
    await secondRequest;
    first.complete(_details(1, 'pending', items: [_item(11)]));
    await firstRequest;

    expect(controller.detailsOrders?.id, 2);
    expect(controller.detailsOrders?.status, 'shipped');
    expect(controller.productId, [22]);
    expect(controller.detailsOrdersApiResponse.state, ResponseState.complete);
  });

  test('late same-order error cannot undo a newer successful refresh',
      () async {
    final oldResponse = Completer<ApiResponse>();
    final newResponse = Completer<ApiResponse>();
    var calls = 0;
    final controller = OrdersController(
      detailsLoader: (_) =>
          calls++ == 0 ? oldResponse.future : newResponse.future,
    );
    addTearDown(controller.dispose);

    final oldRequest = controller.getDetailsOrders(id: 1);
    final newRequest = controller.getDetailsOrders(id: 1);
    newResponse.complete(_details(1, 'shipped'));
    await newRequest;
    oldResponse.completeError(StateError('stale transport failure'));
    await oldRequest;

    expect(controller.detailsOrders?.status, 'shipped');
    expect(controller.detailsOrdersApiResponse.state, ResponseState.complete);
  });

  test('changing target never displays the previous order after a failed load',
      () async {
    final controller = OrdersController(
      detailsLoader: (id) async => id == 1
          ? _details(1, 'accepted', items: [_item(11)])
          : ApiResponse(state: ResponseState.error, data: null),
    );
    addTearDown(controller.dispose);
    await controller.getDetailsOrders(id: 1);

    final request = controller.getDetailsOrders(id: 2);
    expect(controller.detailsOrders, isNull);
    expect(controller.productId, isEmpty);
    await request;

    expect(controller.detailsOrders, isNull);
    expect(controller.productQuantity, isEmpty);
    expect(controller.detailsOrdersApiResponse.state, ResponseState.error);
  });

  test('explicit reset invalidates a pending request', () async {
    final response = Completer<ApiResponse>();
    final controller = OrdersController(detailsLoader: (_) => response.future);
    addTearDown(controller.dispose);
    final request = controller.getDetailsOrders(id: 1);

    controller.initialDetailsOrders();
    response.complete(_details(1, 'shipped', items: [_item(11)]));
    await request;

    expect(controller.detailsOrders, isNull);
    expect(controller.productId, isEmpty);
    expect(controller.detailsOrdersApiResponse.state, ResponseState.sleep);
  });

  test('late responses and public detail calls are ignored after dispose',
      () async {
    final response = Completer<ApiResponse>();
    var calls = 0;
    var notifications = 0;
    final controller = OrdersController(
      detailsLoader: (_) {
        calls++;
        return response.future;
      },
    );
    controller.addListener(() => notifications++);
    final request = controller.getDetailsOrders(id: 1);
    final beforeDispose = notifications;

    controller.dispose();
    response.complete(_details(1, 'shipped'));
    await request;
    await controller.getDetailsOrders(id: 2);
    controller.initialDetailsOrders();

    expect(calls, 1);
    expect(notifications, beforeDispose);
    expect(controller.detailsOrders, isNull);
  });

  test('invalid payloads and request failures settle loading and allow retry',
      () async {
    var response =
        ApiResponse(state: ResponseState.complete, data: {'data': null});
    var shouldThrow = false;
    final controller = OrdersController(
      detailsLoader: (_) async {
        if (shouldThrow) throw StateError('transport failure');
        return response;
      },
    );
    addTearDown(controller.dispose);

    await controller.getDetailsOrders(id: 1);
    expect(controller.detailsOrdersApiResponse.state, ResponseState.error);
    expect(controller.detailsOrders, isNull);

    shouldThrow = true;
    await controller.getDetailsOrders(id: 1);
    expect(controller.detailsOrdersApiResponse.state, ResponseState.error);

    shouldThrow = false;
    response = _details(1, 'accepted');
    await controller.getDetailsOrders(id: 1);
    expect(controller.detailsOrdersApiResponse.state, ResponseState.complete);
    expect(controller.detailsOrders?.id, 1);

    response = _details(2, 'shipped');
    await controller.getDetailsOrders(id: 1);
    expect(controller.detailsOrdersApiResponse.state, ResponseState.error);
    expect(controller.detailsOrders?.id, 1);
    expect(controller.detailsOrders?.status, 'accepted');
  });

  test('an empty item refresh clears prepared reorder fields', () async {
    var response = _details(1, 'accepted', items: [_item(11)]);
    final controller = OrdersController(detailsLoader: (_) async => response);
    addTearDown(controller.dispose);
    await controller.getDetailsOrders(id: 1);
    expect(controller.productId, [11]);

    response = _details(1, 'completed');
    await controller.getDetailsOrders(id: 1);

    expect(controller.productId, isEmpty);
    expect(controller.productFeatureId, isEmpty);
    expect(controller.productClean, isEmpty);
    expect(controller.productQuantity, isEmpty);
    expect(controller.detailsOrdersApiResponse.state, ResponseState.complete);
  });

  test('invalid request IDs never call the API or remain loading', () async {
    var calls = 0;
    final controller = OrdersController(
      detailsLoader: (id) async {
        calls++;
        return _details(id, 'pending');
      },
    );
    addTearDown(controller.dispose);

    await controller.getDetailsOrders(id: 0);

    expect(calls, 0);
    expect(controller.detailsOrders, isNull);
    expect(controller.detailsOrdersApiResponse.state, ResponseState.error);
  });
}
