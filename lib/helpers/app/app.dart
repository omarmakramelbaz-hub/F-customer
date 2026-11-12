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
import '../images/app_images.dart';
import '../pusher_service/pusher_controller.dart';
import '../routes/app_routers_import.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_style.dart';
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth < 430 ? screenWidth - 30 : 400.0;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    final heading = isArabic
        ? 'إصدار أحدث من فسخانستا'
        : 'A newer Fasakhansta version';
    final body = isArabic
        ? 'يجب تحديث التطبيق للاستمرار والاستفادة من أحدث المميزات والتحسينات وتجربة أكثر سلاسة.'
        : 'Please update the app to continue with the latest features, improvements, and a smoother experience.';
    final requiredText = isArabic
        ? 'التحديث إجباري لمتابعة استخدام التطبيق'
        : 'This update is required to continue using the app';

    return Dialog(
      key: key,
      insetPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 22),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: 650),
          child: Container(
            width: dialogWidth,
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 32,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 142,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                FasakhanstaBrand.surfaceRaised,
                                FasakhanstaBrand.surfaceRaised,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        Positioned(
                          top: 13,
                          right: isArabic ? 13 : null,
                          left: isArabic ? null : 13,
                          child: Container(
                            width: 52,
                            height: 52,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: FasakhanstaBrand.surface,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x16000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              AppImages.appLogo,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                            color: FasakhanstaBrand.surfaceRaised,
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.rotate(
                                angle: -.22,
                                child: Icon(
                                  Icons.rocket_launch_rounded,
                                  size: 72,
                                  color: AppColors.mainAppColor,
                                ),
                              ),
                              const Positioned(
                                top: 15,
                                left: 13,
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                  color: FasakhanstaBrand.orange,
                                ),
                              ),
                              const Positioned(
                                bottom: 12,
                                right: 11,
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 14,
                                  color: FasakhanstaBrand.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.mainAppColor,
                            FasakhanstaBrand.orange,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sync_rounded,
                            color: FasakhanstaBrand.text,
                            size: 19,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            title,
                            style: AppTextStyle.text16BW().copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      heading,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.text24BS().copyWith(
                        color: FasakhanstaBrand.text,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.text14RG().copyWith(
                        color: FasakhanstaBrand.muted,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: FasakhanstaBrand.surfaceRaised,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: FasakhanstaBrand.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _UpdateBenefit(
                              icon: Icons.star_outline_rounded,
                              title: isArabic ? 'مميزات جديدة' : 'New features',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 38,
                            color: const Color(0xFFFFE0C7),
                          ),
                          Expanded(
                            child: _UpdateBenefit(
                              icon: Icons.rocket_launch_outlined,
                              title: isArabic ? 'أداء أسرع' : 'Faster',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 38,
                            color: const Color(0xFFFFE0C7),
                          ),
                          Expanded(
                            child: _UpdateBenefit(
                              icon: Icons.verified_user_outlined,
                              title: isArabic ? 'أكثر أماناً' : 'More secure',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 17),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => onUserUpdated(context, false),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.mainAppColor,
                          foregroundColor: FasakhanstaBrand.text,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isIOS
                                  ? Icons.apple_rounded
                                  : Icons.play_arrow_rounded,
                              size: isIOS ? 24 : 27,
                              color: FasakhanstaBrand.text,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              messages.message(
                                    UpgraderMessage.buttonTitleUpdate,
                                  ) ??
                                  (isArabic
                                      ? 'تحديث التطبيق الآن'
                                      : 'Update app now'),
                              style: AppTextStyle.text16BW().copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isArabic
                                  ? Icons.arrow_back_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 15,
                          color: FasakhanstaBrand.muted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            requiredText,
                            textAlign: TextAlign.center,
                            style: AppTextStyle.text11RG().copyWith(
                              color: FasakhanstaBrand.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateBenefit extends StatelessWidget {
  final IconData icon;
  final String title;

  const _UpdateBenefit({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: FasakhanstaBrand.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 19, color: AppColors.mainAppColor),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyle.text11BS().copyWith(
            color: FasakhanstaBrand.muted,
          ),
        ),
      ],
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
