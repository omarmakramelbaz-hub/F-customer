part of 'notification_helper.dart';

FirebaseMessaging? _firebaseMessaging;
bool _didPrintFirstNotificationPayload = false;

String _safeJsonEncode(Object? value) {
  try {
    return jsonEncode(value);
  } catch (_) {
    return value.toString();
  }
}

void _traceImmediateFcmReceipt(
  RemoteMessage message, {
  required String source,
}) {
  final now = DateTime.now().toIso8601String();
  final marker = 'FCM_RECEIVED_IMMEDIATE source=$source messageId=${message.messageId ?? '-'} at=$now';
  log(marker);
  debugPrint(marker);
}

void _printNotificationPayload(
  RemoteMessage message, {
  required String source,
}) {
  final payload = <String, dynamic>{
    'source': source,
    'messageId': message.messageId,
    'from': message.from,
    'sentTime': message.sentTime?.toIso8601String(),
    'collapseKey': message.collapseKey,
    'category': message.category,
    'threadId': message.threadId,
    'dataKeys': message.data.keys.toList()..sort(),
  };

  final encoded = _safeJsonEncode(payload);
  log('NOTIFICATION_METADATA => $encoded');
  // Keep a plain print so it is obvious in Xcode/Android logs.
  debugPrint('NOTIFICATION_METADATA => $encoded');
}

void _printFirstNotificationPayload(RemoteMessage message, {required String source}) {
  if (_didPrintFirstNotificationPayload) {
    return;
  }
  _didPrintFirstNotificationPayload = true;
  final marker = 'FIRST_NOTIFICATION_PAYLOAD source=$source';
  log(marker);
  debugPrint(marker);
  _printNotificationPayload(message, source: source);
}

class FirebaseNotifications {
  static FirebaseNotifications? _instance;

  FirebaseNotifications._internal();

  factory FirebaseNotifications() {
    _instance ??= FirebaseNotifications._internal();
    return _instance!;
  }

  static Future<void> setUpFirebase() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _firebaseMessaging = FirebaseMessaging.instance;
    await _firebaseMessaging!.setAutoInitEnabled(true);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    localNotification();
    await firebaseCloudMessagingListeners();
  }

  static String? fcmToken;

  static Future<String?> _waitForApnsToken({
    Duration timeout = const Duration(seconds: 12),
    Duration pollInterval = const Duration(milliseconds: 500),
  }) async {
    if (!Platform.isIOS) return null;
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      try {
        final token = await _firebaseMessaging?.getAPNSToken();
        if (token != null && token.isNotEmpty) {
          return token;
        }
      } catch (e) {
        log('Waiting for APNS token error: $e');
      }
      await Future<void>.delayed(pollInterval);
    }
    return null;
  }

  static Future<void> getToken() async {
    String? deviceToken;
    log('-----------Device Token--------------');
    try {
      if (Platform.isIOS) {
        final apnsToken = await _waitForApnsToken();
        if (apnsToken == null || apnsToken.isEmpty) {
          log('APNS token is not available yet (simulator often has this).');
        }
      }

      for (var i = 0; i < 6; i++) {
        deviceToken = await _firebaseMessaging?.getToken();
        if (deviceToken != null && deviceToken.isNotEmpty) {
          break;
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      log('Error getting device token $e');
      deviceToken = null;
      log('_deviceToken : Device Token Null');
    }
    fcmToken = deviceToken;
  }

  static Future<void> firebaseCloudMessagingListeners() async {
    if (Platform.isIOS) {
      final settings = await iOSPermission();
      log('iOS permission status => ${settings.authorizationStatus}');
    }
    await getToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      fcmToken = token;
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage data) async {
      _traceImmediateFcmReceipt(
        data,
        source: 'onMessage',
      );
      _printFirstNotificationPayload(
        data,
        source: 'onMessage',
      );
      _printNotificationPayload(
        data,
        source: 'onMessage',
      );
      final notify = Map<String, dynamic>.from(data.data);

      final isLiveActivityPayload = DeliveryActivityPushHandler.isLiveActivityPayload(notify);
      log('onMessage isLiveActivityPayload=$isLiveActivityPayload');

      await DeliveryActivityPushHandler.handlePushData(notify);
      log('onMessage handlePushData completed');

      if (!isLiveActivityPayload && Platform.isAndroid && data.notification != null) {
        scheduleNotification(data.notification!.title ?? '', data.notification!.body ?? '', json.encode(notify));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage data) async {
      _traceImmediateFcmReceipt(
        data,
        source: 'onMessageOpenedApp',
      );
      _printFirstNotificationPayload(
        data,
        source: 'onMessageOpenedApp',
      );
      _printNotificationPayload(
        data,
        source: 'onMessageOpenedApp',
      );
      final notify = Map<String, dynamic>.from(data.data);
      final isLiveActivityPayload = DeliveryActivityPushHandler.isLiveActivityPayload(notify);
      log('onMessageOpenedApp isLiveActivityPayload=$isLiveActivityPayload');
      await DeliveryActivityPushHandler.handlePushData(notify);
      log('onMessageOpenedApp handlePushData completed');

      if (isLiveActivityPayload) {
        return;
      }

      NotificationResponse response = NotificationResponse(
        id: 0,
        payload: json.encode(notify),
        notificationResponseType: NotificationResponseType.selectedNotification,
      );
      handlePath(response);
    });

    FirebaseMessaging.instance.getInitialMessage().then((value) async {
      if (value != null) {
        _traceImmediateFcmReceipt(
          value,
          source: 'getInitialMessage',
        );
        _printFirstNotificationPayload(
          value,
          source: 'getInitialMessage',
        );
        _printNotificationPayload(
          value,
          source: 'getInitialMessage',
        );
        await DeliveryActivityPushHandler.handlePushData(
          Map<String, dynamic>.from(value.data),
        );
        log('getInitialMessage handlePushData completed');
      }
    });

    _notificationsPlugin!.getActiveNotifications().then((value) {
      if (value.isNotEmpty) {
        if (value[0].payload != null && value[0].payload != '') {
          handlePath(json.decode(value[0].payload!));
        }
      }
    });

    _notificationsPlugin!.getNotificationAppLaunchDetails().then((NotificationAppLaunchDetails? data) {
      final payload = data?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        handlePath(json.decode(payload));
      }
    });
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('FIREBASE INIT');
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _traceImmediateFcmReceipt(message, source: 'onBackgroundMessage');
  _printFirstNotificationPayload(message, source: 'onBackgroundMessage');
  _printNotificationPayload(message, source: 'onBackgroundMessage');
  await DeliveryActivityPushHandler.handlePushData(Map<String, dynamic>.from(message.data));
  log('onBackgroundMessage handlePushData completed');
}
