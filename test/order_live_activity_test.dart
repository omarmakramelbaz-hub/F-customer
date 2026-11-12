import 'dart:async';

import 'package:faskhaninja/helpers/delivery_activity/delivery_provider.dart';
import 'package:faskhaninja/helpers/delivery_activity/order_activity_platform.dart';
import 'package:faskhaninja/helpers/pusher_service/pusher_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class _Platform implements OrderActivityPlatform {
  final tokens = StreamController<OrderActivitySnapshot>.broadcast();
  final updates = <Map<String, dynamic>>[];
  final endings = <Map<String, dynamic>>[];
  bool enabled = true;
  String? token = 'synthetic-apple-token';
  @override
  bool get isIOS => true;
  @override
  Stream<OrderActivitySnapshot> get tokenUpdates => tokens.stream;
  @override
  Future<bool> supported() async => enabled;
  @override
  Future<OrderActivitySnapshot?> sync(int id, Map<String, dynamic> data) async {
    updates.add(data);
    return OrderActivitySnapshot(id, 'native-uuid-$id', pushToken: token);
  }

  @override
  Future<void> end(int id, Map<String, dynamic> data,
      {bool immediate = false}) async {
    endings.add({...data, 'target_order': id, 'immediate': immediate});
  }

  @override
  void dispose() {
    unawaited(tokens.close());
  }
}

class _Pusher extends PusherController {
  final listeners = <String, List<void Function(PusherEvent)>>{};
  @override
  void addEventListener(String name, void Function(PusherEvent) listener) {
    (listeners[name] ??= []).add(listener);
  }

  @override
  void removeEventListener(String name, void Function(PusherEvent) listener) {
    listeners[name]?.remove(listener);
  }

  void emit(String name, String data) {
    for (final listener in [...?listeners[name]]) {
      listener(PusherEvent(
          channelName: 'private-user.1', eventName: name, data: data));
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'authentic order stages reach the native activity and retain delivered content',
      () async {
    final platform = _Platform();
    final registrations = <Map<String, dynamic>>[];
    final provider = DeliveryProvider(
      platform: platform,
      deviceToken: () async => 'synthetic-fcm-token',
      registerActivity: (data) async {
        registrations.add(data);
        return true;
      },
      unregisterActivity: (_) async {},
    );
    addTearDown(provider.dispose);
    await provider.syncOrder(id: 10, status: 'pending');
    await provider.syncOrder(id: 10, status: 'shipped');
    await provider.syncOrder(id: 10, status: 'completed');
    expect(platform.updates.map((data) => data['order_status']),
        ['Preparing', 'On the Way']);
    expect(platform.endings.single['order_status'], 'Delivered');
    expect(platform.endings.single['target_order'], 10);
    expect(platform.endings.single['immediate'], false);
    expect(registrations.single['live_activity_id'], 'native-uuid-10');
    expect(
        registrations.single['live_activity_token'], 'synthetic-apple-token');
    expect(registrations.single['fcm_token'], 'synthetic-fcm-token');
    expect(provider.orderId, isNull);
  });

  test(
      'native push-token rotation is registered and delivery failures are retried',
      () async {
    final platform = _Platform()..token = null;
    final registrations = <Map<String, dynamic>>[];
    bool deliver = false;
    final provider = DeliveryProvider(
      platform: platform,
      deviceToken: () async => 'synthetic-fcm-token',
      registerActivity: (data) async {
        registrations.add(data);
        return deliver;
      },
      unregisterActivity: (_) async {},
    );
    addTearDown(provider.dispose);
    await provider.syncOrder(id: 10, status: 'accepted');
    expect(registrations, isEmpty);
    platform.tokens.add(const OrderActivitySnapshot(999, 'native-uuid-999',
        pushToken: 'wrong-order'));
    await Future<void>.delayed(Duration.zero);
    expect(registrations, isEmpty);
    platform.tokens.add(const OrderActivitySnapshot(10, 'native-uuid-10',
        pushToken: 'rotated-token'));
    await Future<void>.delayed(Duration.zero);
    expect(registrations.length, 1);
    deliver = true;
    await provider.syncOrder(id: 10, status: 'shipped');
    expect(registrations.length, 2);
    expect(registrations.last['live_activity_token'], 'rotated-token');
  });

  test('shared private socket and app resume refresh the authenticated order',
      () async {
    final platform = _Platform();
    final pusher = _Pusher();
    var status = 'pending';
    int fetches = 0;
    final provider = DeliveryProvider(
      platform: platform,
      pusher: pusher,
      deviceToken: () async => null,
      registerActivity: (_) async => true,
      unregisterActivity: (_) async {},
      orderLoader: (id) async {
        fetches++;
        return {'id': id, 'status': status};
      },
    );
    addTearDown(pusher.dispose);
    addTearDown(provider.dispose);
    await provider.syncOrder(id: 10, status: status);
    pusher.emit('status-updated', '{"order_id":20}');
    await Future<void>.delayed(Duration.zero);
    expect(fetches, 0);
    status = 'shipped';
    pusher.emit('status-updated', '{"order_id":10}');
    await Future<void>.delayed(Duration.zero);
    expect(platform.updates.last['order_status'], 'On the Way');
    provider.didChangeAppLifecycleState(AppLifecycleState.paused);
    pusher.emit('user.updated', '{}');
    await Future<void>.delayed(Duration.zero);
    expect(fetches, 1);
    status = 'completed';
    provider.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(platform.endings.single['order_status'], 'Delivered');
  });

  test('an old finished order never closes the active order', () async {
    final platform = _Platform();
    final provider = DeliveryProvider(
        platform: platform,
        deviceToken: () async => null,
        registerActivity: (_) async => true,
        unregisterActivity: (_) async {});
    addTearDown(provider.dispose);
    await provider.syncOrder(id: 10, status: 'shipped');
    await provider.syncOrder(id: 20, status: 'completed');
    expect(provider.orderId, 10);
    expect(platform.endings.single['target_order'], 20);
  });

  test(
      'unsupported activity surfaces cannot interrupt checkout or start remote registration',
      () async {
    final platform = _Platform()..enabled = false;
    final provider = DeliveryProvider(
        platform: platform,
        registerActivity: (_) async => throw StateError('Must not register'),
        unregisterActivity: (_) async {});
    addTearDown(provider.dispose);
    await provider.syncOrder(id: 10, status: 'pending');
    expect(platform.updates, isEmpty);
    expect(provider.latestActivityId, isNull);
  });
}
