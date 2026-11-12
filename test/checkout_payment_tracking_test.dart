import 'dart:io';

import 'package:faskhaninja/helpers/hive/hive_methods.dart';
import 'package:faskhaninja/helpers/routes/app_routers_import.dart';
import 'package:faskhaninja/helpers/translation/all_translation.dart';
import 'package:faskhaninja/view/custom_widgets/custom_payment_web_view/custom_payment_web_view.dart';
import 'package:faskhaninja/view/layout/address/controller/address_controller.dart';
import 'package:faskhaninja/view/layout/cart/controller/cart_controller.dart';
import 'package:faskhaninja/view/layout/cart/model/user_cart_model.dart';
import 'package:faskhaninja/view/layout/cart/widgets/execute_order_button.dart';
import 'package:faskhaninja/view/layout/orders/screen/tracking_your_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

class _Cart extends CartController {
  String method = 'online';
  int refreshes = 0;

  @override
  String get selectedPayment => method;
  @override
  UserCartModel get cart =>
      UserCartModel(resturant: Resturant(resturantStatus: 'opened'));
  @override
  Future<void> getCart() async {
    refreshes++;
  }

  @override
  Future<void> orderPayment({
    required int userAddressId,
    required String paymentType,
    required String deliveryPrice,
    String? scheduleDate,
    String? notes,
    required String orderType,
    required Function(int orderId) onSuccess,
    required Function(String url, int orderId) onHadeLink,
    VoidCallback? onHasOTP,
  }) async {
    onHadeLink(
        'https://accept.paymob.com/unifiedcheckout/?clientSecret=synthetic-test',
        42);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory hiveDirectory;
  setUpAll(() async {
    hiveDirectory =
        await Directory.systemTemp.createTemp('checkout-payment-test-');
    Hive.init(hiveDirectory.path);
    await Hive.openBox<dynamic>('app');
    await HiveMethods.updateToken('synthetic-checkout-test-token');
    await GlobalTranslations.setNewLanguage('ar', false);
  });
  tearDownAll(() async {
    await HiveMethods.deleteToken();
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  testWidgets('card and Vodafone Cash return to the matching tracking route',
      (tester) async {
    final cart = _Cart();
    final address = AddressController();
    final destinations = <RouteSettings>[];
    late PaymentArgs payment;
    Widget checkout() => ChangeNotifierProvider<CartController>.value(
          value: cart,
          child: Scaffold(
              body: ExecuteOrderButton(
            cartController: cart,
            addressController: address,
            selectedDate: null,
            selectedTime: null,
            selectedDateZone: null,
            userAddressId: 3,
            deliveryPrice: 50,
          )),
        );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      cart.dispose();
      address.dispose();
    });

    await tester.pumpWidget(MaterialApp(
      navigatorKey: NamedNavigatorImpl.navigatorState,
      onGenerateRoute: (settings) {
        destinations.add(settings);
        if (settings.name == CustomPaymentWebViewScreen.routeName) {
          payment = settings.arguments! as PaymentArgs;
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => settings.name == 'checkout-test'
              ? checkout()
              : const Scaffold(body: Text('destination')),
        );
      },
      home: checkout(),
    ));

    for (final method in ['online', 'v_cash']) {
      cart.method = method;
      if (method == 'v_cash') {
        NamedNavigatorImpl.push('checkout-test', clean: true);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.descendant(
        of: find.byType(ExecuteOrderButton),
        matching: find.byType(InkWell),
      ));
      await tester.pumpAndSettle();
      expect(destinations.last.name, CustomPaymentWebViewScreen.routeName);
      expect(payment.orderId, 42);
      expect(payment.url, startsWith('https://accept.paymob.com/'));

      // The payment route removes itself before invoking its completion action.
      NamedNavigatorImpl.navigatorState.currentState!.pop();
      await tester.pumpAndSettle();
      payment.onSuccess();
      await tester.pumpAndSettle();
      expect(destinations.last.name, TrackingYourOrderScreen.routeName);
      expect((destinations.last.arguments! as TrackingYourOrderArgs).id, 42);
      expect(NamedNavigatorImpl.navigatorState.currentState!.canPop(), isFalse,
          reason: 'Back must not resubmit the completed checkout');
      expect(tester.takeException(), isNull);
    }
    expect(cart.refreshes, 2);
  });
}
