import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:live_activities/live_activities.dart';

class OrderActivitySnapshot {
  const OrderActivitySnapshot(this.orderId, this.activityId, {this.pushToken});
  final int orderId;
  final String activityId;
  final String? pushToken;

  static OrderActivitySnapshot? fromMap(dynamic value) {
    if (value is! Map) return null;
    final id = int.tryParse('${value['order_id']}');
    final activityId = value['activity_id']?.toString();
    if (id == null || activityId == null || activityId.isEmpty) return null;
    return OrderActivitySnapshot(
      id,
      activityId,
      pushToken: value['push_token']?.toString(),
    );
  }
}

abstract class OrderActivityPlatform {
  bool get isIOS;
  Stream<OrderActivitySnapshot> get tokenUpdates;
  Future<bool> supported();
  Future<OrderActivitySnapshot?> sync(int orderId, Map<String, dynamic> data);
  Future<void> end(
    int orderId,
    Map<String, dynamic> data, {
    bool immediate = false,
  });
  void dispose();
}

// ActivityKit receives the same typed content state locally and through APNs.
// Android continues to use the existing ongoing notification implementation.
class NativeOrderActivityPlatform implements OrderActivityPlatform {
  static const channel = MethodChannel('com.fasakhansta/order_activity');
  final _tokens = StreamController<OrderActivitySnapshot>.broadcast();
  final _android = LiveActivities();
  bool _initialized = false;

  NativeOrderActivityPlatform() {
    if (isIOS) {
      channel.setMethodCallHandler((call) async {
        if (call.method != 'token') return;
        final snapshot = OrderActivitySnapshot.fromMap(call.arguments);
        if (snapshot != null && !_tokens.isClosed) _tokens.add(snapshot);
      });
    }
  }

  @override
  bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  @override
  Stream<OrderActivitySnapshot> get tokenUpdates => _tokens.stream;

  @override
  Future<bool> supported() async {
    if (isIOS) return await channel.invokeMethod<bool>('supported') ?? false;
    if (!_isAndroid) return false;
    if (!_initialized) {
      await _android.init(appGroupId: 'group.faskhaninja.liveactivities');
      _initialized = true;
    }
    return _android.areActivitiesSupported();
  }

  @override
  Future<OrderActivitySnapshot?> sync(
    int orderId,
    Map<String, dynamic> data,
  ) async {
    if (isIOS) {
      return OrderActivitySnapshot.fromMap(
        await channel.invokeMethod<dynamic>('sync', data),
      );
    }
    if (!_isAndroid) return null;
    final id = 'order_$orderId';
    await _android.createOrUpdateActivity(id, data);
    return OrderActivitySnapshot(orderId, id);
  }

  @override
  Future<void> end(
    int orderId,
    Map<String, dynamic> data, {
    bool immediate = false,
  }) async {
    if (isIOS) {
      await channel.invokeMethod<void>('end', {
        ...data,
        'immediate': immediate,
      });
    } else if (_isAndroid) {
      final id = 'order_$orderId';
      if (!immediate) {
        await _android.updateActivity(id, data);
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      await _android.endActivity(id);
    }
  }

  @override
  void dispose() {
    if (isIOS) channel.setMethodCallHandler(null);
    unawaited(_tokens.close());
  }
}
