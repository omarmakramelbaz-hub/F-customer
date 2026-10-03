import 'package:flutter/material.dart';

import '../translation/all_translation.dart';

String formatRestaurantOpeningTime(
  BuildContext context,
  String? rawTime,
) {
  final raw = (rawTime ?? '').trim();
  if (raw.isEmpty) return '';

  int? hour;
  int? minute;

  final timeOnly = raw.contains('T')
      ? raw.split('T').last
      : raw.contains(' ')
          ? raw.split(' ').last
          : raw;

  final parts = timeOnly.split(':');
  if (parts.length >= 2) {
    hour = int.tryParse(parts[0]);
    minute = int.tryParse(parts[1]);
  }

  if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return raw;
  }

  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: hour, minute: minute),
    alwaysUse24HourFormat: false,
  );
}

String restaurantClosedLabel(
  BuildContext context,
  String? openAt,
) {
  final opening = formatRestaurantOpeningTime(context, openAt);
  if (opening.isEmpty) return 'closed'.tr;

  return 'closedOpensAt'.tr.replaceAll('{}', opening);
}

String restaurantOrderingUnavailableLabel(
  BuildContext context, {
  required String? status,
  String? openAt,
}) {
  if (status == 'busy') {
    return 'restaurantClosedOrBusy'.tr;
  }

  final closedLabel = restaurantClosedLabel(context, openAt);
  return '$closedLabel\nundefined';
}
