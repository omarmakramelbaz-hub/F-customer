import 'dart:io';

import 'package:flutter/services.dart';

/// Keeps ActivityKit's typed content in step with the plugin's shared defaults.
class DeliveryActivityNative {
  static const MethodChannel _channel = MethodChannel('fasakhansta/live_activity');

  static Future<void> sync(Map<String, dynamic> data) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<bool>('syncOrderState', data);
    } on MissingPluginException {
      // Older app shells can still use the plugin's local update path.
    } on PlatformException {
      // A concurrent OS dismissal must not interrupt customer navigation.
    }
  }
}
