import 'dart:developer';
import 'dart:io';

import 'package:live_activities/live_activities.dart';

import 'delivery_activity_native.dart';
import 'delivery_activity_payload.dart';

class DeliveryActivityPushHandler {
  static final LiveActivities _liveActivities = LiveActivities();
  static const String _appGroupId = 'group.faskhaninja.liveactivities';

  static Future<void> handlePushData(Map<String, dynamic> payload) async {
    final data = DeliveryActivityPayload.extract(payload);
    if (!DeliveryActivityPayload.isLiveActivity(data)) return;
    final status = DeliveryActivityPayload.status(data);
    if (status == null) return;

    // Never apply an order update to every activity on the device.
    final activityId = DeliveryActivityPayload.activityId(data);
    if (activityId == null) return;

    try {
      if (!await _liveActivities.areActivitiesSupported()) return;
      await _liveActivities.init(
        appGroupId: _appGroupId,
        urlScheme: Platform.isIOS ? 'la' : null,
        requestAndroidNotificationPermission: false,
      );
      if (Platform.isIOS) {
        await DeliveryActivityNative.sync(DeliveryActivityPayload.data(data, status));
        return;
      }
      final ids = await _liveActivities.getAllActivitiesIds();
      if (!ids.contains(activityId)) return;

      if (DeliveryActivityPayload.isTerminal(status)) {
        await DeliveryActivityNative.sync({...data, 'order_status': status});
        await _liveActivities.endActivity(activityId);
      } else {
        final activityData = DeliveryActivityPayload.data(data, status);
        await _liveActivities.updateActivity(activityId, activityData);
        await DeliveryActivityNative.sync(activityData);
      }
    } catch (error, stack) {
      log('Live Activity push handling failed: $error', stackTrace: stack);
    }
  }

  static bool isLiveActivityPayload(Map<String, dynamic> payload) =>
      DeliveryActivityPayload.isLiveActivity(DeliveryActivityPayload.extract(payload));

  static String activityIdForOrderId(dynamic orderId) =>
      DeliveryActivityPayload.activityIdForOrderId(orderId);
}
