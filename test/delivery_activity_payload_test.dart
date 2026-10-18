import 'dart:convert';

import 'package:faskhaninja/helpers/delivery_activity/delivery_activity_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('delivery activity wire formats', () {
    test('FCM JSON data and its content-state retain order identity', () {
      final payload = <String, dynamic>{
        'message': 'Your order is on its way',
        'data': jsonEncode({
          'notification_type': 'live_activity',
          'content-state': jsonEncode({
            'order_id': 652,
            'order_no': 'F-1045',
            'orderStatus': 'picked_up',
          }),
        }),
      };

      expect(DeliveryActivityPayload.isLiveActivity(payload), isTrue);
      expect(DeliveryActivityPayload.orderId(payload), '652');
      expect(DeliveryActivityPayload.orderNo(payload), 'F-1045');
      expect(DeliveryActivityPayload.activityId(payload), 'order_652');
      expect(DeliveryActivityPayload.status(payload), 'picked_up');
      expect(DeliveryActivityPayload.data(payload, null), {
        'order_id': '652',
        'orderId': '652',
        'order_no': 'F-1045',
        'orderNo': 'F-1045',
        'order_status': 'On the Way',
        'orderStatus': 'On the Way',
      });
    });

    test('APNs content-state overrides stale outer values without mutation', () {
      final payload = <String, dynamic>{
        'order_status': 'pending',
        'order_id': 652,
        'aps': {
          'event': 'end',
          'content-state': {
            'orderStatus': 'completed',
            'order_status': 'completed',
            'order_no': 1045,
          },
        },
      };

      final extracted = DeliveryActivityPayload.extract(payload);
      expect(extracted['order_status'], 'completed');
      expect(DeliveryActivityPayload.status(payload), 'completed');
      expect(DeliveryActivityPayload.isTerminal(
        DeliveryActivityPayload.status(payload),
      ), isTrue);
      expect(DeliveryActivityPayload.orderNo(payload), '1045');
      expect(payload['order_status'], 'pending');
      expect(payload.containsKey('order_no'), isFalse);
    });

    test('APNs envelope and content-state may both be JSON strings', () {
      final payload = <String, dynamic>{
        'aps': jsonEncode({
          'content-state': jsonEncode({
            'order': {'id': 652, 'order_no': '1045', 'status': 'delivered'},
          }),
        }),
      };

      expect(DeliveryActivityPayload.orderId(payload), '652');
      expect(DeliveryActivityPayload.orderNo(payload), '1045');
      expect(DeliveryActivityPayload.status(payload), 'delivered');
      expect(DeliveryActivityPayload.isLiveActivity(payload), isTrue);
    });

    test('malformed optional JSON does not discard valid outer fields', () {
      final payload = <String, dynamic>{
        'order_id': 652,
        'order_state': 'delivering',
        'data': '{invalid',
        'content-state': '[]',
        'aps': {'content-state': 'not-json'},
      };

      expect(DeliveryActivityPayload.activityId(payload), 'order_652');
      expect(DeliveryActivityPayload.status(payload), 'delivering');
      expect(DeliveryActivityPayload.data(payload, null)['orderStatus'],
          'On the Way');
    });
  });

  group('immutable identity and public order number', () {
    test('changing public number never changes the activity identifier', () {
      final before = <String, dynamic>{'id': 652, 'order_no': 1045};
      final after = <String, dynamic>{'id': 652, 'order_no': 2045};

      expect(DeliveryActivityPayload.activityId(before), 'order_652');
      expect(DeliveryActivityPayload.activityId(after), 'order_652');
      expect(DeliveryActivityPayload.orderNo(before), '1045');
      expect(DeliveryActivityPayload.orderNo(after), '2045');
    });

    test('a database identifier is never invented as the public number', () {
      final payload = <String, dynamic>{'order_id': 652};

      expect(DeliveryActivityPayload.orderNo(payload), isNull);
      expect(DeliveryActivityPayload.data(payload, 'accepted'), {
        'order_id': '652',
        'orderId': '652',
        'order_status': 'Preparing',
        'orderStatus': 'Preparing',
      });
      expect(DeliveryActivityPayload.activityId({'order_no': 1045}), isNull);
    });

    test('legacy order_id object resolves its id without stringifying a map', () {
      final payload = <String, dynamic>{
        'id': 'notification-42',
        'order_id': {'id': 652, 'order_no': 1045},
      };

      expect(DeliveryActivityPayload.orderId(payload), '652');
      expect(DeliveryActivityPayload.orderNo(payload), '1045');
      expect(DeliveryActivityPayload.activityId(payload), 'order_652');
      expect(DeliveryActivityPayload.activityIdForOrderId({'id': 652}), '');
    });

    test('JSON order_id object keeps its immutable id and public number', () {
      final payload = <String, dynamic>{
        'order_id': jsonEncode({'id': 652, 'order_no': 1045}),
      };

      expect(DeliveryActivityPayload.orderId(payload), '652');
      expect(DeliveryActivityPayload.orderNo(payload), '1045');
    });

    test('explicit activity identifiers win over generated identifiers', () {
      for (final key in [
        'activity-id',
        'activity_id',
        'activityId',
        'live_activity_id',
        'liveActivityId',
      ]) {
        expect(DeliveryActivityPayload.activityId({
          key: 'native-activity-uuid',
          'order_id': 652,
        }), 'native-activity-uuid');
      }
      expect(DeliveryActivityPayload.activityIdForOrderId(' 652 '), 'order_652');
      expect(DeliveryActivityPayload.activityIdForOrderId(null), '');
      expect(DeliveryActivityPayload.activityIdForOrderId(' '), '');
    });
  });

  group('lifecycle states', () {
    test('projected status wins over legacy accepted notification status', () {
      final notification = <String, dynamic>{
        'order_id': '7375',
        'order_status': 'accepted',
        'live_activity_status': 'On the Way',
        'tracking_status': 'shipped',
      };

      expect(DeliveryActivityPayload.status(notification), 'On the Way');
      expect(DeliveryActivityPayload.data(notification, null)['order_status'],
          'On the Way');
      expect(DeliveryActivityPayload.status({
        'status': 'accepted',
        'tracking_status': 'shipped',
      }), 'shipped');
    });

    test('branch courier API snapshot resolves accepted as on the way', () {
      final snapshot = <String, dynamic>{
        'id': 7375,
        'order_no': 'R363-16897',
        'status': 'accepted',
        'delegate_from_out': 'in_resturant',
      };

      expect(DeliveryActivityPayload.status(snapshot), 'On the Way');
      expect(DeliveryActivityPayload.status({'order': snapshot}), 'On the Way');
      expect(DeliveryActivityPayload.status({
        ...snapshot,
        'delegate_from_out': 'out_resturant',
      }), 'accepted');
      expect(DeliveryActivityPayload.status({
        ...snapshot,
        'status': 'completed',
      }), 'completed');
      expect(DeliveryActivityPayload.status({
        'order': {...snapshot, 'live_activity_status': 'Delivered'},
      }), 'Delivered');
    });

    test('every terminal backend alias ends the activity', () {
      for (final status in [
        'ended',
        'delivered',
        'completed',
        'cancelled',
        'canceled',
        'declined',
        'rejected',
        'failed',
        'payment_failed',
        ' Payment-Failed ',
      ]) {
        expect(DeliveryActivityPayload.isTerminal(status), isTrue,
            reason: status);
      }
      for (final status in [null, '', 'pending', 'preparing', 'on_the_way']) {
        expect(DeliveryActivityPayload.isTerminal(status), isFalse,
            reason: '$status');
      }
    });

    test('known backend states render the same labels in every push path', () {
      const expected = {
        'pending': 'Preparing',
        'new_order': 'Preparing',
        'accepted': 'Preparing',
        'preparing': 'Preparing',
        'in_preparation': 'Preparing',
        'picked_up': 'On the Way',
        'on_the_way': 'On the Way',
        'out_for_delivery': 'On the Way',
        'shipped': 'On the Way',
        'delivering': 'On the Way',
        'delivered': 'Delivered',
        'completed': 'Delivered',
        'cancelled': 'Cancelled',
        'canceled': 'Cancelled',
        'declined': 'Cancelled',
        'rejected': 'Cancelled',
        'failed': 'Cancelled',
        'payment_failed': 'Cancelled',
      };
      for (final entry in expected.entries) {
        expect(DeliveryActivityPayload.displayStatus(entry.key), entry.value);
      }
      expect(DeliveryActivityPayload.displayStatus(' On-the-way '), 'On the Way');
    });

    test('status aliases and nested order status are accepted', () {
      for (final key in [
        'order_status',
        'orderStatus',
        'order_state',
        'orderState',
        'status',
      ]) {
        expect(DeliveryActivityPayload.status({key: ' completed '}), 'completed');
      }
      expect(DeliveryActivityPayload.status({
        'order': {'status': 'delivered'},
      }), 'delivered');
    });
  });

  group('notification routing', () {
    test('ordinary status-only chat cannot update unrelated order activities', () {
      expect(DeliveryActivityPayload.isLiveActivity({
        'status': 'delivered',
        'title': 'Message delivered',
        'message': 'Hello',
      }), isFalse);
      expect(DeliveryActivityPayload.isLiveActivity({
        'notification_type': 'chat',
        'status': 'delivered',
        'conversation_id': 42,
      }), isFalse);
      expect(DeliveryActivityPayload.isLiveActivity({'order_no': 1045}), isFalse);
    });

    test('explicit live markers or order identity with status are accepted', () {
      for (final marker in [true, 1, '1', 'true', 'TRUE']) {
        expect(DeliveryActivityPayload.isLiveActivity({'live_activity': marker}),
            isTrue);
      }
      expect(DeliveryActivityPayload.isLiveActivity({
        'notification_type': 'live_activity',
      }), isTrue);
      expect(DeliveryActivityPayload.isLiveActivity({
        'order_id': 652,
        'order_status': 'completed',
      }), isTrue);
      expect(DeliveryActivityPayload.isLiveActivity({
        'activity_id': 'native-uuid',
        'status': 'completed',
      }), isTrue);
      expect(DeliveryActivityPayload.isLiveActivity({'activity_id': 'native-uuid'}),
          isFalse);
    });

    test('optional restaurant and logo data survive normalization', () {
      expect(DeliveryActivityPayload.data({
        'orderId': '652',
        'orderNo': '1045',
        'restaurant_name': 'Fasakhansta',
        'app_logo': 'logo.png',
      }, 'accepted'), {
        'order_id': '652',
        'orderId': '652',
        'order_no': '1045',
        'orderNo': '1045',
        'order_status': 'Preparing',
        'orderStatus': 'Preparing',
        'restaurant_name': 'Fasakhansta',
        'restaurantName': 'Fasakhansta',
        'app_logo': 'logo.png',
      });
    });
  });

  group('out-of-order delivery updates', () {
    final before = DateTime.utc(2026, 10, 18, 17);
    final after = DateTime.utc(2026, 10, 18, 17, 1);

    test('delayed preparing cannot replace on-the-way or delivered', () {
      for (final current in ['on_the_way', 'delivered']) {
        expect(DeliveryActivityPayload.shouldApply(
          currentStatus: current,
          currentTimestamp: after,
          nextStatus: 'preparing',
          nextTimestamp: before,
        ), isFalse);
        expect(DeliveryActivityPayload.shouldApply(
          currentStatus: current,
          currentTimestamp: after,
          nextStatus: 'preparing',
          nextTimestamp: null,
        ), isFalse);
      }
    });

    test('an authoritative newer timestamp permits an owner undo', () {
      expect(DeliveryActivityPayload.shouldApply(
        currentStatus: 'delivered',
        currentTimestamp: before,
        nextStatus: 'preparing',
        nextTimestamp: after,
      ), isTrue);
    });

    test('equal timestamps permit progress and reject backwards states', () {
      expect(DeliveryActivityPayload.shouldApply(
        currentStatus: 'preparing',
        currentTimestamp: after,
        nextStatus: 'on_the_way',
        nextTimestamp: after,
      ), isTrue);
      expect(DeliveryActivityPayload.shouldApply(
        currentStatus: 'on_the_way',
        currentTimestamp: after,
        nextStatus: 'preparing',
        nextTimestamp: after,
      ), isFalse);
    });

    test('missing timestamps allow progress and corrections between end states', () {
      expect(DeliveryActivityPayload.shouldApply(
        currentStatus: 'accepted',
        currentTimestamp: null,
        nextStatus: 'delivered',
        nextTimestamp: null,
      ), isTrue);
      expect(DeliveryActivityPayload.shouldApply(
        currentStatus: 'completed',
        currentTimestamp: null,
        nextStatus: 'payment_failed',
        nextTimestamp: null,
      ), isTrue);
    });

    test('an older update is rejected even when its status has advanced', () {
      expect(DeliveryActivityPayload.shouldApply(
        currentStatus: 'preparing',
        currentTimestamp: after,
        nextStatus: 'completed',
        nextTimestamp: before,
      ), isFalse);
    });

    test('timestamps support epoch seconds, millis, numeric strings and ISO', () {
      final epochSeconds = after.millisecondsSinceEpoch / 1000;
      for (final value in [
        epochSeconds,
        after.millisecondsSinceEpoch,
        epochSeconds.toString(),
        after.millisecondsSinceEpoch.toString(),
        after.toIso8601String(),
        '2026-10-18T20:01:00+03:00',
      ]) {
        expect(DeliveryActivityPayload.statusTimestamp({'timestamp': value}),
            after, reason: '$value');
      }
    });

    test('all timestamp aliases work including nested order and FCM envelopes', () {
      for (final key in [
        'timestamp',
        'updateId',
        'status_updated_at',
        'updated_at',
        'updatedAt',
      ]) {
        expect(DeliveryActivityPayload.statusTimestamp({
          'data': jsonEncode({key: after.toIso8601String()}),
        }), after, reason: key);
      }
      expect(DeliveryActivityPayload.statusTimestamp({
        'order': {'updated_at': after.toIso8601String()},
      }), after);
    });

    test('malformed timestamps are ignored and a valid later alias survives', () {
      expect(DeliveryActivityPayload.statusTimestamp({
        'timestamp': 'not-a-date',
        'updateId': {'value': 1},
        'status_updated_at': false,
        'updated_at': after.toIso8601String(),
      }), after);
      for (final value in [null, '', 'not-a-date', double.nan, double.infinity]) {
        expect(DeliveryActivityPayload.statusTimestamp({'timestamp': value}),
            isNull);
      }
    });

    test('native payload preserves the status timestamp in UTC', () {
      final payload = DeliveryActivityPayload.data({
        'order_id': 652,
        'order_status': 'on_the_way',
        'status_updated_at': '2026-10-18T20:01:00+03:00',
      }, null);

      expect(payload['updated_at'], after.toIso8601String());
      expect(DeliveryActivityPayload.data({'order_id': 652}, null)
          .containsKey('updated_at'), isFalse);
    });
  });
}
