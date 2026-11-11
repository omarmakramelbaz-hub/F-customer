import 'dart:async';
import 'dart:io';

import 'package:faskhaninja/helpers/hive/hive_methods.dart';
import 'package:faskhaninja/helpers/networking/api_helper.dart';
import 'package:faskhaninja/helpers/pusher_service/pusher_controller.dart';
import 'package:faskhaninja/view/layout/auth/controller/auth_controller.dart';
import 'package:faskhaninja/view/layout/auth/model/profile_model.dart';
import 'package:faskhaninja/view/layout/bottom_navigation/controller/bottom_navigation_controller.dart';
import 'package:faskhaninja/view/layout/cart/controller/cart_controller.dart';
import 'package:faskhaninja/view/layout/home/controller/home_controller.dart';
import 'package:faskhaninja/view/layout/home/controller/home_primary_action_controller.dart';
import 'package:faskhaninja/view/layout/home/screen/home_screen.dart';
import 'package:faskhaninja/view/layout/wallet/controller/wallet_controller.dart';
import 'package:faskhaninja/view/layout/wallet/model/wallet_model.dart'
    show WalletResponse;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

ApiResponse _complete(Object? data) => ApiResponse(
      state: ResponseState.complete,
      data: {'data': data},
    );

class _HomeData extends HomeController {
  @override
  ApiResponse get restaurantsNearYouApiResponse => _complete([]);
  @override
  ApiResponse get couponResponse => _complete(null);
  @override
  Future<void> getRestaurantsNearYou({double? lat, double? lng}) async {}
  @override
  Future<void> getCoupon({double? lat, double? lng}) async {}
}

class _AuthData extends AuthController {
  final _profile = ProfileModel(
    id: 9001,
    userAddresses: [
      UserAddresses(id: 7, streetName: 'عنوان الاختبار', cityName: 'المنصورة'),
    ],
  );

  @override
  ProfileModel get profile => _profile;
}

class _WalletData extends WalletController {
  @override
  WalletResponse get wallet => WalletResponse(balance: 25);
  @override
  Future<void> getWallet() async {}
}

class _CartSignals extends CartController {
  @override
  ApiResponse get cartResponse => _complete(null);

  @override
  Future<void> getCart() async {
    throw StateError('Home must load its own session-scoped cart');
  }

  void emitChange() => notifyListeners();
}

class _PusherSignals extends PusherController {
  final _listeners = <String, List<void Function(PusherEvent)>>{};

  @override
  void addEventListener(String eventName, void Function(PusherEvent) listener) {
    (_listeners[eventName] ??= []).add(listener);
  }

  @override
  void removeEventListener(
      String eventName, void Function(PusherEvent) listener) {
    _listeners[eventName]?.remove(listener);
  }

  void emitOrderUpdate() {
    final event = PusherEvent(
      channelName: 'synthetic-test-channel',
      eventName: 'user.updated',
      data: '{}',
    );
    for (final listener in [...?_listeners['user.updated']]) {
      listener(event);
    }
  }
}

/// No media, network or native plugin activity is needed to test the real page.
class _VideoPlatform extends VideoPlayerPlatform {
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

class _HomeHarness {
  final navigator = GlobalKey<NavigatorState>();
  final home = _HomeData();
  final auth = _AuthData();
  final wallet = _WalletData();
  final cart = _CartSignals();
  final pusher = _PusherSignals();
  final bottomNavigation = BottomNavigationController();
  int orderRequests = 0;
  int cartRequests = 0;
  List<Map<String, Object?>> orders = [];
  Object? cartData;
  late final primaryAction = HomePrimaryActionController(
    loadOrders: () async {
      orderRequests++;
      return _complete(orders);
    },
    loadCart: () async {
      cartRequests++;
      return _complete(cartData);
    },
  );

  Future<void> mount(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    final previousVideoPlatform = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _VideoPlatform();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      VideoPlayerPlatform.instance = previousVideoPlatform;
      await tester.binding.setSurfaceSize(null);
      home.dispose();
      auth.dispose();
      wallet.dispose();
      cart.dispose();
      pusher.dispose();
      bottomNavigation.dispose();
      primaryAction.dispose();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeController>.value(value: home),
          ChangeNotifierProvider<AuthController>.value(value: auth),
          ChangeNotifierProvider<WalletController>.value(value: wallet),
          ChangeNotifierProvider<CartController>.value(value: cart),
          ChangeNotifierProvider<PusherController>.value(value: pusher),
          ChangeNotifierProvider<BottomNavigationController>.value(
            value: bottomNavigation,
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          home: HomeScreen(primaryActionController: primaryAction),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDirectory;
  late Box<dynamic> appBox;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('home-action-test-');
    Hive.init(hiveDirectory.path);
    appBox = await Hive.openBox<dynamic>('app');
  });

  setUp(() async {
    await appBox.clear();
    await HiveMethods.updateToken('synthetic-home-integration-token');
    await appBox.putAll({
      'selectedCity': 7,
      'lat': 31.0409,
      'lan': 31.3785,
      'City': 'عنوان الاختبار',
      'isVisitor': false,
    });
  });

  tearDownAll(() async {
    await HiveMethods.deleteToken();
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('real home loads the server cart and displays its primary action',
      (tester) async {
    final harness = _HomeHarness()
      ..cartData = {
        'carts': [
          // The server already filters is_order=false. order_id may be retained.
          {'qty': 1, 'order_id': 99},
        ],
      };
    await harness.mount(tester);

    expect(harness.orderRequests, greaterThan(0));
    expect(harness.cartRequests, greaterThan(0));
    expect(find.widgetWithText(ElevatedButton, 'الاطّلاع على السلة'),
        findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'ابدأ طلبك'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real home prioritizes an active order above a nonempty cart',
      (tester) async {
    final harness = _HomeHarness()
      ..orders = [
        {'id': 202, 'status': 'pending', 'order_no': 'TEST-202'},
      ]
      ..cartData = {
        'carts': [
          {'qty': 1, 'order_id': 99},
        ],
      };
    await harness.mount(tester);

    expect(harness.orderRequests, greaterThan(0));
    expect(harness.cartRequests, greaterThan(0));
    expect(find.widgetWithText(ElevatedButton, 'تتبّع الطلب'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'ابدأ طلبك'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real home refresh indicator updates the action after loading',
      (tester) async {
    final harness = _HomeHarness();
    await harness.mount(tester);
    expect(find.widgetWithText(ElevatedButton, 'ابدأ طلبك'), findsOneWidget);
    final requestsBeforeRefresh = harness.orderRequests;
    harness.orders = [
      {'id': 203, 'status': 'accepted', 'order_no': 'TEST-203'},
    ];

    unawaited(
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show(),
    );
    await tester.pumpAndSettle();

    expect(harness.orderRequests, greaterThan(requestsBeforeRefresh));
    expect(find.widgetWithText(ElevatedButton, 'تتبّع الطلب'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('covered home pauses refresh and reloads when its route returns',
      (tester) async {
    final harness = _HomeHarness();
    await harness.mount(tester);
    unawaited(harness.navigator.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('covering-test-route')),
      ),
    ));
    await tester.pumpAndSettle();
    final requestsWhileCovered = harness.orderRequests;
    final cartRequestsWhileCovered = harness.cartRequests;

    harness.orders = [
      {'id': 204, 'status': 'shipped', 'order_no': 'TEST-204'},
    ];
    harness.pusher.emitOrderUpdate();
    harness.cart.emitChange();
    await tester.pump(const Duration(seconds: 31));
    expect(harness.orderRequests, requestsWhileCovered);
    expect(harness.cartRequests, cartRequestsWhileCovered);

    harness.navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(harness.orderRequests, greaterThan(requestsWhileCovered));
    expect(find.widgetWithText(ElevatedButton, 'تتبّع الطلب'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
