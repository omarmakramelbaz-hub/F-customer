import 'dart:async';

import 'package:faskhaninja/helpers/networking/api_helper.dart';
import 'package:faskhaninja/view/layout/home/controller/home_primary_action_controller.dart';
import 'package:flutter_test/flutter_test.dart';

ApiResponse _success(List<dynamic> orders) => ApiResponse(
      state: ResponseState.complete,
      data: {'data': orders},
    );

ApiResponse _cartSuccess(List<dynamic> items) => ApiResponse(
      state: ResponseState.complete,
      data: {
        'data': {'carts': items},
      },
    );

HomePrimaryActionController _controller({
  required Future<ApiResponse> Function() loadOrders,
  Future<ApiResponse> Function()? loadCart,
}) =>
    HomePrimaryActionController(
      loadOrders: loadOrders,
      loadCart: loadCart ?? () async => _cartSuccess([]),
    );

Map<String, dynamic> _order(
  int id,
  String? status, {
  String? createdAt,
  String? updatedAt,
}) =>
    {
      'id': id,
      'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };

void main() {
  test('active order takes priority over cart, then restores the cart action',
      () async {
    var response = _success([_order(12, 'accepted')]);
    final controller = _controller(
      loadOrders: () async => response,
      loadCart: () async => _cartSuccess([
        {'qty': 1, 'order_id': null}
      ]),
    );
    addTearDown(controller.dispose);

    expect(controller.action, HomePrimaryAction.startOrder);
    controller.updateCart(session: 'customer', hasItems: true);
    expect(controller.action, HomePrimaryAction.viewCart);

    await controller.refresh(session: 'customer');
    expect(controller.action, HomePrimaryAction.trackOrder);
    expect(controller.activeOrders.single.id, 12);

    response = _success([_order(12, 'completed')]);
    await controller.refresh(session: 'customer');
    expect(controller.action, HomePrimaryAction.viewCart);

    controller.updateCart(session: 'customer', hasItems: false);
    expect(controller.action, HomePrimaryAction.startOrder);
  });

  test('newer completed order never hides an older active order', () async {
    final controller = _controller(
      loadOrders: () async => _success([
        _order(20, 'completed', createdAt: '2026-11-12T14:00:00Z'),
        _order(10, 'shipped', createdAt: '2026-11-12T12:00:00Z'),
      ]),
    );
    addTearDown(controller.dispose);

    await controller.refresh(session: 'customer');

    expect(controller.action, HomePrimaryAction.trackOrder);
    expect(controller.activeOrders.map((order) => order.id), [10]);
  });

  test('terminal, unknown and invalid orders cannot become tracking targets',
      () async {
    final statuses = [
      'completed',
      'delivered',
      'cancelled',
      'canceled',
      'declined',
      'rejected',
      'ended',
      'failed',
      'payment_failed',
      'unrecognized_status',
      '',
      null,
    ];
    final controller = _controller(
      loadOrders: () async => _success([
        for (var i = 0; i < statuses.length; i++)
          _order(i + 1,
              statuses[i] == null ? null : ' ${statuses[i]!.toUpperCase()} '),
        _order(0, 'accepted'),
        _order(-1, 'shipped'),
      ]),
    );
    addTearDown(controller.dispose);

    await controller.refresh(session: 'customer');

    expect(controller.activeOrders, isEmpty);
    expect(controller.action, HomePrimaryAction.startOrder);
  });

  test('known in-flight aliases normalize spaces, hyphens and case', () async {
    const statuses = [
      'pending',
      'accepted',
      'shipped',
      'NEW ORDER',
      'another_delegate',
      'preparing',
      'in-preparation',
      'picked up',
      'ON-THE-WAY',
      ' out_for_delivery ',
    ];
    final controller = _controller(
      loadOrders: () async => _success([
        for (var i = 0; i < statuses.length; i++) _order(i + 1, statuses[i]),
      ]),
    );
    addTearDown(controller.dispose);

    await controller.refresh(session: 'customer');

    expect(controller.activeOrders, hasLength(statuses.length));
    expect(controller.action, HomePrimaryAction.trackOrder);
  });

  test('multiple active orders sort by creation date then ID, not last update',
      () async {
    final controller = _controller(
      loadOrders: () async => _success([
        _order(7, 'accepted',
            createdAt: '2026-11-12T10:00:00Z',
            updatedAt: '2026-11-13T12:00:00Z'),
        _order(8, 'pending', createdAt: '2026-11-12T11:00:00Z'),
        _order(9, 'shipped', createdAt: '2026-11-12T11:00:00Z'),
        _order(50, 'preparing', createdAt: 'invalid date'),
      ]),
    );
    addTearDown(controller.dispose);

    await controller.refresh(session: 'customer');

    expect(controller.activeOrders.map((order) => order.id), [9, 8, 7, 50]);
    expect(() => controller.activeOrders.clear(), throwsUnsupportedError);
  });

  test('guests never request orders or expose a confirmed cart', () async {
    var calls = 0;
    final controller = _controller(
      loadOrders: () async {
        calls++;
        return _success([_order(1, 'accepted')]);
      },
    );
    addTearDown(controller.dispose);

    controller.updateCart(session: null, hasItems: true);
    await controller.refresh(session: null);

    expect(calls, 0);
    expect(controller.activeOrders, isEmpty);
    expect(controller.action, HomePrimaryAction.startOrder);
    expect(controller.isInitialLoading, isFalse);
  });

  test('same-session concurrent refreshes share one pending request', () async {
    final response = Completer<ApiResponse>();
    var calls = 0;
    final controller = _controller(
      loadOrders: () {
        calls++;
        return response.future;
      },
    );
    addTearDown(controller.dispose);

    final first = controller.refresh(session: 'customer');
    final second = controller.refresh(session: 'customer');
    expect(identical(first, second), isTrue);
    expect(calls, 1);
    expect(controller.isInitialLoading, isTrue);

    response.complete(_success([_order(1, 'accepted')]));
    await first;

    expect(controller.isInitialLoading, isFalse);
    expect(controller.action, HomePrimaryAction.trackOrder);
  });

  test('late previous-user response cannot replace a new session', () async {
    final oldResponse = Completer<ApiResponse>();
    final newResponse = Completer<ApiResponse>();
    var calls = 0;
    final controller = _controller(
      loadOrders: () => calls++ == 0 ? oldResponse.future : newResponse.future,
    );
    addTearDown(controller.dispose);

    final oldRequest = controller.refresh(session: 'old-customer');
    controller.updateCart(session: 'new-customer', hasItems: true);
    expect(controller.activeOrders, isEmpty);
    expect(controller.action, HomePrimaryAction.viewCart);
    final newRequest = controller.refresh(session: 'new-customer');

    newResponse.complete(_success([_order(2, 'shipped')]));
    await newRequest;
    oldResponse.complete(_success([_order(1, 'accepted')]));
    await oldRequest;

    expect(calls, 2);
    expect(controller.activeOrders.single.id, 2);
    expect(controller.action, HomePrimaryAction.trackOrder);
    expect(controller.isInitialLoading, isFalse);
  });

  test(
      'sign-out immediately clears old state and rejects an in-flight response',
      () async {
    final response = Completer<ApiResponse>();
    var calls = 0;
    final controller = _controller(
      loadOrders: () {
        calls++;
        return response.future;
      },
    );
    addTearDown(controller.dispose);
    controller.updateCart(session: 'customer', hasItems: true);
    final request = controller.refresh(session: 'customer');

    await controller.refresh(session: null);
    expect(controller.action, HomePrimaryAction.startOrder);
    expect(controller.isInitialLoading, isFalse);
    response.complete(_success([_order(1, 'shipped')]));
    await request;

    expect(calls, 1);
    expect(controller.activeOrders, isEmpty);
    expect(controller.action, HomePrimaryAction.startOrder);
  });

  test(
      'confirmed state does not flicker through refresh, API or parsing errors',
      () async {
    final responses = <Completer<ApiResponse>>[];
    final controller = _controller(
      loadOrders: () {
        final response = Completer<ApiResponse>();
        responses.add(response);
        return response.future;
      },
      loadCart: () async => _cartSuccess([
        {'qty': 1, 'order_id': null}
      ]),
    );
    addTearDown(controller.dispose);
    controller.updateCart(session: 'customer', hasItems: true);
    final initial = controller.refresh(session: 'customer');
    responses.last.complete(_success([_order(1, 'accepted')]));
    await initial;
    final actions = <HomePrimaryAction>[];
    controller.addListener(() => actions.add(controller.action));

    final apiError = controller.refresh(session: 'customer');
    expect(controller.isInitialLoading, isFalse);
    expect(controller.activeOrders.single.id, 1);
    responses.last
        .complete(ApiResponse(state: ResponseState.error, data: null));
    await apiError;

    final transportError = controller.refresh(session: 'customer');
    responses.last.completeError(StateError('temporary request failure'));
    await transportError;

    final malformedResponse = controller.refresh(session: 'customer');
    responses.last.complete(_success([_order(2, 'pending'), 'invalid order']));
    await malformedResponse;

    expect(controller.activeOrders.single.id, 1);
    expect(actions, isNotEmpty);
    expect(actions, everyElement(HomePrimaryAction.trackOrder));

    final finished = controller.refresh(session: 'customer');
    responses.last.complete(_success([]));
    await finished;
    expect(controller.action, HomePrimaryAction.viewCart);
  });

  test('disposed controller ignores late results and future public calls',
      () async {
    final response = Completer<ApiResponse>();
    var calls = 0;
    var notifications = 0;
    final controller = _controller(
      loadOrders: () {
        calls++;
        return response.future;
      },
    );
    controller.addListener(() => notifications++);
    final request = controller.refresh(session: 'customer');
    final beforeDispose = notifications;

    controller.dispose();
    response.complete(_success([_order(1, 'shipped')]));
    await request;
    await controller.refresh(session: 'another-customer');
    controller.updateCart(session: 'another-customer', hasItems: true);

    expect(calls, 1);
    expect(notifications, beforeDispose);
    expect(controller.activeOrders, isEmpty);
  });

  test('server cart includes only unsubmitted items with positive quantity',
      () async {
    var cart = _cartSuccess([
      {'qty': 2, 'order_id': 19},
      {'qty': 0, 'order_id': null},
      {'qty': -1, 'order_id': 0},
    ]);
    final controller = _controller(
      loadOrders: () async => _success([]),
      loadCart: () async => cart,
    );
    addTearDown(controller.dispose);

    await controller.refresh(session: 'customer');
    expect(controller.action, HomePrimaryAction.startOrder);

    cart = _cartSuccess([
      {'qty': '2', 'order_id': '0'}
    ]);
    await controller.refresh(session: 'customer');
    expect(controller.action, HomePrimaryAction.viewCart);

    cart = _cartSuccess([
      {'qty': 1, 'order_id': null}
    ]);
    await controller.refresh(session: 'customer');
    expect(controller.action, HomePrimaryAction.viewCart);

    cart = ApiResponse(state: ResponseState.complete, data: {'data': null});
    await controller.refresh(session: 'customer');
    expect(controller.action, HomePrimaryAction.startOrder);
  });

  test('server order and cart responses determine the complete action priority',
      () async {
    var orders = _success([_order(10, 'pending')]);
    var cart = _cartSuccess([
      {'qty': 3, 'order_id': null}
    ]);
    final controller = _controller(
      loadOrders: () async => orders,
      loadCart: () async => cart,
    );
    addTearDown(controller.dispose);

    await controller.refresh(session: 'customer');
    expect(controller.action, HomePrimaryAction.trackOrder);

    orders = _success([_order(10, 'delivered')]);
    await controller.refresh(session: 'customer');
    expect(controller.action, HomePrimaryAction.viewCart);

    cart = _cartSuccess([]);
    await controller.refresh(session: 'customer');
    expect(controller.action, HomePrimaryAction.startOrder);
  });

  test('initial loading waits for both independent endpoint responses',
      () async {
    final orders = Completer<ApiResponse>();
    final cart = Completer<ApiResponse>();
    var cartCalls = 0;
    final controller = _controller(
      loadOrders: () => orders.future,
      loadCart: () {
        cartCalls++;
        return cart.future;
      },
    );
    addTearDown(controller.dispose);

    final request = controller.refresh(session: 'customer');
    orders.complete(_success([]));
    await Future<void>.delayed(Duration.zero);
    expect(cartCalls, 1);
    expect(controller.isInitialLoading, isTrue);

    cart.complete(_cartSuccess([
      {'qty': 1, 'order_id': null}
    ]));
    await request;
    expect(controller.isInitialLoading, isFalse);
    expect(controller.action, HomePrimaryAction.viewCart);
  });

  test('late cart from a prior session cannot expose another user cart',
      () async {
    final oldCart = Completer<ApiResponse>();
    final newCart = Completer<ApiResponse>();
    var cartCalls = 0;
    final controller = _controller(
      loadOrders: () async => _success([]),
      loadCart: () => cartCalls++ == 0 ? oldCart.future : newCart.future,
    );
    addTearDown(controller.dispose);

    final oldRequest = controller.refresh(session: 'old-customer');
    final newRequest = controller.refresh(session: 'new-customer');
    newCart.complete(_cartSuccess([]));
    await newRequest;
    oldCart.complete(_cartSuccess([
      {'qty': 5, 'order_id': null}
    ]));
    await oldRequest;

    expect(cartCalls, 2);
    expect(controller.action, HomePrimaryAction.startOrder);
    expect(controller.activeOrders, isEmpty);
    expect(controller.isInitialLoading, isFalse);
  });

  test('one failed endpoint does not discard the other valid response',
      () async {
    var orders = _success([_order(1, 'pending')]);
    var cart = _cartSuccess([
      {'qty': 2, 'order_id': null}
    ]);
    var cartThrows = false;
    final controller = _controller(
      loadOrders: () async => orders,
      loadCart: () async {
        if (cartThrows) throw StateError('cart request failed');
        return cart;
      },
    );
    addTearDown(controller.dispose);

    await controller.refresh(session: 'customer');
    expect(controller.action, HomePrimaryAction.trackOrder);

    orders = _success([]);
    cartThrows = true;
    await controller.refresh(session: 'customer');
    expect(controller.action, HomePrimaryAction.viewCart);
    expect(controller.isInitialLoading, isFalse);

    cartThrows = false;
    cart = _cartSuccess([]);
    orders = ApiResponse(state: ResponseState.error, data: null);
    await controller.refresh(session: 'customer');
    expect(controller.action, HomePrimaryAction.startOrder);

    orders = _success([_order(2, 'shipped')]);
    cart =
        ApiResponse(state: ResponseState.complete, data: {'data': 'invalid'});
    await controller.refresh(session: 'customer');
    expect(controller.activeOrders.single.id, 2);
    expect(controller.action, HomePrimaryAction.trackOrder);
  });

  test('malformed cart responses retain confirmed state without flicker',
      () async {
    var cart = _cartSuccess([
      {'qty': 2, 'order_id': null}
    ]);
    final controller = _controller(
      loadOrders: () async => _success([]),
      loadCart: () async => cart,
    );
    addTearDown(controller.dispose);
    await controller.refresh(session: 'customer');
    final actions = <HomePrimaryAction>[];
    controller.addListener(() => actions.add(controller.action));

    final malformed = <dynamic>[
      null,
      {},
      {'data': {}},
      {
        'data': {'carts': 'invalid'}
      },
      {
        'data': {
          'carts': [false]
        }
      },
      {
        'data': {
          'carts': [
            {'qty': 'invalid', 'order_id': null}
          ]
        }
      },
      {
        'data': {
          'carts': [
            {'qty': 1, 'order_id': 'invalid'}
          ]
        }
      },
    ];
    for (final body in malformed) {
      cart = ApiResponse(state: ResponseState.complete, data: body);
      await controller.refresh(session: 'customer');
    }

    expect(controller.action, HomePrimaryAction.viewCart);
    expect(actions, everyElement(HomePrimaryAction.viewCart));
  });

  test('guest and disposed controllers never accept a late cart response',
      () async {
    final cart = Completer<ApiResponse>();
    var cartCalls = 0;
    final controller = _controller(
      loadOrders: () async => _success([]),
      loadCart: () {
        cartCalls++;
        return cart.future;
      },
    );
    final request = controller.refresh(session: 'customer');
    await controller.refresh(session: null);
    controller.dispose();
    cart.complete(_cartSuccess([
      {'qty': 2, 'order_id': null}
    ]));
    await request;
    await controller.refresh(session: null);

    expect(cartCalls, 1);
    expect(controller.action, HomePrimaryAction.startOrder);
    expect(controller.activeOrders, isEmpty);
  });
}
