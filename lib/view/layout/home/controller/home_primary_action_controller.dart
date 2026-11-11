import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../orders/model/orders_model.dart';

enum HomePrimaryAction { startOrder, viewCart, trackOrder }

/// Combines submitted orders and the cart without carrying state across users.
class HomePrimaryActionController extends ChangeNotifier {
  HomePrimaryActionController({
    Future<ApiResponse> Function()? loadOrders,
    Future<ApiResponse> Function()? loadCart,
  })  : _loadOrders = loadOrders ?? _getOrders,
        _loadCart = loadCart ?? _getCart;

  static Future<ApiResponse> _getOrders() =>
      ApiHelper.instance.get(Urls.orders);

  static Future<ApiResponse> _getCart() =>
      ApiHelper.instance.get(Urls.userCart);

  static const _inFlightStatuses = {
    'pending',
    'accepted',
    'shipped',
    'new_order',
    'another_delegate',
    'preparing',
    'in_preparation',
    'picked_up',
    'on_the_way',
    'out_for_delivery',
  };

  static const _terminalStatuses = {
    'completed',
    'delivered',
    'cancelled',
    'canceled',
    'declined',
    'rejected',
    'ended',
    'failed',
    'payment_failed',
  };

  final Future<ApiResponse> Function() _loadOrders;
  final Future<ApiResponse> Function() _loadCart;
  Object? _session;
  int _generation = 0;
  bool _disposed = false;
  bool _hasCompletedRefresh = false;
  bool _hasCartItems = false;
  bool _isInitialLoading = false;
  List<OrdersModel> _activeOrders = const [];
  Future<void>? _refreshFuture;

  HomePrimaryAction get action => _activeOrders.isNotEmpty
      ? HomePrimaryAction.trackOrder
      : _hasCartItems
          ? HomePrimaryAction.viewCart
          : HomePrimaryAction.startOrder;

  List<OrdersModel> get activeOrders => _activeOrders;

  bool get isInitialLoading => _isInitialLoading;

  bool _setSession(Object? session) {
    if (_session == session) return false;
    _session = session;
    _generation++;
    _hasCompletedRefresh = false;
    _hasCartItems = false;
    _isInitialLoading = false;
    _activeOrders = const [];
    _refreshFuture = null;
    return true;
  }

  /// The caller supplies cart values only after a completed cart response.
  void updateCart({required Object? session, required bool hasItems}) {
    if (_disposed) return;
    final sessionChanged = _setSession(session);
    final confirmedHasItems = session != null && hasItems;
    final cartChanged = _hasCartItems != confirmedHasItems;
    _hasCartItems = confirmedHasItems;
    if (sessionChanged || cartChanged) notifyListeners();
  }

  /// Coalesces same-session requests and ignores stale responses after sign-out.
  Future<void> refresh({required Object? session}) {
    if (_disposed) return Future<void>.value();
    final sessionChanged = _setSession(session);
    if (session == null) {
      if (sessionChanged) notifyListeners();
      return Future<void>.value();
    }
    final current = _refreshFuture;
    if (current != null) return current;

    final completion = Completer<void>();
    final generation = _generation;
    _refreshFuture = completion.future;
    _isInitialLoading = !_hasCompletedRefresh;
    notifyListeners();
    unawaited(_refreshData(generation, completion));
    return completion.future;
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _generation && _session != null;

  Future<void> _refreshData(
    int generation,
    Completer<void> completion,
  ) async {
    try {
      if (!_isCurrent(generation)) return;
      final responses = await Future.wait([
        _loadResponse(_loadOrders),
        _loadResponse(_loadCart),
      ]);
      if (!_isCurrent(generation)) return;
      final orders = _parseActiveOrders(responses[0]);
      final hasCartItems = _parseCartItems(responses[1]);
      // Each response is independent: one failed endpoint must not prevent
      // a valid update from the other or erase its last confirmed state.
      if (orders != null) _activeOrders = orders;
      if (hasCartItems != null) _hasCartItems = hasCartItems;
    } finally {
      if (_isCurrent(generation)) {
        _hasCompletedRefresh = true;
        _isInitialLoading = false;
        _refreshFuture = null;
        notifyListeners();
      }
      completion.complete();
    }
  }

  static Future<ApiResponse?> _loadResponse(
    Future<ApiResponse> Function() load,
  ) async {
    try {
      return await load();
    } catch (_) {
      return null;
    }
  }

  static List<OrdersModel>? _parseActiveOrders(ApiResponse? response) {
    if (response?.state != ResponseState.complete) return null;
    final body = response!.data;
    final rows = body is Map ? body['data'] : null;
    if (rows is! Iterable) return null;
    try {
      // The home action needs only these scalars. Legacy order resources may
      // include unrelated monetary or nested fields with different types.
      final orders = rows
          .map((row) {
            if (row is! Map) throw const FormatException('Invalid order');
            return OrdersModel(
              id: _integer(row['id']),
              status: _label(row['status']),
              orderNo: _label(row['order_no']),
              resturantName: _label(row['resturant_name']),
              createdAt: _label(row['created_at']),
            );
          })
          .where(_isActiveOrder)
          .toList()
        ..sort(_compareOrders);
      return List<OrdersModel>.unmodifiable(orders);
    } catch (_) {
      return null;
    }
  }

  static bool? _parseCartItems(ApiResponse? response) {
    if (response?.state != ResponseState.complete) return null;
    final body = response!.data;
    if (body is! Map || !body.containsKey('data')) return null;
    final data = body['data'];
    if (data == null) return false;
    if (data is! Map || !data.containsKey('carts')) return null;
    final rows = data['carts'];
    if (rows == null) return false;
    if (rows is! Iterable) return null;

    var hasItems = false;
    for (final row in rows) {
      if (row is! Map) return null;
      final quantity = _number(row['qty']);
      if (quantity == null) return null;
      // /user/cart/index already scopes records to is_order=false. An older
      // order_id link is not evidence that an item has been submitted.
      if (quantity > 0) hasItems = true;
    }
    return hasItems;
  }

  static num? _number(Object? value) {
    final result = value is num ? value : num.tryParse(value?.toString() ?? '');
    return result != null && result.isFinite ? result : null;
  }

  static int? _integer(Object? value) {
    if (value is int) return value;
    if (value is num) {
      return value.isFinite && value == value.truncateToDouble()
          ? value.toInt()
          : null;
    }
    return value is String ? int.tryParse(value.trim()) : null;
  }

  static String? _label(Object? value) =>
      value is String || value is num || value is bool
          ? value.toString().trim()
          : null;

  static bool _isActiveOrder(OrdersModel order) {
    if ((order.id ?? 0) <= 0) return false;
    final status = (order.status ?? '').trim().toLowerCase().replaceAll(
          RegExp(r'[\s-]+'),
          '_',
        );
    return !_terminalStatuses.contains(status) &&
        _inFlightStatuses.contains(status);
  }

  static int _compareOrders(OrdersModel a, OrdersModel b) {
    final aCreated = DateTime.tryParse(a.createdAt ?? '');
    final bCreated = DateTime.tryParse(b.createdAt ?? '');
    if (aCreated != null && bCreated != null) {
      final byDate = bCreated.compareTo(aCreated);
      if (byDate != 0) return byDate;
    } else if (aCreated != null || bCreated != null) {
      return aCreated != null ? -1 : 1;
    }
    return (b.id ?? 0).compareTo(a.id ?? 0);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _refreshFuture = null;
    super.dispose();
  }
}
