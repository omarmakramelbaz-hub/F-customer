import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';

import '../../view/layout/address/controller/address_controller.dart';
import '../../view/layout/auth/controller/auth_controller.dart';
import '../../view/layout/bottom_navigation/controller/advertising_controller.dart';
import '../../view/layout/cart/controller/cart_controller.dart';
import '../../view/layout/home/controller/home_controller.dart';
import '../../view/layout/my_account/controller/my_account_controller.dart';
import '../../view/layout/on_boarding/screen/splash_screen.dart';
import '../../view/layout/orders/controller/last_order_controller.dart';
import '../../view/layout/request_delegate/controller/request_delegate_controller.dart';
import '../../view/layout/wallet/controller/wallet_controller.dart';
import '../delivery_activity/delivery_provider.dart';
import '../forced_update/fasakhansta_update_dialog.dart';
import '../pusher_service/pusher_controller.dart';
import '../routes/app_routers_import.dart';
import '../theme/theme.dart';
import '../theme/fasakhansta_brand.dart';
import '../translation/all_translation.dart';
import '../translation/main_app_bloc.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    mainAppBloc.getShared();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PusherController()),
        ChangeNotifierProvider(
            create: (context) =>
                DeliveryProvider(pusher: context.read<PusherController>())),
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
        ChangeNotifierProvider(create: (_) => LastCorderController()),
      ],
      child: StreamBuilder<String>(
        stream: mainAppBloc.langStream,
        builder: (context, lang) {
          if (lang.hasData) {
            final languageCode = lang.data!;
            final botToastBuilder = BotToastInit();

            return MaterialApp(
              title: 'FaskhaNinja',
              locale: Locale(languageCode, ''),
              supportedLocales: GlobalTranslations.supportedLocales(),
              localizationsDelegates: context.localizationsDelegates,
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                final appChild = FasakhanstaAppBackground(
                  child: botToastBuilder(context, child),
                );

                // Web is only used for the review build. Store-version checks
                // are enabled on the actual Android/iOS applications.
                if (kIsWeb) return appChild;

                return _FasakhanstaUpgradeAlert(
                  upgrader: Upgrader(
                    countryCode: 'EG',
                    durationUntilAlertAgain: Duration.zero,
                    messages: _FasakhanstaUpgraderMessages(code: languageCode),
                  ),
                  child: appChild,
                );
              },
              navigatorObservers: [BotToastNavigatorObserver()],
              initialRoute: SplashScreen.routeName,
              onGenerateRoute: NamedNavigatorImpl.onGenerateRoute,
              navigatorKey: NamedNavigatorImpl.navigatorState,
              theme: theme(context),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}

class _FasakhanstaUpgradeAlert extends UpgradeAlert {
  _FasakhanstaUpgradeAlert({required Upgrader upgrader, required Widget child})
      : super(
          upgrader: upgrader,
          showIgnore: false,
          showLater: false,
          showPrompt: false,
          showReleaseNotes: false,
          barrierDismissible: false,
          shouldPopScope: () => false,
          child: child,
        );

  @override
  UpgradeAlertState createState() => _FasakhanstaUpgradeAlertState();
}

class _FasakhanstaUpgradeAlertState extends UpgradeAlertState {
  @override
  Widget alertDialog(
    Key? key,
    String title,
    String message,
    String? releaseNotes,
    BuildContext context,
    bool cupertino,
    UpgraderMessages messages,
  ) {
    return FasakhanstaUpdateDialog(
      key: key,
      title: title,
      buttonText: messages.message(UpgraderMessage.buttonTitleUpdate),
      onUpdate: () => onUserUpdated(context, false),
    );
  }
}

class _FasakhanstaUpgraderMessages extends UpgraderMessages {
  _FasakhanstaUpgraderMessages({required String code}) : super(code: code);

  @override
  String message(UpgraderMessage messageKey) {
    if (languageCode == 'ar') {
      switch (messageKey) {
        case UpgraderMessage.title:
          return 'تحديث جديد متاح';
        case UpgraderMessage.body:
          return 'يتوفر إصدار جديد من فسخانستا. يجب تحديث التطبيق للاستمرار والاستفادة من أحدث التحسينات.';
        case UpgraderMessage.prompt:
          return 'التحديث مطلوب للمتابعة';
        case UpgraderMessage.buttonTitleUpdate:
          return 'تحديث التطبيق الآن';
        case UpgraderMessage.buttonTitleIgnore:
          return 'تجاهل';
        case UpgraderMessage.buttonTitleLater:
          return 'لاحقاً';
        case UpgraderMessage.releaseNotes:
          return 'ما الجديد';
      }
    }

    switch (messageKey) {
      case UpgraderMessage.title:
        return 'New update available';
      case UpgraderMessage.body:
        return 'A new version of Fasakhansta is available. Please update the app to continue and get the latest improvements.';
      case UpgraderMessage.prompt:
        return 'Update required to continue';
      case UpgraderMessage.buttonTitleUpdate:
        return 'Update app now';
      case UpgraderMessage.buttonTitleIgnore:
        return 'Ignore';
      case UpgraderMessage.buttonTitleLater:
        return 'Later';
      case UpgraderMessage.releaseNotes:
        return "What's new";
    }
  }
}
