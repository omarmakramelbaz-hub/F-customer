import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/activity_update.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../utils/logger.dart';
import '../networking/api_helper.dart';
import '../networking/urls.dart';
import 'delivery_activity_model.dart';
import 'delivery_activity_payload.dart';
import 'delivery_activity_native.dart';

class DeliveryProvider extends ChangeNotifier with WidgetsBindingObserver {
  DeliveryProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  Timer? _reconcileTimer;
  StreamSubscription<String>? _fcmTokenSubscription;
  String? _registeredTokenKey;
  String? _fcmToken;
  bool _registering = false;
  bool _reconciling = false;
  bool _disposed = false;
  int _deliveryGeneration = 0;
  DateTime? _latestStatusTimestamp;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(reconcileOrder());
      _startReconcileTimer();
    } else {
      _reconcileTimer?.cancel();
      _reconcileTimer = null;
    }
  }

  void _startReconcileTimer() {
    _reconcileTimer?.cancel();
    if (_disposed || deliveryModel == null) return;
    _reconcileTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(reconcileOrder());
    });
  }

  Future<void> reconcileOrder() async {
    final id = orderId;
    if (_disposed || _reconciling || id == null || deliveryModel == null) return;
    _reconciling = true;
    try {
      final response = await ApiHelper.instance.get('${Urls.detailsOrders}/$id');
      if (!_disposed && id == orderId && response.state == ResponseState.complete) {
        final data = response.data['data'];
        if (data is Map) await syncOrderSnapshot(Map<String, dynamic>.from(data));
      }
      await _registerLiveActivity();
    } catch (error) {
      PrintLog.w('Live Activity reconciliation failed: $error');
    } finally {
      _reconciling = false;
    }
  }

  Future<void> syncOrderSnapshot(Map<String, dynamic> data) async {
    if (_disposed || deliveryModel == null ||
        DeliveryActivityPayload.orderId(data) != orderId?.toString()) return;
    final status = DeliveryActivityPayload.status(data);
    if (status == null) return;
    final timestamp = DeliveryActivityPayload.statusTimestamp(data);
    if (!DeliveryActivityPayload.shouldApply(
      currentStatus: deliveryModel!.orderStatus ?? 'Preparing',
      currentTimestamp: _latestStatusTimestamp,
      nextStatus: status,
      nextTimestamp: timestamp,
    )) return;
    if (timestamp != null) _latestStatusTimestamp = timestamp;
    deliveryModel = deliveryModel!.copyWith(
      orderNo: DeliveryActivityPayload.orderNo(data),
      restaurantName: data['resturant_name']?.toString() ?? data['restaurant_name']?.toString(),
      updatedAt: timestamp?.toUtc().toIso8601String(),
    );
    await updateStatus(status);
  }

  Future<void> _registerLiveActivity() async {
    if (_disposed || !Platform.isIOS || _registering) return;
    final id = orderId;
    final activityId = latestActivityId;
    final token = latestActivityPushToken;
    if (id == null || activityId == null || token == null || token.isEmpty) return;
    _registering = true;
    try {
      _fcmToken ??= await FirebaseMessaging.instance.getToken();
      if (_fcmToken == null || _fcmToken!.isEmpty) return;
      final key = '$id:$activityId:$token:${_fcmToken ?? ''}';
      if (_registeredTokenKey == key) return;
      final response = await ApiHelper.instance.post(
        Urls.orderLiveActivity(id),
        body: {
          'activity_id': activityId,
          'activity_token': token,
          if (_fcmToken != null && _fcmToken!.isNotEmpty) 'fcm_token': _fcmToken,
          'platform': 'ios',
        },
      );
      if (response.state == ResponseState.complete &&
          !_disposed && id == orderId && activityId == latestActivityId &&
          token == latestActivityPushToken) {
        _registeredTokenKey = key;
      }
    } catch (error) {
      PrintLog.w('Live Activity registration failed: $error');
    } finally {
      _registering = false;
    }
  }

  Future<void> _unregisterLiveActivity(int? id, String? activityId) async {
    if (!Platform.isIOS || id == null || activityId == null) return;
    try {
      await ApiHelper.instance.delete(Urls.orderLiveActivity(id), body: {'activity_id': activityId});
    } catch (error) {
      PrintLog.w('Live Activity unregistration failed: $error');
    }
  }

  final LiveActivities _liveActivitiesPlugin = LiveActivities();
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();

  bool _liveActivitiesReady = false;
  bool _pusherInitialized = false;
  String? _subscribedChannel;
  StreamSubscription<ActivityUpdate>? _activityUpdateSubscription;
  int? orderId;
  String? latestActivityId;
  String? latestActivityPushToken;
  DeliveryActivityModel? deliveryModel;

  final String apiKey = '8bb214071d3189c993bf';
  final String cluster = 'eu';
  String get channelName => 'order.$orderId';
  String eventName = 'status-updated';

  Map<String, dynamic>? buildLiveActivityRegistrationPayload() {
    if (orderId == null ||
        latestActivityId == null ||
        latestActivityPushToken == null ||
        latestActivityPushToken!.isEmpty) {
      return null;
    }

    return {
      'order_id': orderId.toString(),
      'activity_id': latestActivityId,
      'activity_token': latestActivityPushToken,
      if (_fcmToken != null) 'fcm_token': _fcmToken,
      'platform': 'ios',
    };
  }

  Future<void> init(int id) async {
    if (deliveryModel != null) await stopDelivery();
    PrintLog.i('➡️ init called with id=$id');
    orderId = id;
    latestActivityPushToken = null;
    _registeredTokenKey = null;
    final generatedActivityId =
        DeliveryActivityPayload.activityIdForOrderId(orderId);
    if (generatedActivityId.isNotEmpty) {
      latestActivityId = generatedActivityId;
      PrintLog.i('Generated deterministic activity id=$latestActivityId');
    }
    _notify();
    await _initializeLiveActivities();
    await _initializePusher();
    if (Platform.isIOS && _fcmTokenSubscription == null) {
      _fcmTokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _fcmToken = token;
        unawaited(_registerLiveActivity());
      });
    }
    PrintLog.i('✅ init completed for orderId=$orderId');
  }

  Future<String> checkLiveActivitiesSupport() async {
    PrintLog.i('➡️ checkLiveActivitiesSupport called');
    try {
      final supported = await _liveActivitiesPlugin.areActivitiesSupported();
      if (Platform.isIOS) {
        final enabled = await _liveActivitiesPlugin.areActivitiesEnabled();
        final msg =
            'iOS Live Activities supported: $supported, enabled: $enabled';
        PrintLog.i(msg);
        return msg;
      } else {
        final msg =
            'Android Live Activities (notification) supported: $supported';
        PrintLog.i(msg);
        return msg;
      }
    } catch (e) {
      final msg = 'Error checking Live Activities support: $e';
      PrintLog.e(msg);
      return msg;
    }
  }

  Future<void> _initializeLiveActivities() async {
    PrintLog.i('➡️ _initializeLiveActivities start');
    try {
      final supported = await _liveActivitiesPlugin.areActivitiesSupported();
      final enabled = await _liveActivitiesPlugin.areActivitiesEnabled();

      PrintLog.i('LiveActivities supported=$supported enabled=$enabled');

      if (!supported) {
        PrintLog.e('⚠️ Live Activities not available on this device/OS.');
        return;
      }
      if (!enabled) {
        PrintLog.e(
            '⚠️ Live Activities/notifications are disabled by the user.');
        return;
      }

      await _liveActivitiesPlugin.init(
        appGroupId: 'group.faskhaninja.liveactivities',
        urlScheme: Platform.isIOS ? 'la' : null,
      );
      _subscribeToActivityUpdates();

      _liveActivitiesReady = true;
      PrintLog.i(
          '✅ Live Activities ready (${Platform.isIOS ? 'iOS' : 'Android'})');
    } catch (e) {
      PrintLog.e('❌ Live Activities init failed: $e');
    }
  }

  void _subscribeToActivityUpdates() {
    if (!Platform.isIOS) {
      return;
    }

    _activityUpdateSubscription?.cancel();
    _activityUpdateSubscription =
        _liveActivitiesPlugin.activityUpdateStream.listen(
      (event) {
        event.mapOrNull(
          active: (active) {
            if (active.activityToken.isEmpty) {
              return;
            }
            if (latestActivityId == null ||
                latestActivityId == active.activityId) {
              latestActivityPushToken = active.activityToken;
              PrintLog.i(
                  'LIVE_ACTIVITY_PUSH_TOKEN_READY (activityId=${active.activityId})');
              _notify();
              unawaited(_registerLiveActivity());
            }
          },
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        PrintLog.e('Live Activity update stream error: $error');
      },
    );
  }

  Future<void> _waitForLiveActivityPushToken(
    String activityId, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    if (!Platform.isIOS || !_liveActivitiesReady) {
      return;
    }

    final generation = _deliveryGeneration;
    final end = DateTime.now().add(timeout);
    while (!_disposed && generation == _deliveryGeneration && latestActivityId == activityId && DateTime.now().isBefore(end)) {
      try {
        final token = await _liveActivitiesPlugin.getPushToken(activityId);
        if (!_disposed && generation == _deliveryGeneration && latestActivityId == activityId && token != null && token.isNotEmpty) {
          latestActivityPushToken = token;
          PrintLog.i(
              'LIVE_ACTIVITY_PUSH_TOKEN_READY (activityId=$activityId)');
          _notify();
          await _registerLiveActivity();
          return;
        }
      } catch (e) {
        PrintLog.w('Unable to fetch Live Activity push token: $e');
      }

      await Future<void>.delayed(const Duration(seconds: 2));
    }

    PrintLog.e(
      '⚠️ Live Activity push token timeout for activityId=$activityId. '
      'Remote terminated updates require this token.',
    );
  }

  Future<void> _initializePusher() async {
    PrintLog.i('➡️ _initializePusher start for orderId=$orderId');
    if (orderId == null) {
      PrintLog.w('No orderId provided; skipping Pusher initialization');
      return;
    }
    try {
      if (!_pusherInitialized) {
        PrintLog.i('Initializing Pusher with apiKey=$apiKey cluster=$cluster');
        await _pusher.init(apiKey: apiKey, cluster: cluster);
        _pusherInitialized = true;
        PrintLog.i('✅ Pusher SDK initialized');
      } else {
        PrintLog.i('Pusher SDK already initialized');
      }

      if (_subscribedChannel != null && _subscribedChannel != channelName) {
        PrintLog.i('Unsubscribing from previous channel=$_subscribedChannel');
        await _pusher.unsubscribe(channelName: _subscribedChannel!);
        PrintLog.i('🧹 Pusher unsubscribed from $_subscribedChannel');
      }

      if (_subscribedChannel != channelName) {
        PrintLog.i('Subscribing to channel=$channelName');
        await _pusher.subscribe(
          channelName: channelName,
          onEvent: (event) {
            if (event is PusherEvent) _onPusherEvent(event);
          },
          onSubscriptionError: (message, code, e) =>
              PrintLog.e('Pusher subscription error: $message, $code, $e'),
        );
        _subscribedChannel = channelName;
        PrintLog.i('✅ Pusher subscribed to $channelName');
      } else {
        PrintLog.i('Already subscribed to $channelName');
      }

      PrintLog.i('Connecting to Pusher...');
      await _pusher.connect();
      PrintLog.i('✅ Pusher connected');
    } catch (e) {
      PrintLog.e('❌ Pusher init error: $e');
    }
  }

  Future<void> _onPusherEvent(PusherEvent event) async {
    PrintLog.i(
        '📡 Event received: ${event.eventName} on channel ${event.channelName}');
    if (event.eventName != eventName) {
      PrintLog.i(
          'Event ${event.eventName} is not the expected $eventName; ignoring');
      return;
    }

    try {
      final data = _extractEventData(event.data);
      final status = _extractStatus(data);

      if (status == null) {
        PrintLog.e('⚠️ Status update event received without status payload.');
        return;
      }

      final eventOrderId = DeliveryActivityPayload.orderId(data);
      if (eventOrderId != null && eventOrderId != orderId?.toString()) return;
      if (deliveryModel == null) return;
      await syncOrderSnapshot({...data, 'order_id': orderId.toString()});
    } catch (e) {
      PrintLog.e('⚠️ Error parsing event: $e');
    }
  }

  Future<void> startDelivery(String? orderStatus, {String? orderNo, String? restaurantName, String? updatedAt}) async {
    if (DeliveryActivityPayload.isTerminal(orderStatus)) {
      await stopDelivery();
      return;
    }
    if (!_liveActivitiesReady || orderId == null) return;
    if (deliveryModel != null) await stopDelivery();
    final generation = ++_deliveryGeneration;
    _registeredTokenKey = null;
    latestActivityPushToken = null;
    _latestStatusTimestamp = DeliveryActivityPayload.statusTimestamp({'updated_at': updatedAt});
    PrintLog.i('➡️ startDelivery called with orderStatus=$orderStatus');
    if (_liveActivitiesReady) {
      PrintLog.i(
          'Ending all existing Live Activities before starting a new one');
      await _liveActivitiesPlugin.endAllActivities();
    }
    if (Platform.isIOS || Platform.isAndroid) {
      PrintLog.i('Requesting notification permission');
      final status = await Permission.notification.request();
      PrintLog.i('Notification permission status: $status');
      if (!status.isGranted) {
        PrintLog.e(
            '⚠️ Notification permission not granted; live activity/notification may not appear.');
      }
    }

    final newDeliveryModel = DeliveryActivityModel(
      orderStatus: _toDisplayStatus(orderStatus ?? 'Preparing'),
      orderId: orderId?.toString(),
      orderNo: orderNo,
      restaurantName: restaurantName,
      updatedAt: updatedAt,
    );
    PrintLog.i(
        'Created new DeliveryActivityModel: ${newDeliveryModel.toMap()}');

    String? activityId;
    final generatedActivityId =
        DeliveryActivityPayload.activityIdForOrderId(orderId);
    final fallbackId = generatedActivityId.isNotEmpty
        ? generatedActivityId
        : DateTime.now().millisecondsSinceEpoch.toString();

    if (_liveActivitiesReady) {
      PrintLog.i('Creating Live Activity with id=$fallbackId');
      activityId = await _liveActivitiesPlugin.createActivity(
        fallbackId,
        newDeliveryModel.toMap(),
        iOSEnableRemoteUpdates: true,
      );
      PrintLog.i('Live Activity created with id=$activityId');
    }

    if (_disposed || generation != _deliveryGeneration) {
      if (activityId != null) await _liveActivitiesPlugin.endActivity(activityId);
      return;
    }
    PrintLog.i('ActivityID: $activityId');
    await DeliveryActivityNative.sync(newDeliveryModel.toMap());
    if (_disposed || generation != _deliveryGeneration) {
      if (activityId != null) await _liveActivitiesPlugin.endActivity(activityId);
      return;
    }

    latestActivityId = activityId ?? fallbackId;
    latestActivityPushToken = null;
    if (_liveActivitiesReady && Platform.isIOS && latestActivityId != null) {
      unawaited(_waitForLiveActivityPushToken(latestActivityId!));
    }
    if (_disposed || generation != _deliveryGeneration) return;
    deliveryModel = newDeliveryModel;
    _startReconcileTimer();
    _notify();
    PrintLog.i('startDelivery finished - latestActivityId=$latestActivityId');
  }

  Future<void> updateStatus(String status) async {
    PrintLog.i('➡️ updateStatus called with status=$status');
    if (deliveryModel == null) {
      PrintLog.w('updateStatus ignored - no active deliveryModel');
      return;
    }

    final normalizedStatus = _normalizeStatus(status);
    PrintLog.i('Normalized status: $normalizedStatus');
    if (DeliveryActivityPayload.isTerminal(normalizedStatus)) {
      PrintLog.i('Status indicates delivered/completed -> stopping delivery');
      await stopDelivery();
      return;
    }

    final updatedModel =
        deliveryModel!.copyWith(orderStatus: _toDisplayStatus(status));
    PrintLog.i('Prepared updatedModel: ${updatedModel.toMap()}');

    if (_liveActivitiesReady && latestActivityId != null) {
      PrintLog.i(
          'Updating Live Activity id=$latestActivityId with ${updatedModel.toMap()}');
      if (Platform.isIOS) {
        await DeliveryActivityNative.sync(updatedModel.toMap());
      } else {
        await _liveActivitiesPlugin.updateActivity(latestActivityId!, updatedModel.toMap());
      }
      PrintLog.i('✅ Live Activity updated from updateStatus');
    }

    deliveryModel = updatedModel;
    _notify();
    PrintLog.i('updateStatus finished and listeners notified');
  }

  Future<void> stopDelivery() async {
    PrintLog.i('Stopping Live Activity');
    final id = orderId;
    final activityId = latestActivityId;
    ++_deliveryGeneration;
    _reconcileTimer?.cancel();
    _reconcileTimer = null;
    latestActivityId = null;
    latestActivityPushToken = null;
    _registeredTokenKey = null;
    _latestStatusTimestamp = null;
    deliveryModel = null;
    _notify();
    try {
      if (_liveActivitiesReady && activityId != null) {
        await _liveActivitiesPlugin.endActivity(activityId);
      }
    } finally {
      await _unregisterLiveActivity(id, activityId);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_deliveryGeneration;
    WidgetsBinding.instance.removeObserver(this);
    _reconcileTimer?.cancel();
    unawaited(_activityUpdateSubscription?.cancel());
    unawaited(_fcmTokenSubscription?.cancel());
    if (_subscribedChannel != null) {
      unawaited(_pusher.unsubscribe(channelName: _subscribedChannel!));
    }
    _liveActivitiesPlugin.dispose();
    super.dispose();
  }

  Map<String, dynamic> _extractEventData(String? rawData) {
    if (rawData == null || rawData.isEmpty) return {};

    dynamic decoded;
    try {
      decoded = jsonDecode(rawData);
    } catch (_) {
      PrintLog.w('_extractEventData: failed to jsonDecode rawData');
      return {};
    }

    final initialData = _toMap(decoded);
    if (initialData == null) {
      PrintLog.w('_extractEventData: decoded payload is not a Map');
      return {};
    }
    Map<String, dynamic> data = initialData;

    final nestedData = data['data'];
    if (nestedData is String && nestedData.isNotEmpty) {
      try {
        final nestedDecoded = jsonDecode(nestedData);
        final nestedMap = _toMap(nestedDecoded);
        if (nestedMap != null) data = nestedMap;
      } catch (_) {
        // Ignore invalid nested JSON and keep original payload.
        PrintLog.w(
            '_extractEventData: nested data is not valid JSON - keeping original payload');
      }
    } else {
      final nestedMap = _toMap(nestedData);
      if (nestedMap != null) data = nestedMap;
    }

    return data;
  }

  Map<String, dynamic>? _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String? _extractStatus(Map<String, dynamic> data) => DeliveryActivityPayload.status(data);

  String _normalizeStatus(String value) => DeliveryActivityPayload.normalizedStatus(value);

  String _toDisplayStatus(String rawValue) => DeliveryActivityPayload.displayStatus(rawValue);
}
