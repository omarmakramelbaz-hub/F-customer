import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/activity_update.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../utils/logger.dart';
import 'delivery_activity_model.dart';
import 'delivery_activity_push_handler.dart';

class DeliveryProvider extends ChangeNotifier {
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
      'live_activity_id': latestActivityId,
      'live_activity_token': latestActivityPushToken,
      'platform': 'ios',
    };
  }

  Future<void> init(int id) async {
    PrintLog.i('➡️ init called with id=$id');
    orderId = id;
    final generatedActivityId =
        DeliveryActivityPushHandler.activityIdForOrderId(orderId);
    if (generatedActivityId.isNotEmpty) {
      latestActivityId = generatedActivityId;
      PrintLog.i('Generated deterministic activity id=$latestActivityId');
    }
    notifyListeners();
    await _initializeLiveActivities();
    await _initializePusher();
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
              notifyListeners();
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

    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      try {
        final token = await _liveActivitiesPlugin.getPushToken(activityId);
        if (token != null && token.isNotEmpty) {
          latestActivityPushToken = token;
          PrintLog.i(
              'LIVE_ACTIVITY_PUSH_TOKEN_READY (activityId=$activityId)');
          notifyListeners();
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

      final normalizedStatus = _normalizeStatus(status);
      final displayStatus = _toDisplayStatus(status);
      PrintLog.w(
          'Order status update raw="$status" normalized="$normalizedStatus" display="$displayStatus"');

      if (deliveryModel == null) {
        PrintLog.e('⚠️ Received event but no active delivery');
        return;
      }

      if (normalizedStatus == 'ended' ||
          normalizedStatus == 'cancelled' ||
          normalizedStatus == 'declined') {
        PrintLog.i(
            'Status indicates end/cancel/decline: $normalizedStatus -> stopping delivery');
        await stopDelivery();
        return;
      }

      final updatedModel = deliveryModel!.copyWith(orderStatus: displayStatus);
      PrintLog.i('Updated deliveryModel prepared: ${updatedModel.toMap()}');

      if (_liveActivitiesReady && latestActivityId != null) {
        PrintLog.i(
            'Updating Live Activity id=$latestActivityId with data=${updatedModel.toMap()}');
        await _liveActivitiesPlugin.updateActivity(
            latestActivityId!, updatedModel.toMap());
        PrintLog.i('✅ Live Activity updated');
      }

      deliveryModel = updatedModel;
      notifyListeners();
      PrintLog.i('Listeners notified after status update');

      if (normalizedStatus == 'delivered' || normalizedStatus == 'completed') {
        PrintLog.i(
            'Status is delivered/completed; scheduling stopDelivery in 2s');
        await Future.delayed(const Duration(seconds: 2));
        await stopDelivery();
        return;
      }
    } catch (e) {
      PrintLog.e('⚠️ Error parsing event: $e');
    }
  }

  Future<void> startDelivery(String? orderStatus) async {
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
    );
    PrintLog.i(
        'Created new DeliveryActivityModel: ${newDeliveryModel.toMap()}');

    String? activityId;
    final generatedActivityId =
        DeliveryActivityPushHandler.activityIdForOrderId(orderId);
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

    PrintLog.i('ActivityID: $activityId');

    latestActivityId = activityId ?? fallbackId;
    latestActivityPushToken = null;
    if (_liveActivitiesReady && Platform.isIOS && latestActivityId != null) {
      unawaited(_waitForLiveActivityPushToken(latestActivityId!));
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 800), () async {
          try {
            final token =
                await _liveActivitiesPlugin.getPushToken(latestActivityId!);
            if (token != null && token.isNotEmpty) {
              latestActivityPushToken = token;
              PrintLog.i(
                  'LIVE_ACTIVITY_PUSH_TOKEN_READY (activityId=$latestActivityId)');
              notifyListeners();
            } else {
              PrintLog.w(
                'Live Activity push token is empty for activityId=$latestActivityId, waiting for activityUpdateStream.',
              );
            }
          } catch (e) {
            PrintLog.w('Unable to fetch Live Activity push token: $e');
          }
        }),
      );
    }
    deliveryModel = newDeliveryModel;
    notifyListeners();
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
    if (normalizedStatus == 'delivered' || normalizedStatus == 'completed') {
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
      await _liveActivitiesPlugin.updateActivity(
          latestActivityId!, updatedModel.toMap());
      PrintLog.i('✅ Live Activity updated from updateStatus');
    }

    deliveryModel = updatedModel;
    notifyListeners();
    PrintLog.i('updateStatus finished and listeners notified');
  }

  Future<void> stopDelivery() async {
    PrintLog.i('➡️ stopDelivery called');
    if (_liveActivitiesReady) {
      PrintLog.i('Ending all Live Activities');
      await _liveActivitiesPlugin.endAllActivities();
      PrintLog.i('✅ All Live Activities ended');
    } else {
      PrintLog.i('Live activities not ready; skipping endAllActivities');
    }
    latestActivityId = null;
    latestActivityPushToken = null;
    deliveryModel = null;
    notifyListeners();
    PrintLog.i(
        'stopDelivery finished - delivery cleared and listeners notified');
  }

  @override
  void dispose() {
    PrintLog.i('➡️ dispose called - cleaning up resources');
    if (_subscribedChannel != null) {
      PrintLog.i('Unsubscribing from channel=$_subscribedChannel (dispose)');
      unawaited(_pusher.unsubscribe(channelName: _subscribedChannel!));
      _subscribedChannel = null;
    }
    if (_activityUpdateSubscription != null) {
      unawaited(_activityUpdateSubscription!.cancel());
      _activityUpdateSubscription = null;
    }
    _pusher.disconnect();
    PrintLog.i('📴 Pusher disconnected');
    _liveActivitiesPlugin.dispose();
    PrintLog.i('LiveActivities disposed');
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

  String? _extractStatus(Map<String, dynamic> data) {
    PrintLog.i('➡️ _extractStatus called with data keys=${data.keys.toList()}');
    final values = <dynamic>[
      data['order_status'],
      data['orderStatus'],
      data['status'],
      if (data['order'] is Map) (data['order'] as Map)['status'],
    ];

    for (final value in values) {
      if (value == null) continue;
      final status = value.toString().trim();
      if (status.isNotEmpty) {
        PrintLog.i('_extractStatus found status=$status');
        return status;
      }
    }
    PrintLog.w('_extractStatus: no status found in payload');
    return null;
  }

  String _normalizeStatus(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'[\s-]+'), '_');
  }

  String _toDisplayStatus(String rawValue) {
    final normalized = _normalizeStatus(rawValue);

    switch (normalized) {
      case 'new_order':
      case 'pending':
      case 'accepted':
      case 'preparing':
      case 'in_preparation':
        return 'Preparing';
      case 'picked_up':
      case 'on_the_way':
      case 'out_for_delivery':
      case 'shipped':
        return 'On the Way';
      case 'delivered':
      case 'completed':
        return 'Delivered';
      default:
        final value = rawValue.replaceAll('_', ' ').trim();
        return value.isEmpty ? 'Preparing' : value;
    }
  }
}
