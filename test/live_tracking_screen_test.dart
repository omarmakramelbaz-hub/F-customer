import 'dart:async';

import 'package:faskhaninja/helpers/delivery_activity/delivery_provider.dart';
import 'package:faskhaninja/helpers/networking/api_helper.dart';
import 'package:faskhaninja/helpers/pusher_service/pusher_controller.dart';
import 'package:faskhaninja/view/layout/auth/controller/auth_controller.dart';
import 'package:faskhaninja/view/layout/auth/model/profile_model.dart';
import 'package:faskhaninja/view/layout/orders/controller/orders_controller.dart';
import 'package:faskhaninja/view/layout/orders/screen/tracking_your_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

ApiResponse _details(int id, String status,
        {Map<String, Object?> extra = const {}}) =>
    ApiResponse(
      state: ResponseState.complete,
      data: {
        'data': {
          'id': id,
          'order_no': 'TEST-$id',
          'status': status,
          'resturant_name': 'فرع الاختبار',
          'payment_type': 'cash',
          'total_item_price': 60,
          'delivery_price': 20,
          'tax': 0,
          'service_fees': 0,
          'grand_total': 80,
          'items': [],
          ...extra,
        },
      },
    );

class _TrackingAuth extends AuthController {
  num _balance = 100;

  @override
  ProfileModel get profile => ProfileModel(id: 9001, balance: _balance);

  void setBalance(num balance) {
    _balance = balance;
    notifyListeners();
  }
}

class _TrackingPusher extends PusherController {
  final _listeners = <String, List<void Function(PusherEvent)>>{};

  int get listenerCount =>
      _listeners.values.fold(0, (count, listeners) => count + listeners.length);

  @override
  void addEventListener(String eventName, void Function(PusherEvent) listener) {
    (_listeners[eventName] ??= []).add(listener);
  }

  @override
  void removeEventListener(
      String eventName, void Function(PusherEvent) listener) {
    _listeners[eventName]?.remove(listener);
  }

  void emit(int id) {
    final event = PusherEvent(
      channelName: 'synthetic-tracking-channel',
      eventName: 'user.updated',
      data: '{"order_id":{"id":$id}}',
    );
    for (final listener in [...?_listeners['user.updated']]) {
      listener(event);
    }
  }
}

class _TrackingVideoPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}
  @override
  Future<int> createWithOptions(VideoCreationOptions options) async => 1;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => Stream.value(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 6),
          size: const Size(360, 640),
        ),
      );
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<void> setAllowBackgroundPlayback(bool allowBackgroundPlayback) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.expand();
}

class _TrackingActivity extends DeliveryProvider {
  final stages = <String>[];
  @override
  Future<void> syncOrder(
      {required int id,
      required String status,
      String? restaurantName,
      String? updatedAt}) async {
    stages.add('$id:$status');
  }
}

class _TrackingHarness {
  final activity = _TrackingActivity();
  final navigator = GlobalKey<NavigatorState>();
  final auth = _TrackingAuth();
  final pusher = _TrackingPusher();
  int detailRequests = 0;
  String status = 'accepted';
  Future<ApiResponse> Function(int id)? nextDetails;
  late final orders = OrdersController(
    detailsLoader: (id) {
      detailRequests++;
      return nextDetails?.call(id) ?? Future.value(_details(id, status));
    },
  );

  Future<void> mount(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    final previousVideoPlatform = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _TrackingVideoPlatform();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      VideoPlayerPlatform.instance = previousVideoPlatform;
      await tester.binding.setSurfaceSize(null);
      orders.dispose();
      auth.dispose();
      pusher.dispose();
      activity.dispose();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OrdersController>.value(value: orders),
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<PusherController>.value(value: pusher),
          ChangeNotifierProvider<DeliveryProvider>.value(value: activity),
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: TrackingYourOrderScreen(
            args: TrackingYourOrderArgs(id: 501),
            settingsLoader: () async => ApiResponse(
              state: ResponseState.complete,
              data: {'data': <String, dynamic>{}},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('real tracking screen applies matching Pusher status changes', (
    tester,
  ) async {
    final harness = _TrackingHarness();
    await harness.mount(tester);
    expect(find.text('طلبك بيتجهّز'), findsOneWidget);
    final initialRequests = harness.detailRequests;
    expect(harness.activity.stages.last, '501:accepted');

    harness.status = 'shipped';
    harness.pusher.emit(999);
    await tester.pumpAndSettle();
    expect(harness.detailRequests, initialRequests);
    expect(find.text('طلبك بيتجهّز'), findsOneWidget);

    harness.pusher.emit(501);
    await tester.pumpAndSettle();
    expect(harness.detailRequests, greaterThan(initialRequests));
    expect(find.text('طلبك في الطريق'), findsOneWidget);
    expect(harness.activity.stages.last, '501:shipped');
    expect(find.text('طلبك بيتجهّز'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'refresh keeps confirmed tracking visible through loading and error',
      (tester) async {
    final harness = _TrackingHarness();
    await harness.mount(tester);
    final pending = Completer<ApiResponse>();
    harness.nextDetails = (_) => pending.future;

    harness.pusher.emit(501);
    await tester.pump();
    expect(find.text('طلبك بيتجهّز'), findsOneWidget);
    expect(find.text('بنحمّل تفاصيل طلبك'), findsNothing);
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('tracking-refresh')))
          .onPressed,
      isNull,
    );

    pending.complete(ApiResponse(state: ResponseState.offline, data: null));
    await tester.pumpAndSettle();
    expect(find.text('طلبك بيتجهّز'), findsOneWidget);
    expect(
      find.text('تعذّر تحديث الطلب. تفاصيل طلبك الأخيرة ما زالت ظاهرة.'),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey('tracking-refresh-retry')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'tracking stops hidden and disposed polling and resumes on return',
      (tester) async {
    final harness = _TrackingHarness();
    await harness.mount(tester);
    unawaited(harness.navigator.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('tracking-cover-route')),
      ),
    ));
    await tester.pumpAndSettle();
    final coveredRequests = harness.detailRequests;

    harness.status = 'shipped';
    harness.pusher.emit(501);
    await tester.pump(const Duration(seconds: 31));
    expect(harness.detailRequests, coveredRequests);

    harness.navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(harness.detailRequests, greaterThan(coveredRequests));
    expect(find.text('طلبك في الطريق'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final disposedRequests = harness.detailRequests;
    expect(harness.pusher.listenerCount, 0);
    harness.pusher.emit(501);
    await tester.pump(const Duration(seconds: 61));
    expect(harness.detailRequests, disposedRequests);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recent delivered order permits rating and positive-balance tips',
      (tester) async {
    final harness = _TrackingHarness()
      ..nextDetails = (id) async => _details(id, 'completed', extra: {
            'updated_at': DateTime.now()
                .subtract(const Duration(hours: 1))
                .toIso8601String(),
            'delegate_from_out': 'out_resturant',
            'has_rated_before': 0,
            'has_commissioned_before': 0,
          });
    await harness.mount(tester);

    for (final actionKey in ['tracking-rate', 'tracking-tip']) {
      final action = find.byKey(ValueKey(actionKey));
      expect(action, findsOneWidget);
      final button = find.descendant(
        of: action,
        matching:
            find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
      );
      expect(tester.widget<ButtonStyleButton>(button).onPressed, isNotNull);
    }

    harness.auth.setBalance(0);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tracking-rate')), findsOneWidget);
    expect(find.byKey(const ValueKey('tracking-tip')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delivery older than six hours hides rating and tipping actions',
      (tester) async {
    final harness = _TrackingHarness()
      ..nextDetails = (id) async => _details(id, 'completed', extra: {
            'updated_at': DateTime.now()
                .subtract(const Duration(hours: 7))
                .toIso8601String(),
            'delegate_from_out': 'out_resturant',
            'has_rated_before': 0,
            'has_commissioned_before': 0,
          });
    await harness.mount(tester);

    expect(find.text('طلبك وصل بالسلامة'), findsOneWidget);
    expect(find.byKey(const ValueKey('tracking-rate')), findsNothing);
    expect(find.byKey(const ValueKey('tracking-tip')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancellation removes the pending cancel and support actions',
      (tester) async {
    final harness = _TrackingHarness()..status = 'pending';
    await harness.mount(tester);
    expect(find.byKey(const ValueKey('tracking-cancel')), findsOneWidget);
    expect(find.text('محتاج مساعدة؟'), findsOneWidget);

    harness.status = 'cancelled';
    harness.pusher.emit(501);
    await tester.pumpAndSettle();
    expect(find.text('تم إلغاء الطلب'), findsOneWidget);
    expect(find.byKey(const ValueKey('tracking-cancel')), findsNothing);
    expect(find.text('محتاج مساعدة؟'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
