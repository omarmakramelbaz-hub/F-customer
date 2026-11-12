import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../networking/api_helper.dart';
import '../networking/urls.dart';
import '../pusher_service/pusher_controller.dart';
import '../utils/logger.dart';
import 'delivery_activity_model.dart';
import 'order_activity_platform.dart';

class DeliveryProvider extends ChangeNotifier with WidgetsBindingObserver {
  DeliveryProvider({
    OrderActivityPlatform? platform,
    Future<bool> Function(Map<String, dynamic>)? registerActivity,
    Future<void> Function(Map<String, dynamic>)? unregisterActivity,
    Future<String?> Function()? deviceToken,
    Future<Map<String, dynamic>?> Function(int)? orderLoader,
    PusherController? pusher,
  })  : _platform = platform ?? NativeOrderActivityPlatform(),
        _registerActivity = registerActivity ?? _register,
        _unregisterActivity = unregisterActivity ?? _unregister,
        _deviceToken =
            deviceToken ?? (() => FirebaseMessaging.instance.getToken()),
        _orderLoader = orderLoader ?? _loadOrder,
        _pusher = pusher {
    WidgetsBinding.instance.addObserver(this);
    _tokenSubscription = _platform.tokenUpdates.listen(_receiveToken);
    _pusher?.addEventListener('status-updated', _onStatusEvent);
    _pusher?.addEventListener('user.updated', _onOrderEvent);
  }

  final OrderActivityPlatform _platform;
  final Future<bool> Function(Map<String, dynamic>) _registerActivity;
  final Future<void> Function(Map<String, dynamic>) _unregisterActivity;
  final Future<String?> Function() _deviceToken;
  final Future<Map<String, dynamic>?> Function(int) _orderLoader;
  final PusherController? _pusher;
  StreamSubscription<OrderActivitySnapshot>? _tokenSubscription;
  Timer? _poll;
  Future<void> _pending = Future<void>.value();
  bool _disposed = false;
  bool _foreground = true;
  bool _refreshing = false;
  String? _registered;
  int? orderId;
  String? latestActivityId;
  String? latestActivityPushToken;
  DeliveryActivityModel? deliveryModel;

  static Future<bool> _register(Map<String, dynamic> data) async {
    final response = await ApiHelper.instance.post(
      Urls.liveActivities,
      body: data,
      requestTimeout: const Duration(seconds: 12),
    );
    return response.state == ResponseState.complete;
  }

  static Future<void> _unregister(Map<String, dynamic> data) async {
    await ApiHelper.instance.post(
      '${Urls.liveActivities}/unregister',
      body: data,
      requestTimeout: const Duration(seconds: 8),
    );
  }

  static Future<Map<String, dynamic>?> _loadOrder(int id) async {
    final response = await ApiHelper.instance.get('${Urls.detailsOrders}/$id');
    final data = response.data;
    if (response.state != ResponseState.complete ||
        data is! Map ||
        data['data'] is! Map) return null;
    return Map<String, dynamic>.from(data['data'] as Map);
  }

  static int? _timestamp(String? value) {
    final date = DateTime.tryParse(value ?? '');
    return date == null ? null : date.millisecondsSinceEpoch ~/ 1000;
  }

  static String normalizeStatus(String status) =>
      status.trim().toLowerCase().replaceAll(RegExp(r'[ -]'), '_');
  static bool isTerminal(String status) => const {
        'delivered',
        'completed',
        'cancelled',
        'canceled',
        'declined',
        'rejected',
        'ended',
        'failed',
        'payment_failed',
      }.contains(normalizeStatus(status));

  static String displayStatus(String status) {
    switch (normalizeStatus(status)) {
      case 'pending':
      case 'new_order':
      case 'accepted':
      case 'preparing':
      case 'in_preparation':
        return 'Preparing';
      case 'shipped':
      case 'picked_up':
      case 'on_the_way':
      case 'out_for_delivery':
        return 'On the Way';
      case 'completed':
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
      case 'canceled':
      case 'declined':
      case 'rejected':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Map<String, dynamic>? buildLiveActivityRegistrationPayload() {
    if (orderId == null ||
        latestActivityId == null ||
        latestActivityPushToken?.isNotEmpty != true) return null;
    return {
      'order_id': orderId,
      'live_activity_id': latestActivityId,
      'live_activity_token': latestActivityPushToken,
      'platform': 'ios',
    };
  }

  Future<void> syncOrder({
    required int id,
    required String status,
    String? restaurantName,
    String? updatedAt,
  }) {
    // Serialize native calls: an older response cannot finish after a newer stage.
    _pending = _pending.then((_) async {
      if (_disposed || id <= 0 || status.isEmpty) return;
      try {
        if (!await _platform.supported() || _disposed) return;
        final model = DeliveryActivityModel(
          orderId: '$id',
          orderStatus: displayStatus(status),
          restaurantName: restaurantName ?? 'Fasakhansta',
          updatedAt: _timestamp(updatedAt),
        );
        if (isTerminal(status)) {
          await _platform.end(id, model.toMap());
          if (orderId == id) await _clearRegistration();
          return;
        }
        final snapshot = await _platform.sync(id, model.toMap());
        if (snapshot == null || _disposed) return;
        if (latestActivityId != snapshot.activityId) {
          latestActivityPushToken = null;
          _registered = null;
        }
        orderId = id;
        deliveryModel = model;
        latestActivityId = snapshot.activityId;
        if (snapshot.pushToken?.isNotEmpty == true)
          latestActivityPushToken = snapshot.pushToken;
        _poll ??= Timer.periodic(
          const Duration(seconds: 45),
          (_) => unawaited(_refreshOrder()),
        );
        notifyListeners();
        await _registerToken();
      } catch (_) {
        // Order tracking and checkout remain usable if system activities are disabled.
        PrintLog.w(
          'Live Activity sync unavailable; retrying on the next order refresh.',
        );
      }
    });
    return _pending;
  }

  void _receiveToken(OrderActivitySnapshot snapshot) {
    if (_disposed ||
        snapshot.orderId != orderId ||
        snapshot.activityId != latestActivityId) return;
    latestActivityPushToken = snapshot.pushToken;
    unawaited(_registerToken());
  }

  Future<void> _registerToken() async {
    if (!_platform.isIOS || _disposed) return;
    final data = buildLiveActivityRegistrationPayload();
    if (data == null) return;
    try {
      final device = await _deviceToken();
      if (device == null || device.isEmpty || _disposed) return;
      data['fcm_token'] = device;
      final key = jsonEncode(data);
      if (_registered == key) return;
      if (await _registerActivity(data) &&
          !_disposed &&
          latestActivityId == data['live_activity_id'] &&
          latestActivityPushToken == data['live_activity_token']) {
        _registered = key;
      }
    } catch (_) {
      PrintLog.w('Live Activity registration pending; retrying on refresh.');
    }
  }

  void _onStatusEvent(PusherEvent event) {
    try {
      final data = jsonDecode(event.data);
      if (data is! Map || int.tryParse('${data['order_id']}') != orderId)
        return;
      // Refresh authenticated order details instead of trusting stale socket payloads.
      unawaited(_refreshOrder());
    } catch (_) {
      /* Ignore malformed events. */
    }
  }

  void _onOrderEvent(PusherEvent event) => unawaited(_refreshOrder());

  Future<void> _refreshOrder() async {
    final id = orderId;
    if (_disposed || !_foreground || _refreshing || id == null) return;
    _refreshing = true;
    try {
      final data = await _orderLoader(id);
      if (_disposed ||
          orderId != id ||
          data == null ||
          int.tryParse('${data['id']}') != id) return;
      final status = data['status']?.toString();
      if (status == null || status.isEmpty) return;
      await syncOrder(
        id: id,
        status: status,
        restaurantName: data['resturant_name']?.toString(),
        updatedAt: data['updated_at']?.toString(),
      );
    } catch (_) {
      PrintLog.w('Live Activity order refresh unavailable.');
    } finally {
      _refreshing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) unawaited(_refreshOrder());
  }

  Future<void> _clearRegistration() async {
    final id = orderId;
    final activity = latestActivityId;
    _poll?.cancel();
    _poll = null;
    orderId = null;
    latestActivityId = null;
    latestActivityPushToken = null;
    deliveryModel = null;
    _registered = null;
    if (!_disposed) notifyListeners();
    if (_platform.isIOS && id != null && activity != null) {
      try {
        await _unregisterActivity({
          'order_id': id,
          'live_activity_id': activity,
        });
      } catch (_) {
        /* Server expires inactive registrations. */
      }
    }
  }

  Future<void> init(int id) async {
    orderId = id;
  }

  Future<void> startDelivery(String? status) async {
    final id = orderId;
    if (id != null) await syncOrder(id: id, status: status ?? 'Preparing');
  }

  Future<void> updateStatus(String status) async {
    final id = orderId;
    if (id != null) await syncOrder(id: id, status: status);
  }

  Future<void> stopDelivery() async {
    await _pending;
    final id = orderId;
    if (id != null) {
      try {
        await _platform.end(
            id,
            {
              'order_id': '$id',
              'order_status': 'ended',
            },
            immediate: true);
      } catch (_) {
        /* Already ended. */
      }
    }
    await _clearRegistration();
  }

  Future<String> checkLiveActivitiesSupport() async =>
      'Live Activities supported: ${await _platform.supported()}';

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    _tokenSubscription?.cancel();
    _pusher?.removeEventListener('status-updated', _onStatusEvent);
    _pusher?.removeEventListener('user.updated', _onOrderEvent);
    WidgetsBinding.instance.removeObserver(this);
    _platform.dispose();
    super.dispose();
  }
}
