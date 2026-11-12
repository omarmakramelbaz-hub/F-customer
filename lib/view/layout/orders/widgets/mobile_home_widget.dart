import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/enum/order_status_enum.dart';
import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../../custom_widgets/custom_loading/custom_shimmer.dart';
import '../controller/last_order_controller.dart';

class MobileHomeWidget extends StatefulWidget {
  const MobileHomeWidget({super.key});

  @override
  State<MobileHomeWidget> createState() => _MobileHomeWidgetState();
}

class _MobileHomeWidgetState extends State<MobileHomeWidget> {
  late PusherController _pusherController; // Saved reference

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<LastCorderController>().initialLastOrders();
      context.read<LastCorderController>().getlastOrders();
    });
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('user.updated', _handleOrderUpdated);
    super.initState();
  }

  void _handleOrderUpdated(PusherEvent event) {
    try {
      if (!mounted) return;
      context.read<LastCorderController>().refreshLastOrders();
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LastCorderController>(
      builder: (context, lastOrderController, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: ApiResponseWidget(
            apiResponse: lastOrderController.lastOrdersApiResponse,
            onReload: lastOrderController.getlastOrders,
            isEmpty: lastOrderController.lastOrders == null,
            loadingWidget: CustomShimmer(
              height: 170,
              width: double.infinity,
              radius: 20,
              fillColor: AppColors.lightGreyColor,
              shimmerColor: AppColors.greyColor,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: FasakhanstaBrand.surfaceRaised,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CustomNetworkImage(
                          imageUrl:
                              lastOrderController.lastOrders?.resturantLogo ??
                                  '',
                          width: 50,
                          height: 50,
                          radius: 10,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          lastOrderController.lastOrders?.resturantName ?? '',
                          style: AppTextStyle.text18BS().copyWith(
                            color: FasakhanstaBrand.text,
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.mainAppColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Text(
                              lastOrderController.lastOrders?.status
                                      .toString()
                                      .tr ??
                                  '',
                              style: AppTextStyle.text14BS().copyWith(
                                color: FasakhanstaBrand.onOrange,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                    10.sbH,
                    Row(
                      children: [
                        Column(
                          children: [
                            Text(
                              'orderNumber'.translate(
                                args: [
                                  lastOrderController.lastOrders?.orderNo ?? '',
                                ],
                              ),
                              style: AppTextStyle.text14BS().copyWith(
                                color: FasakhanstaBrand.text,
                              ),
                            ),
                            10.sbH,
                            Text(
                              'Fasakhanesta',
                              style: AppTextStyle.text18BS().copyWith(
                                color: AppColors.mainAppColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        const Expanded(child: SizedBox()),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularPercentIndicator(
                            radius: 35.0,
                            lineWidth: 5.0,
                            percent: lastOrderController.lastOrders?.status ==
                                    OrderStatusEnum.pending.value
                                ? 0.25
                                : lastOrderController.lastOrders?.status ==
                                        OrderStatusEnum.accepted.value
                                    ? 0.5
                                    : lastOrderController.lastOrders?.status ==
                                            OrderStatusEnum.shipped.value
                                        ? 0.75
                                        : lastOrderController
                                                    .lastOrders?.status ==
                                                OrderStatusEnum.completed.value
                                            ? 1
                                            : 0,
                            center: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(AppImages.house),
                            ),
                            progressColor: AppColors.mainAppColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
