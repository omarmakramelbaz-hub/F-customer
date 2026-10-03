import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../auth/controller/auth_controller.dart';
import '../../home/controller/home_controller.dart';
import '../../home/screen/another_home_screen.dart';
import '../../home/screen/home_screen.dart';
import '../../my_account/screen/my_account_screen.dart';
import '../../notifications/controller/notifications_controller.dart';
import '../../notifications/screen/notifications_screen.dart';
import '../../orders/controller/orders_controller.dart';
import '../../orders/screen/orders_screen.dart';
import '../../restaurants/controller/restaurants_controller.dart';
import '../../restaurants/screen/restaurant_details_screen.dart';
import '../controller/advertising_controller.dart';

export 'bottom_navigation_controller.dart';

class BottomNavLogicController {
  final BuildContext context = NamedNavigatorImpl.context;

  bool dialogShown = false;
  late PusherController pusherController;

  final OrdersController ordersController = OrdersController();
  final NotificationsController notificationsController =
      NotificationsController();

  bool _ordersLoaded = false;
  bool _notificationsLoaded = false;

  BottomNavLogicController();

  Future<void> init() async {
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());

    final advertisingController = Provider.of<AdvertisingController>(context, listen: false);

    pusherController = context.read<PusherController>();
    pusherController.addEventListener('user.updated', handleUserOrdersUpdate);

    advertisingController.initialAdvertising();

    advertisingController.getAdvertising().then((_) {
      if (advertisingController.advertising.isNotEmpty &&
          advertisingController.advertising.first.restaurantId != null) {
        Future.delayed(const Duration(seconds: 1), () {
          if (!dialogShown) showAdvertisingDialog();
        });
      }
    });
  }

  Future<void> _initializeData() async {
    final homeProvider = Provider.of<HomeController>(context, listen: false);

    homeProvider.initialCountCart();
    homeProvider.initialSlider();
    homeProvider.initialDefaultSlider();
    homeProvider.initialPreviousOrder();
    homeProvider.initialRestaurantsNearYou();
    homeProvider.initialCoupon();
    homeProvider.initialSpacialRestaurants();

    try {
      Future.wait([
        homeProvider.getSlider(),
        homeProvider.getDefaultSlider(),
        homeProvider.getPreviousOrder(),
        homeProvider.getCoupon(lat: HiveMethods.getLat(), lng: HiveMethods.getLan()),
        homeProvider.getRestaurantsNearYou(lat: HiveMethods.getLat(), lng: HiveMethods.getLan()),
        homeProvider.getSpacialRestaurants(lat: HiveMethods.getLat(), lng: HiveMethods.getLan()),
      ]);
    } catch (e) {
      log('Failed to initialize data: $e');
    }
  }

  void handleUserOrdersUpdate(PusherEvent event) {
    try {
      Map<String, dynamic> jsonData = jsonDecode(event.data);

      String? status = jsonData['order_id']['status']?.toString();
      String? orderNo = jsonData['order_id']['order_no']?.toString();

      if (status != null && status != 'pending') {
        CommonMethods.showToast(message: "${'thereIsANewOrderWithStatus'.tr} $orderNo");
      }
    } catch (e, s) {
      log('Error handling Pusher event: $e');
      log('Stack: $s');
    }
  }

  void dispose() {
    pusherController.removeEventListener('user.updated', handleUserOrdersUpdate);
    ordersController.dispose();
    notificationsController.dispose();
  }

  void ensureOrdersLoaded() {
    if (_ordersLoaded) return;
    _ordersLoaded = true;
    ordersController.initialOrders();
    ordersController.getOrders();
  }

  void ensureNotificationsLoaded() {
    if (_notificationsLoaded) return;
    _notificationsLoaded = true;
    notificationsController.initialNotifications();
    notificationsController.getNotifications();
  }

  void showAdvertisingDialog() {
    final ads = context.read<AdvertisingController>();
    if (ads.hasSeenAdd) return;

    showDialog(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future.delayed(const Duration(seconds: 20), () {
              Navigator.pop(context);
            });

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Stack(
                children: [
                  InkWell(
                    onTap: () {
                      NamedNavigatorImpl.push(
                        RestaurantDetailsScreen.routeName,
                        replace: true,
                        arguments: RestaurantDetailsArgs(id: ads.advertising.first.restaurantId ?? 0),
                      );
                    },
                    child: ads.advertising.isNotEmpty
                        ? CustomNetworkImage(
                            width: double.infinity,
                            imageUrl: ads.advertising.first.image ?? '',
                            fit: BoxFit.fill,
                            radius: 20,
                          )
                        : Container(),
                  ),
                  Positioned(
                    left: 20,
                    top: 20,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          child: SvgPicture.asset(AppImages.closeIcon),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      dialogShown = true;
      ads.setHasSeenAdd(true);
    });
  }

  Widget getCurrentScreen(int index) {
    switch (index) {
      case 1:
        ensureOrdersLoaded();
        return ChangeNotifierProvider.value(
          value: ordersController,
          child: const OrdersScreen(),
        );
      case 2:
        ensureNotificationsLoaded();
        return ChangeNotifierProvider.value(
          value: notificationsController,
          child: const NotificationsScreen(),
        );
      case 3:
        return const MyAccountScreen();
      case 0:
      default:
        if (context.read<AuthController>().profile?.appMultiVendor == null) {
          return const HomeScreen();
        }

        return ChangeNotifierProvider(
          create: (_) => RestaurantsController(),
          child: AnotherHomeScreen(
            id: context.read<AuthController>().profile?.appMultiVendor ?? 82,
          ),
        );
    }
  }
}
