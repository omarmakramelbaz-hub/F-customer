import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:live_activities/live_activities.dart';

import '../utils/logger.dart';

class DeliveryActivityPushHandler {
  static final LiveActivities _liveActivities = LiveActivities();

  static const String _appGroupId = 'group.faskhaninja.liveactivities';

  static Future<void> handlePushData(Map<String, dynamic> payload) async {
    final data = _extractPayload(payload);

    final looksLikeLiveActivity = _looksLikeLiveActivityUpdate(data);
    if (!looksLikeLiveActivity) {
      log('LiveActivityPush ignored: payload is not live activity update');
      return;
    }

    try {
      final supported = await _liveActivities.areActivitiesSupported();
      if (!supported) {
        log('LiveActivityPush skipped: activities are not supported on this device');
        return;
      }

      await _liveActivities.init(
        appGroupId: _appGroupId,
        urlScheme: Platform.isIOS ? 'la' : null,
        requestAndroidNotificationPermission: false,
      );

      final status = _extractStatus(data);
      final activityId = _extractActivityId(data);
      final isEndEvent = _isEndEvent(status);

      final payloadData = _buildLiveActivityData(data, status);
      final allActivityIds = await _liveActivities.getAllActivitiesIds();

      log(
        'LiveActivityPush resolved status=$status '
        'activityId=$activityId isEndEvent=$isEndEvent allActivityIds=$allActivityIds',
      );

      if (activityId != null && activityId.isNotEmpty) {
        if (isEndEvent) {
          await _liveActivities.endActivity(activityId);
          log('LiveActivityPush action=end target=$activityId done');
        } else {
          await _liveActivities.updateActivity(activityId, payloadData);

if (payloadData['order_status'] == 'Rejected') {
  Future.delayed(const Duration(seconds: 2), () async {
    try {
      await _liveActivities.endActivity(activityId);
      log('LiveActivityPush auto-end rejected activity=$activityId');
    } catch (_) {}
  });
}

log('LiveActivityPush action=update target=$activityId done');
        }
        return;
      }

      if (allActivityIds.isEmpty) {
        log('LiveActivityPush skipped: no running activities to update/end');
        return;
      }
      for (final id in allActivityIds) {
        if (isEndEvent) {
          await _liveActivities.endActivity(id);
          log('LiveActivityPush action=end target=$id done');
        } else {
          await _liveActivities.updateActivity(id, payloadData);
          log('LiveActivityPush action=update target=$id done');
        }
      }
    } catch (e, stackTrace) {
      log('Live Activity push handling failed: $e');
      log('$stackTrace');
    }
  }

  static bool isLiveActivityPayload(Map<String, dynamic> payload) {
    final data = _extractPayload(payload);
    return _looksLikeLiveActivityUpdate(data);
  }

  static String activityIdForOrderId(dynamic orderId) {
    final value = orderId?.toString().trim();
    if (value == null || value.isEmpty) return '';
    return 'order_$value';
  }

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> payload) {
    var data = Map<String, dynamic>.from(payload);

    final contentState = data['content-state'];
    if (contentState is String && contentState.isNotEmpty) {
      try {
        final decoded = jsonDecode(contentState);
        if (decoded is Map) {
          data = {
            ...data,
            ...Map<String, dynamic>.from(decoded),
          };
        }
      } catch (_) {
        // Ignore malformed content-state and continue with payload as-is.
      }
    }

    final nested = data['data'];
    if (nested is String && nested.isNotEmpty) {
      try {
        final decoded = jsonDecode(nested);
        if (decoded is Map) {
          data = {
            ...data,
            ...Map<String, dynamic>.from(decoded),
          };
        }
      } catch (_) {
        // Ignore malformed nested data and continue.
      }
    } else if (nested is Map) {
      data = {
        ...data,
        ...Map<String, dynamic>.from(nested),
      };
    }

    return data;
  }

  static bool _looksLikeLiveActivityUpdate(Map<String, dynamic> data) {
    final notificationType =
        (data['notification_type'])?.toString().toLowerCase().trim();
    PrintLog.e(notificationType);
    final hasLiveActivityType = notificationType == 'live_activity';

    final hasExplicitLiveActivityMarker = data['live_activity'] == true ||
        data['live_activity']?.toString() == '1' ||
        data['live_activity']?.toString().toLowerCase() == 'true';

    final hasStatus = _extractStatus(data) != null;
    final hasOnlyStatusPayload = hasStatus &&
        data.keys.every(
          (key) =>
              key == 'order_status' ||
              key == 'orderStatus' ||
              key == 'order_state' ||
              key == 'orderState' ||
              key == 'status' ||
              key == 'title' ||
              key == 'message' ||
              key == 'body',
        );
    final hasActivityId = _extractActivityId(data) != null;

    return hasLiveActivityType ||
        hasExplicitLiveActivityMarker ||
        hasActivityId ||
        hasOnlyStatusPayload;
  }

  static String? _extractStatus(Map<String, dynamic> data) {
    final values = <dynamic>[
      data['order_status'],
      data['orderStatus'],
      data['order_state'],
      data['orderState'],
      data['status'],
      if (data['order'] is Map) (data['order'] as Map)['status'],
    ];

    for (final value in values) {
      if (value == null) continue;
      final status = value.toString().trim();
      if (status.isNotEmpty) return status;
    }
    return null;
  }

  static String? _extractActivityId(Map<String, dynamic> data) {
    final explicit = data['activity-id'] ??
        data['activity_id'] ??
        data['activityId'] ??
        data['live_activity_id'] ??
        data['liveActivityId'];

    final explicitValue = explicit?.toString().trim();
    if (explicitValue != null && explicitValue.isNotEmpty) return explicitValue;

    final orderId = _extractOrderId(data);
    final generated = activityIdForOrderId(orderId);
    return generated.isEmpty ? null : generated;
  }

  static String? _extractOrderId(Map<String, dynamic> data) {
    final values = <dynamic>[
      data['order_id'],
      data['orderId'],
      data['id'],
      if (data['order'] is Map) (data['order'] as Map)['id'],
      if (data['order'] is Map) (data['order'] as Map)['order_id'],
    ];

    for (final value in values) {
      if (value == null) continue;
      final id = value.toString().trim();
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  static bool _isEndEvent(String? status) {
    if (status == null) return false;

    final normalized =
        status.toLowerCase().trim().replaceAll(RegExp(r'[\s-]+'), '_');
    return normalized == 'ended' ||
        normalized == 'delivered' ||
        normalized == 'completed' ;
  }

  static Map<String, dynamic> _buildLiveActivityData(
    Map<String, dynamic> data,
    String? rawStatus,
  ) {
    final status = _toDisplayStatus(rawStatus ?? 'Preparing');

    final payload = <String, dynamic>{
      'order_status': status,
      'orderStatus': status,
    };

    final orderId = _extractOrderId(data);
    if (orderId != null && orderId.isNotEmpty) {
      payload['orderId'] = orderId;
      payload['order_id'] = orderId;
    }

    final restaurantName =
        data['restaurantName'] ?? data['restaurant_name'] ?? data['restaurant'];
    if (restaurantName != null && restaurantName.toString().trim().isNotEmpty) {
      payload['restaurantName'] = restaurantName.toString();
      payload['restaurant_name'] = restaurantName.toString();
    }

    if (data['app_logo'] != null) {
      payload['app_logo'] = data['app_logo'];
    }

    return payload;
  }

  static String _toDisplayStatus(String rawValue) {
    final normalized =
        rawValue.toLowerCase().trim().replaceAll(RegExp(r'[\s-]+'), '_');

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
      case 'declined':
      case 'cancelled':
      case 'rejected':
        return 'Rejected';
      default:
        final value = rawValue.replaceAll('_', ' ').trim();
        return value.isEmpty ? 'Preparing' : value;
    }
  }
}
