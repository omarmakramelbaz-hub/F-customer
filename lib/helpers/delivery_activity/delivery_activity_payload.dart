import 'dart:convert';

/// The shared wire format used by foreground and background activity updates.
///
/// [orderId] identifies the database order and the activity. [orderNo] is the
/// public number printed in the dashboard and shown to the customer.
class DeliveryActivityPayload {
  static Map<String, dynamic> extract(Map<String, dynamic> payload) {
    return _extract(payload, 0);
  }

  static Map<String, dynamic> _extract(
    Map<String, dynamic> payload,
    int depth,
  ) {
    final result = Map<String, dynamic>.from(payload);
    if (depth >= 8) return result;

    final nestedData = _map(payload['data']);
    if (nestedData != null) {
      result.addAll(_extract(nestedData, depth + 1));
    }

    final contentState = _map(payload['content-state']);
    if (contentState != null) {
      result.addAll(_extract(contentState, depth + 1));
    }

    final aps = _map(payload['aps']);
    final apsContentState = _map(aps?['content-state']);
    if (apsContentState != null) {
      result.addAll(_extract(apsContentState, depth + 1));
    }

    return result;
  }

  static String? orderId(Map<String, dynamic> payload) {
    final values = extract(payload);
    final order = _map(values['order']);
    final nestedOrderId = _map(values['order_id']);
    return _firstValue([
      if (nestedOrderId == null) values['order_id'],
      values['orderId'],
      nestedOrderId?['id'],
      values['id'],
      order?['id'],
      order?['order_id'],
      order?['orderId'],
    ]);
  }

  static String? orderNo(Map<String, dynamic> payload) {
    final values = extract(payload);
    final order = _map(values['order']);
    final nestedOrderId = _map(values['order_id']);
    return _firstValue([
      values['order_no'],
      values['orderNo'],
      values['order_number'],
      order?['order_no'],
      order?['orderNo'],
      order?['order_number'],
      nestedOrderId?['order_no'],
      nestedOrderId?['orderNo'],
      nestedOrderId?['order_number'],
    ]);
  }

  static String activityIdForOrderId(dynamic value) {
    final id = _value(value);
    return id == null ? '' : 'order_$id';
  }

  static String? activityId(Map<String, dynamic> payload) {
    final values = extract(payload);
    final explicit = _firstValue([
      values['activity-id'],
      values['activity_id'],
      values['activityId'],
      values['live_activity_id'],
      values['liveActivityId'],
    ]);
    if (explicit != null) return explicit;

    final generated = activityIdForOrderId(orderId(values));
    return generated.isEmpty ? null : generated;
  }

  static String? status(Map<String, dynamic> payload) {
    final values = extract(payload);
    final order = _map(values['order']);
    final projected = _firstValue([
      values['live_activity_status'],
      values['tracking_status'],
      order?['live_activity_status'],
      order?['tracking_status'],
    ]);
    if (projected != null) return projected;

    final raw = _firstValue([
      values['order_status'],
      values['orderStatus'],
      values['order_state'],
      values['orderState'],
      values['status'],
      order?['status'],
      order?['order_status'],
      order?['orderStatus'],
      order?['order_state'],
      order?['orderState'],
    ]);
    final courierSource = _firstValue([
      values['delegate_from_out'],
      order?['delegate_from_out'],
    ]);
    // The existing API keeps branch-courier dispatch as accepted. The delivery
    // marker distinguishes dispatch from preparing without changing API status.
    if (raw != null && normalizedStatus(raw) == 'accepted' &&
        courierSource == 'in_resturant') return 'On the Way';
    return raw;
  }

  static String normalizedStatus(String value) {
    return value.toLowerCase().trim().replaceAll(RegExp(r'[\s-]+'), '_');
  }

  static DateTime? statusTimestamp(Map<String, dynamic> payload) {
    final values = extract(payload);
    final order = _map(values['order']);
    for (final value in [
      values['updateId'],
      values['status_updated_at'],
      values['updated_at'],
      values['updatedAt'],
      values['timestamp'],
      order?['updated_at'],
    ]) {
      final timestamp = _timestamp(value);
      if (timestamp != null) return timestamp;
    }
    return null;
  }

  /// A delayed push must not regress a newer local or polled order state.
  /// A timestamped, newer server update can still represent an owner undo.
  static bool shouldApply({
    required String currentStatus,
    required DateTime? currentTimestamp,
    required String nextStatus,
    required DateTime? nextTimestamp,
  }) {
    if (currentTimestamp != null && nextTimestamp != null) {
      if (nextTimestamp.isBefore(currentTimestamp)) return false;
      if (nextTimestamp.isAfter(currentTimestamp)) return true;
    }
    return _progressRank(nextStatus) >= _progressRank(currentStatus);
  }

  static int _progressRank(String value) {
    if (isTerminal(value)) return 2;
    if (displayStatus(value) == 'On the Way') return 1;
    return 0;
  }

  static String displayStatus(String value) {
    switch (normalizedStatus(value)) {
      case 'pending':
      case 'new_order':
      case 'accepted':
      case 'preparing':
      case 'in_preparation':
        return 'Preparing';
      case 'picked_up':
      case 'on_the_way':
      case 'out_for_delivery':
      case 'shipped':
      case 'delivering':
        return 'On the Way';
      case 'delivered':
      case 'completed':
        return 'Delivered';
      case 'cancelled':
      case 'canceled':
      case 'declined':
      case 'rejected':
      case 'failed':
      case 'payment_failed':
        return 'Cancelled';
      default:
        final display = value.replaceAll('_', ' ').trim();
        return display.isEmpty ? 'Preparing' : display;
    }
  }

  static bool isTerminal(String? value) {
    if (value == null) return false;
    return const {
      'ended',
      'delivered',
      'completed',
      'cancelled',
      'canceled',
      'declined',
      'rejected',
      'failed',
      'payment_failed',
    }.contains(normalizedStatus(value));
  }

  static bool isLiveActivity(Map<String, dynamic> payload) {
    final values = extract(payload);
    final notificationType =
        _value(values['notification_type'])?.toLowerCase();
    final marker = _value(values['live_activity'])?.toLowerCase();
    final explicitlyMarked = values['live_activity'] == true ||
        marker == '1' ||
        marker == 'true' ||
        notificationType == 'live_activity';

    return explicitlyMarked ||
        (status(values) != null && activityId(values) != null);
  }

  static Map<String, dynamic> data(
    Map<String, dynamic> payload,
    String? rawStatus,
  ) {
    final values = extract(payload);
    final display = displayStatus(rawStatus ?? status(values) ?? 'Preparing');
    final result = <String, dynamic>{
      'order_status': display,
      'orderStatus': display,
    };

    final id = orderId(values);
    if (id != null) {
      result['order_id'] = id;
      result['orderId'] = id;
    }

    final number = orderNo(values);
    if (number != null) {
      result['order_no'] = number;
      result['orderNo'] = number;
    }

    final restaurant = _firstValue([
      values['restaurantName'],
      values['restaurant_name'],
      values['restaurant'],
    ]);
    if (restaurant != null) {
      result['restaurantName'] = restaurant;
      result['restaurant_name'] = restaurant;
    }
    if (values['app_logo'] != null) {
      result['app_logo'] = values['app_logo'];
    }

    final updatedAt = statusTimestamp(values);
    if (updatedAt != null) {
      result['updated_at'] = updatedAt.toUtc().toIso8601String();
    }

    return result;
  }

  static Map<String, dynamic>? _map(dynamic value) {
    if (value is String) {
      if (value.trim().isEmpty) return null;
      try {
        value = jsonDecode(value);
      } on FormatException {
        return null;
      }
    }
    if (value is! Map) return null;
    return {
      for (final entry in value.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
  }

  static String? _firstValue(List<dynamic> values) {
    for (final value in values) {
      final candidate = _value(value);
      if (candidate != null) return candidate;
    }
    return null;
  }

  static String? _value(dynamic value) {
    if (value is! String && value is! num) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _timestamp(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      final number = num.tryParse(text);
      if (number != null) return _timestamp(number);
      return DateTime.tryParse(text)?.toUtc();
    }
    if (value is! num || !value.isFinite) return null;
    try {
      // Server timestamps use Unix seconds; mobile updateId may use millis.
      final milliseconds = value.abs() >= 100000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds.round(),
        isUtc: true,
      );
    } on ArgumentError {
      return null;
    } on UnsupportedError {
      return null;
    }
  }
}
