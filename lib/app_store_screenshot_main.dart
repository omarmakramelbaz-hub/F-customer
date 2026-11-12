import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'helpers/app/init_services.dart';
import 'helpers/delivery_activity/delivery_provider.dart';
import 'helpers/pusher_service/pusher_controller.dart';
import 'helpers/routes/app_routers_import.dart';
import 'helpers/theme/theme.dart';
import 'helpers/theme/fasakhansta_brand.dart';
import 'helpers/translation/all_translation.dart';
import 'view/layout/address/controller/address_controller.dart';
import 'view/layout/auth/controller/auth_controller.dart';
import 'view/layout/bottom_navigation/controller/advertising_controller.dart';
import 'view/layout/cart/controller/cart_controller.dart';
import 'view/layout/home/controller/home_controller.dart';
import 'view/layout/my_account/controller/my_account_controller.dart';
import 'view/layout/orders/controller/last_order_controller.dart';
import 'view/layout/request_delegate/controller/request_delegate_controller.dart';
import 'view/layout/wallet/controller/wallet_controller.dart';

/// Screenshot-only entry point used by GitHub Actions.
/// It does not affect the production Android/iOS entry point.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServices();
  await GlobalTranslations.setNewLanguage('ar');

  final requestedRoute =
      Uri.base.queryParameters['route'] ?? 'BottomNavigationBarScreen';
  runApp(_ScreenshotApp(initialRoute: requestedRoute));
}

class _ScreenshotApp extends StatelessWidget {
  final String initialRoute;

  const _ScreenshotApp({required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => WalletController()),
        ChangeNotifierProvider(
          create: (_) => MyAccountController()
            ..initialSetting()
            ..getSetting(),
        ),
        ChangeNotifierProvider(create: (_) => AddressController()),
        ChangeNotifierProvider(create: (_) => RequestDelegateController()),
        ChangeNotifierProvider(create: (_) => AdvertisingController()..init()),
        ChangeNotifierProvider(create: (_) => CartController()..init()),
        ChangeNotifierProvider(create: (_) => PusherController()),
        ChangeNotifierProvider(create: (_) => LastCorderController()),
      ],
      child: Builder(
        builder: (context) {
          final botToastBuilder = BotToastInit();
          return MaterialApp(
            title: 'Fasakhansta',
            locale: const Locale('ar', ''),
            supportedLocales: GlobalTranslations.supportedLocales(),
            localizationsDelegates: context.localizationsDelegates,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => FasakhanstaAppBackground(
              child: botToastBuilder(context, child),
            ),
            navigatorObservers: [BotToastNavigatorObserver()],
            initialRoute: initialRoute,
            onGenerateRoute: NamedNavigatorImpl.onGenerateRoute,
            navigatorKey: NamedNavigatorImpl.navigatorState,
            theme: theme(context),
          );
        },
      ),
    );
  }
}
