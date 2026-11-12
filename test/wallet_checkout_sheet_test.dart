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
import 'package:faskhaninja/view/layout/wallet/model/wallet_model.dart';
import 'package:faskhaninja/view/layout/wallet/widget/chooseVCashOrVisaWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

class _SheetWalletController extends WalletController {
  _SheetWalletController({required WalletCheckoutService checkoutService})
      : super(
          checkoutService: checkoutService,
          readCheckoutSession: HiveMethods.getToken,
        );

  @override
  WalletResponse get wallet => WalletResponse(balance: 728.07);
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
    List<RouteSettings> destinations, {
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    final wallet = _SheetWalletController(checkoutService: service)
      ..setSelectedPayment('online');
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
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
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

  Future<void> submitCheckout(WidgetTester tester) async {
    final submit = find.byKey(const ValueKey('wallet-checkout-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
  }

  testWidgets('busy checkout disables controls and keeps errors inline', (
    tester,
  ) async {
    final service = _CheckoutService();
    final destinations = <RouteSettings>[];
    final wallet = await openSheet(tester, service, destinations);
    await submitCheckout(tester);

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

    // A fast second choice must not change an in-flight payment amount.
    final quickAmount = find.byKey(const ValueKey('wallet-quick-amount-200'));
    expect(tester.widget<OutlinedButton>(quickAmount).onPressed, isNull);
    await tester.ensureVisible(quickAmount);
    await tester.tap(
      quickAmount,
    );
    await tester.pump();
    expect(wallet.chargeAmountEc.text, '50');
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
    await submitCheckout(tester);
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
    await submitCheckout(tester);
    await tester.runAsync(() => HiveMethods.updateToken('synthetic-account-b'));
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
    await submitCheckout(tester);
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

  testWidgets('quick amounts update the payment total and projected balance', (
    tester,
  ) async {
    final service = _CheckoutService();
    final wallet = await openSheet(tester, service, <RouteSettings>[]);
    final submit = find.byKey(const ValueKey('wallet-checkout-submit'));
    for (final amount in [50, 100, 200, 500]) {
      final quick = find.byKey(ValueKey('wallet-quick-amount-$amount'));
      await tester.ensureVisible(quick);
      await tester.tap(quick);
      await tester.pumpAndSettle();
      expect(wallet.chargeAmountEc.text, '$amount');
      expect(
        find.descendant(of: submit, matching: find.textContaining('$amount')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('wallet-balance-after-charge')),
            )
            .data
            ?.replaceAll(',', ''),
        contains((728.07 + amount).toStringAsFixed(2)),
      );
    }
    expect(service.calls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom amount clears the quick choice and updates the total', (
    tester,
  ) async {
    final service = _CheckoutService();
    final wallet = await openSheet(tester, service, <RouteSettings>[]);
    await tester.enterText(
      find.byKey(const ValueKey('wallet-recharge-amount')),
      '125',
    );
    await tester.pumpAndSettle();
    expect(wallet.chargeAmountEc.text, '125');
    for (final amount in [50, 100, 200, 500]) {
      expect(
        tester
            .widget<Semantics>(
              find
                  .ancestor(
                    of: find.byKey(
                      ValueKey('wallet-quick-amount-$amount'),
                    ),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .properties
            .selected,
        isFalse,
      );
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('wallet-checkout-submit')),
        matching: find.textContaining('125'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('wallet-balance-after-charge')),
          )
          .data
          ?.replaceAll(',', ''),
      contains('853.07'),
    );
    expect(service.calls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('amounts below the existing minimum cannot start checkout', (
    tester,
  ) async {
    final service = _CheckoutService();
    final wallet = await openSheet(tester, service, <RouteSettings>[]);
    for (final amount in ['', '0', '49']) {
      await tester.enterText(
        find.byKey(const ValueKey('wallet-recharge-amount')),
        amount,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ElevatedButton>(
              find.byKey(const ValueKey('wallet-checkout-submit')),
            )
            .onPressed,
        isNull,
      );
      expect(wallet.chargeWalletFormKey.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
    }
    await tester.enterText(
      find.byKey(const ValueKey('wallet-recharge-amount')),
      '50',
    );
    await tester.pumpAndSettle();
    expect(wallet.chargeWalletFormKey.currentState!.validate(), isTrue);
    expect(service.calls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL sheet stays usable at 320px with keyboard and larger text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetViewInsets);
    final service = _CheckoutService();
    final wallet = await openSheet(
      tester,
      service,
      <RouteSettings>[],
      locale: const Locale('ar'),
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
    final amount = find.byKey(const ValueKey('wallet-recharge-amount'));
    await tester.ensureVisible(amount);
    await tester.tap(amount);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.enterText(amount, '200');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(wallet.chargeAmountEc.text, '200');
    tester.view.resetViewInsets();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    for (final method in ['vodafone_cash', 'orange_cash', 'etisalat_cash']) {
      final payment = find.byKey(ValueKey('wallet-payment-$method'));
      await tester.ensureVisible(payment);
      await tester.tap(payment);
      await tester.pumpAndSettle();
      expect(wallet.selectedPayment, 'v_cash');
      expect(tester.takeException(), isNull);
    }
    final card = find.byKey(const ValueKey('wallet-payment-bank_card'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(wallet.selectedPayment, 'online');
    await tester.ensureVisible(
      find.byKey(const ValueKey('wallet-checkout-submit')),
    );
    expect(tester.takeException(), isNull);
    expect(service.calls, 0);
  });
}
