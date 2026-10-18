import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/delivery_activity/delivery_provider.dart';
import '../../../../helpers/delivery_activity/delivery_activity_payload.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../bottom_navigation/bottom_navigation_bar_screen.dart';
import '../../orders/controller/orders_controller.dart';
import '../../orders/screen/tracking_your_order_screen.dart';

class YourOrderSuccessfullyCompletedArgs {
  final int id;
  const YourOrderSuccessfullyCompletedArgs({required this.id});
}

class YourOrderSuccessfullyCompletedScreen extends StatefulWidget {
  final YourOrderSuccessfullyCompletedArgs args;
  static const routeName = 'YourOrderSuccessfullyCompletedScreen';
  const YourOrderSuccessfullyCompletedScreen({super.key, required this.args});

  @override
  State<YourOrderSuccessfullyCompletedScreen> createState() =>
      _YourOrderSuccessfullyCompletedScreenState();
}

class _YourOrderSuccessfullyCompletedScreenState
    extends State<YourOrderSuccessfullyCompletedScreen> {
  late PusherController _pusherController;
  bool isAcceptedFromDelegate = false;

  @override
  void initState() {
    super.initState();
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener(
      'finished.updated',
      _handleFinishedUpdate,
    );

    final liveActivitiesController =
        Provider.of<DeliveryProvider>(context, listen: false);
    final ordersController =
        Provider.of<OrdersController>(context, listen: false);

    Future.delayed(
      Duration.zero,
      () async {
        await ordersController.getDetailsOrders(id: widget.args.id);
        if (!mounted) return;
        final order = ordersController.detailsOrders;
        if (order == null || order.id != widget.args.id) return;
        await liveActivitiesController.init(widget.args.id);
        await liveActivitiesController.startDelivery(
          DeliveryActivityPayload.status(order.toJson()),
          orderNo: order.orderNo,
          restaurantName: order.resturantName,
          updatedAt: order.updatedAt,
        );
      },
    );
  }

  void _handleFinishedUpdate(PusherEvent event) {
    try {
      final jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      final orderNo = jsonData['order_no']?.toString();

      if (orderNo != null) {
        CommonMethods.showToast(
          message: '${'thereIsANewOrderWithStatus'.tr} $orderNo',
        );
      }

      log('is Finished $jsonData');
      if (mounted) setState(() => isAcceptedFromDelegate = true);
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController.removeEventListener(
      'finished.updated',
      _handleFinishedUpdate,
    );
    super.dispose();
  }

  void _goHome() {
    NamedNavigatorImpl.push(
      clean: true,
      BottomNavigationBarScreen.routeName,
    );
  }

  void _trackOrder() {
    NamedNavigatorImpl.push(
      TrackingYourOrderScreen.routeName,
      arguments: TrackingYourOrderArgs(id: widget.args.id),
      clean: true,
    );
  }

  void _cancelOrder() {
    context.read<OrdersController>().cancelOrder(
          orderId: widget.args.id,
          onSuccess: _goHome,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const success = Color(0xFF1FA76F);
    const textDark = Color(0xFF17212B);
    const muted = Color(0xFF8A9199);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: CustomAppBar(
        actions: const [],
        height: 82,
        radius: 44,
        title: Text('executeTheOrder'.tr),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: success.withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'yourOrderHasBeenSuccessfullyCompletedItWillBePreparedNow'.tr,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: textDark,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE7E9EC)),
                ),
                child: Text(
                  'طلب رقم  #${widget.args.id}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.045),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 190,
                      child: Image.asset(
                        AppImages.orderSuccessfullyImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(.055),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: primary.withOpacity(.16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.restaurant_menu_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'طلبك وصل للمطعم',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: textDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'سيبدأ تجهيز طلبك ويمكنك متابعة حالته لحظة بلحظة',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: muted,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _OrderProgress(primary: primary),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _trackOrder,
                  icon: const Icon(Icons.location_searching_rounded),
                  label: Text(
                    'trackingYourOrder'.tr,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _goHome,
                  icon: const Icon(Icons.home_rounded),
                  label: Text(
                    'backToHome'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textDark,
                    side: const BorderSide(color: Color(0xFFE2E5E9)),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              if (!isAcceptedFromDelegate) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _cancelOrder,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: Text('cancelOrder'.tr),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFD84A4A),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderProgress extends StatelessWidget {
  final Color primary;
  const _OrderProgress({required this.primary});

  @override
  Widget build(BuildContext context) {
    const inactive = Color(0xFFD9DDE2);

    return Row(
      children: [
        Expanded(
          child: _ProgressItem(
            icon: Icons.check_rounded,
            label: 'تم الطلب',
            active: true,
            color: primary,
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 24),
            color: inactive,
          ),
        ),
        Expanded(
          child: _ProgressItem(
            icon: Icons.restaurant_rounded,
            label: 'قيد التحضير',
            active: false,
            color: primary,
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 24),
            color: inactive,
          ),
        ),
        Expanded(
          child: _ProgressItem(
            icon: Icons.delivery_dining_rounded,
            label: 'في الطريق',
            active: false,
            color: primary,
          ),
        ),
      ],
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;

  const _ProgressItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: active ? color : const Color(0xFFF1F3F5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? Colors.white : const Color(0xFFADB3BA),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: active ? color : const Color(0xFF9299A1),
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
