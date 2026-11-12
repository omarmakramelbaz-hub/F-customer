import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../../custom_widgets/page_container/page_container.dart';
import '../controller/orders_controller.dart';
import '../widgets/in_preparation_widget.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late PusherController _pusherController; // Saved reference
  @override
  initState() {
    super.initState();
    _pusherController = context.read<PusherController>();

    _pusherController.addEventListener(
      'user.updated',
      (PusherEvent event) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<OrdersController>().initialOrders();
          context.read<OrdersController>().getOrders();
        });
      },

      //    _handleShippingUpdated
    );
  }

  // void _handleShippingUpdated(PusherEvent event) {
  //   try {
  //     final decodedData = json.decode(event.data) as Map<String, dynamic>;
  //     final orderData = decodedData['order_id'];
  //     var jsonData = jsonDecode(event.data) as Map<String, dynamic>;
  //     if (mounted) {
  //       var status = jsonData['order_id']['status']?.toString();
  //       var orderNo = jsonData['order_id']['order_no']?.toString();
  //       log("*************************************************************");
  //       log(jsonData.toString());
  //       if (status != null && status != "pending") {
  //         CommonMethods.showToast(
  //           message: "${'thereIsANewOrderWithStatus'.tr} $orderNo",
  //         );
  //       }
  //     }
  //     if (mounted) {
  //       final orderModel =
  //           OrdersModel.fromJson(orderData as Map<String, dynamic>);
  //       context.read<OrdersController>().updateOrder(orderModel);
  //     }
  //   } catch (e, stackTrace) {
  //     log("Error handling Pusher event: $e");
  //     log("Stack trace: $stackTrace");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageContainer(
        bottom: false,
        child: Consumer<OrdersController>(
          builder: (BuildContext context, ordersController, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 10,
                  ),
                  child: Text('orders'.tr, style: AppTextStyle.text18BS()),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FasakhanstaBrand.surface,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(36),
                        topLeft: Radius.circular(36),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.greyColor.withValues(alpha: .2),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await ordersController.getOrders();
                      },
                      child: ApiResponseWidget(
                        apiResponse: ordersController.ordersApiResponse,
                        onReload: () => ordersController.getOrders(),
                        isEmpty: ordersController.orders.isEmpty,
                        emptyWidget: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomImage(
                                  height: 100,
                                  path: AppImages.noOrderIcon,
                                  type: ImageType.svg,
                                ),
                              ],
                            ),
                            20.sbH,
                            Text(
                              'youHaveNoOrders'.tr,
                              style: AppTextStyle.text14BS(),
                            ),
                          ],
                        ),
                        loadingWidget: loadingWidget,
                        child: ListView.builder(
                          itemCount: ordersController.orders.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                15.sbH,
                                InPreparationWidget(
                                  orders: ordersController.orders[index],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 35),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget get loadingWidget {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Column(
            children: [
              15.sbH,
              Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 25,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                width: context.width * 0.9,
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.greyColor.withValues(alpha: .4),
                      blurRadius: 9,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('------------', style: AppTextStyle.text14RG()),
                        const Spacer(),
                        Container(
                          height: 30,
                          width: 100,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          decoration: BoxDecoration(
                            color: AppColors.greyColor.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text('', style: AppTextStyle.text14RG()),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const CustomNetworkImage(
                          radius: 12,
                          imageUrl: '',
                          width: 60,
                          height: 60,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('---------', style: AppTextStyle.text16RS()),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const SizedBox(width: 10),
                                  Text(
                                    '-----------',
                                    style: AppTextStyle.text14RL(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'requestAgain'.tr,
                          style: TextStyle(
                            color: AppColors.mainAppColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
