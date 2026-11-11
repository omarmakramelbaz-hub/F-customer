import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';

import '../../../helpers/hive/hive_methods.dart';
import '../../../helpers/routes/app_routers_import.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/theme/app_text_style.dart';
import '../../../helpers/translation/all_translation.dart';
import '../../../helpers/utils/common_methods.dart';
import '../auth/controller/auth_controller.dart';
import '../auth/screen/register_screen.dart';
import '../cart/controller/cart_controller.dart';
import '../cart/screen/cart_screen.dart';
import 'controller/bottom_nav_controller.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  static const String routeName = 'BottomNavigationBarScreen';
  const BottomNavigationBarScreen({super.key});

  @override
  State<BottomNavigationBarScreen> createState() =>
      _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  late BottomNavLogicController logic;

  @override
  void initState() {
    super.initState();
    logic = BottomNavLogicController();
    logic.init();
  }

  @override
  void dispose() {
    logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BottomNavigationController(),
      child: Consumer<BottomNavigationController>(
        builder: (context, controller, _) {
          final fullVideoHome =
              controller.screenIndex == 0 &&
              context.watch<AuthController>().profile?.appMultiVendor == null;
          final scaffold = Scaffold(
            backgroundColor: fullVideoHome ? const Color(0xFF102B2E) : null,
            extendBody: fullVideoHome,
            resizeToAvoidBottomInset: false,
            body: logic.getCurrentScreen(controller.screenIndex),
            bottomNavigationBar: _buildBottomNavBar(
              controller,
              fullVideoHome: fullVideoHome,
            ),
          );

          return PopScope(
            canPop: controller.screenIndex == 0,
            onPopInvoked: controller.onWillPop,
            child: UpgradeAlert(
              dialogStyle: UpgradeDialogStyle.cupertino,
              showLater: true,
              upgrader: Upgrader(
                debugLogging: false,
                debugDisplayAlways: false,
                debugDisplayOnce: false,
                languageCode: context.languageCode,
                messages: UpgraderMessages(code: context.languageCode),
                countryCode: 'EG',
              ),
              child: fullVideoHome
                  ? AnnotatedRegion<SystemUiOverlayStyle>(
                      value: SystemUiOverlayStyle.light.copyWith(
                        statusBarColor: Colors.transparent,
                        systemNavigationBarColor: Colors.transparent,
                        systemNavigationBarDividerColor: Colors.transparent,
                      ),
                      child: scaffold,
                    )
                  : scaffold,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavBar(
    BottomNavigationController controller, {
    required bool fullVideoHome,
  }) {
    final navigationItems = SizedBox(
      height: 70,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: _navItem(
                index: 0,
                controller: controller,
                iconSelected: Icons.home_rounded,
                iconUnselected: Icons.home_outlined,
                title: 'home'.tr,
                fullVideoHome: fullVideoHome,
                onTap: () => controller.updateIndex(0),
              ),
            ),
            Expanded(child: _navCart(fullVideoHome: fullVideoHome)),
            Expanded(
              child: _navOrders(controller, fullVideoHome: fullVideoHome),
            ),
            Expanded(
              child: _navNotifications(
                controller,
                fullVideoHome: fullVideoHome,
              ),
            ),
            Expanded(
              child: _navItem(
                index: 3,
                controller: controller,
                iconSelected: Icons.person_rounded,
                iconUnselected: Icons.person_outline_rounded,
                title: 'account'.tr,
                fullVideoHome: fullVideoHome,
                onTap: () => controller.updateIndex(3),
              ),
            ),
          ],
        ),
      ),
    );

    if (fullVideoHome) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0x660C2728),
              border: Border(top: BorderSide(color: Color(0x26FFF9E1))),
            ),
            child: SafeArea(top: false, child: navigationItems),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 9),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFEDEFF2), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 22,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: navigationItems,
      ),
    );
  }

  Widget _navItem({
    required int index,
    required BottomNavigationController controller,
    required IconData iconSelected,
    required IconData iconUnselected,
    required String title,
    required VoidCallback onTap,
    required bool fullVideoHome,
  }) {
    final selected = controller.screenIndex == index;

    return _navButton(
      selected: selected,
      fullVideoHome: fullVideoHome,
      title: title,
      onTap: onTap,
      icon: selected ? iconSelected : iconUnselected,
    );
  }

  Widget _navCart({required bool fullVideoHome}) {
    final cartCount = HiveMethods.getToken() == null
        ? 0
        : (context.watch<CartController>().cart?.carts?.length ?? 0);

    return _navButton(
      selected: false,
      fullVideoHome: fullVideoHome,
      title: context.languageCode == 'ar' ? 'السلة' : 'Cart',
      icon: Icons.shopping_cart_outlined,
      badgeCount: cartCount,
      onTap: () {
        if (HiveMethods.getToken() == null) {
          CommonMethods.showChooseDialog(
            context,
            onPressed: () {
              Navigator.pop(context);
              NamedNavigatorImpl.push(RegisterScreen.routeName);
            },
            message: 'youMustLoginFirst'.tr,
          );
          return;
        }

        NamedNavigatorImpl.push(CartScreen.routeName);
      },
    );
  }

  Widget _navOrders(
    BottomNavigationController controller, {
    required bool fullVideoHome,
  }) {
    final selected = controller.screenIndex == 1;

    return _navButton(
      selected: selected,
      fullVideoHome: fullVideoHome,
      title: 'orders'.tr,
      onTap: () {
        if (HiveMethods.getToken() == null) {
          CommonMethods.showChooseDialog(
            context,
            onPressed: () {
              Navigator.pop(context);
              NamedNavigatorImpl.push(RegisterScreen.routeName);
            },
            message: 'youMustLoginFirst'.tr,
          );
        } else {
          controller.updateIndex(1);
        }
      },
      icon: selected ? Icons.receipt_long_rounded : Icons.receipt_long_outlined,
    );
  }

  Widget _navNotifications(
    BottomNavigationController controller, {
    required bool fullVideoHome,
  }) {
    final selected = controller.screenIndex == 2;
    final hasNewNotifications =
        HiveMethods.getNotificationsCount() != null &&
        HiveMethods.getNotificationsCount() !=
            context.read<AuthController>().profile?.notificaionsCount;

    return _navButton(
      selected: selected,
      fullVideoHome: fullVideoHome,
      title: 'notifications'.tr,
      onTap: () {
        if (HiveMethods.getToken() == null) {
          CommonMethods.showChooseDialog(
            context,
            onPressed: () {
              Navigator.pop(context);
              NamedNavigatorImpl.push(RegisterScreen.routeName);
            },
            message: 'youMustLoginFirst'.tr,
          );
        } else {
          HiveMethods.updateNotificationCount(
            context.read<AuthController>().profile?.notificaionsCount,
          );
          controller.updateIndex(2);
        }
      },
      icon: selected
          ? Icons.notifications_rounded
          : Icons.notifications_none_rounded,
      showBadge: hasNewNotifications,
    );
  }

  Widget _navButton({
    required bool selected,
    required String title,
    required VoidCallback onTap,
    required IconData icon,
    required bool fullVideoHome,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    final inactiveColor = fullVideoHome
        ? const Color(0xFFE5E8DA)
        : const Color(0xFF8A8F98);
    final accentColor = fullVideoHome
        ? const Color(0xFFFFAD5B)
        : AppColors.mainAppColor;
    final badgeBorderColor = fullVideoHome
        ? const Color(0xFF183D3C)
        : AppColors.whiteColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: accentColor.withValues(alpha: .07),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 210),
                    curve: Curves.easeOutCubic,
                    width: 46,
                    height: 34,
                    decoration: BoxDecoration(
                      color: selected
                          ? accentColor.withValues(alpha: .11)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                      border: selected
                          ? Border.all(
                              color: accentColor.withValues(alpha: .10),
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 190),
                      curve: Curves.easeOutBack,
                      scale: selected ? 1.04 : 1,
                      child: Icon(
                        icon,
                        size: selected ? 24 : 23,
                        color: selected ? accentColor : inactiveColor,
                      ),
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -4,
                      top: -5,
                      child: Container(
                        height: 17,
                        constraints: const BoxConstraints(minWidth: 17),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: badgeBorderColor,
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22FD7201),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: TextStyle(
                            color: fullVideoHome
                                ? const Color(0xFF183D3C)
                                : Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    )
                  else if (showBadge)
                    Positioned(
                      right: 1,
                      top: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: badgeBorderColor,
                            width: 1.7,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style:
                    (selected
                            ? AppTextStyle.text12RM()
                            : AppTextStyle.text12RG())
                        .copyWith(
                          fontSize: fullVideoHome ? 11 : 10.3,
                          height: 1.05,
                          color: selected ? accentColor : inactiveColor,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
