import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:faskhaninja/helpers/hive/hive_methods.dart';
import 'package:faskhaninja/helpers/networking/api_helper.dart';
import 'package:faskhaninja/helpers/routes/app_routers_import.dart';
import 'package:faskhaninja/helpers/translation/all_translation.dart';
import 'package:faskhaninja/view/custom_widgets/custom_payment_web_view/custom_payment_web_view.dart';
import 'package:faskhaninja/view/layout/auth/controller/auth_controller.dart';
import 'package:faskhaninja/view/layout/my_account/controller/my_account_controller.dart';
import 'package:faskhaninja/view/layout/my_account/model/setting_model.dart';
import 'package:faskhaninja/view/layout/wallet/bottom_sheet/charge_wallet_bottom_sheet.dart';
import 'package:faskhaninja/view/layout/wallet/controller/wallet_controller.dart';
import 'package:faskhaninja/view/layout/wallet/model/wallet_checkout_service.dart';
import 'package:faskhaninja/view/layout/wallet/widget/chooseVCashOrVisaWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

class _AccountSettings extends MyAccountController {
  @override
  SettingModel get setting =>
      SettingModel(paymentCardActivate: 'true', walletCardActivate: 'true');
}

class _CheckoutService extends WalletCheckoutService {
  final response = Completer<ApiResponse>();
  int calls = 0;
  CancelToken? cancellation;

  @override
  Future<ApiResponse> create({
    required dynamic amount,
    required String paymentMethod,
    required CancelToken cancelToken,
    required Duration timeout,
    required String sessionToken,
    required bool Function() canSendRequest,
  }) {
    calls++;
    cancellation = cancelToken;
    return response.future;
  }
}

ApiResponse _ready() => ApiResponse(
      state: ResponseState.complete,
      data: {
        'data': {
          'link': 'https://accept.paymob.com/unifiedcheckout/?test=synthetic',
          'order_id': 42,
        },
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('wallet-sheet-');
    Hive.init(directory.path);
    await Hive.openBox<dynamic>('app');
    await GlobalTranslations.setNewLanguage('en', false);
  });
  setUp(() async {
    await HiveMethods.updateToken('synthetic-account-a');
  });
  tearDownAll(() async {
    await HiveMethods.deleteToken();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<WalletController> openSheet(
    WidgetTester tester,
    _CheckoutService service,
    List<RouteSettings> destinations,
  ) async {
    final wallet = WalletController(
      checkoutService: service,
      readCheckoutSession: HiveMethods.getToken,
    )..setSelectedPayment('online');
    wallet.chargeAmountEc.text = '50';
    final settings = _AccountSettings();
    final auth = AuthController();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      wallet.dispose();
      settings.dispose();
      auth.dispose();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WalletController>.value(value: wallet),
          ChangeNotifierProvider<MyAccountController>.value(value: settings),
          ChangeNotifierProvider<AuthController>.value(value: auth),
        ],
        child: MaterialApp(
          navigatorKey: NamedNavigatorImpl.navigatorState,
          onGenerateRoute: (route) {
            destinations.add(route);
            return MaterialPageRoute<void>(
              settings: route,
              builder: (_) =>
                  const Scaffold(body: Text('Payment route opened')),
            );
          },
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ChargeWalletBottomSheet(
                      walletController: wallet,
                      myAccountController: settings,
                    ),
                  ),
                  child: const Text('Open wallet'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open wallet'));
    await tester.pumpAndSettle();
    return wallet;
  }

  testWidgets('busy checkout disables controls and keeps errors inline', (
    tester,
  ) async {
    final service = _CheckoutService();
    final destinations = <RouteSettings>[];
    final wallet = await openSheet(tester, service, destinations);
    await tester.tap(find.byKey(const ValueKey('wallet-checkout-submit')));
    await tester.pump();

    expect(wallet.isCreatingCheckout, isTrue);
    expect(
      tester
          .widget<ElevatedButton>(
            find.byKey(const ValueKey('wallet-checkout-submit')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).enabled,
      isFalse,
    );
    final paymentAbsorber = find.ancestor(
      of: find.byType(ChooseVCashOrVisaWidget),
      matching: find.byType(AbsorbPointer),
    );
    expect(
      tester.widget<AbsorbPointer>(paymentAbsorber.first).absorbing,
      isTrue,
    );
    expect(service.calls, 1);

    service.response.complete(
      ApiResponse(
        state: ResponseState.error,
        data: null,
        failure: ApiFailureKind.timeout,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wallet-checkout-error')), findsOneWidget);
    expect(wallet.chargeAmountEc.text, '50');
    expect(wallet.selectedPayment, 'online');
    expect(wallet.isCreatingCheckout, isFalse);
    expect(
      destinations.where((r) => r.name == CustomPaymentWebViewScreen.routeName),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dismissed sheet ignores late checkout without navigation', (
    tester,
  ) async {
    final service = _CheckoutService();
    final destinations = <RouteSettings>[];
    final wallet = await openSheet(tester, service, destinations);
    await tester.tap(find.byKey(const ValueKey('wallet-checkout-submit')));
    await tester.pump();
    NamedNavigatorImpl.navigatorState.currentState!.pop();
    await tester.pumpAndSettle();
    expect(service.cancellation?.isCancelled, isTrue);
    service.response.complete(_ready());
    await tester.pumpAndSettle();
    expect(wallet.isCreatingCheckout, isFalse);
    expect(
      destinations.where((r) => r.name == CustomPaymentWebViewScreen.routeName),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('changed account cannot open previous account checkout', (
    tester,
  ) async {
    final service = _CheckoutService();
    final destinations = <RouteSettings>[];
    final wallet = await openSheet(tester, service, destinations);
    await tester.tap(find.byKey(const ValueKey('wallet-checkout-submit')));
    await tester.pump();
    await tester.runAsync(
      () => HiveMethods.updateToken('synthetic-account-b'),
    );
    service.response.complete(_ready());
    await tester.pumpAndSettle();
    expect(wallet.isCreatingCheckout, isFalse);
    expect(
      destinations.where((r) => r.name == CustomPaymentWebViewScreen.routeName),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('active sheet opens the validated checkout once', (tester) async {
    final service = _CheckoutService();
    final destinations = <RouteSettings>[];
    await openSheet(tester, service, destinations);
    await tester.tap(find.byKey(const ValueKey('wallet-checkout-submit')));
    await tester.pump();
    service.response.complete(_ready());
    await tester.pumpAndSettle();
    final routes = destinations.where(
      (route) => route.name == CustomPaymentWebViewScreen.routeName,
    );
    expect(routes, hasLength(1));
    expect(
      (routes.single.arguments as PaymentArgs).url,
      startsWith('https://accept.paymob.com/'),
    );
    expect(find.text('Payment route opened'), findsOneWidget);
    expect(service.calls, 1);
    expect(tester.takeException(), isNull);
  });
}
