import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../bottom_navigation/bottom_navigation_bar_screen.dart';
import '../controller/request_delegate_controller.dart';
import '../model/accepted_delegate_model.dart';

class DelegateOfferWidget extends StatefulWidget {
  const DelegateOfferWidget({
    super.key,
    required this.acceptedDelegateModel,
    this.cancelReCall,
    this.onErrorCall,
    this.order,
    this.onReject,
  });
  final Delegates? acceptedDelegateModel;
  final VoidCallback? cancelReCall;
  final VoidCallback? onErrorCall;
  final VoidCallback? onReject;
  final Order? order;
  @override
  State<DelegateOfferWidget> createState() => _DelegateOfferWidgetState();
}

class _DelegateOfferWidgetState extends State<DelegateOfferWidget> {
  RequestDelegateController? requestDelegateController;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        requestDelegateController = Provider.of<RequestDelegateController>(context, listen: false);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestDelegateController>(
      builder: (context, requestDelegateController, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Card(
            color: AppColors.lightDarkColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CustomImage(
                        path: widget.acceptedDelegateModel?.photoProfile != null
                            ? widget.acceptedDelegateModel?.photoProfile ?? ''
                            : AppImages.delegateRDIcon,
                        type: widget.acceptedDelegateModel?.photoProfile != null ? ImageType.network : ImageType.svg,
                        height: 45,
                        width: 45,
                        radius: 25,
                        fit: BoxFit.cover,
                      ),
                      // const SizedBox(
                      //   width: 5,
                      // ),
                      Text(
                        widget.acceptedDelegateModel?.name ?? '',
                        style: AppTextStyle.text18RS().copyWith(color: AppColors.whiteColor),
                      ),

                      // const SizedBox(
                      //   width: 5,
                      // ),
                      // Row(
                      //   crossAxisAlignment: CrossAxisAlignment.start,
                      //   children: [
                      //     const CustomImage(
                      //         path: AppImages.starIcon, type: ImageType.svg),
                      //     const SizedBox(
                      //       width: 5,
                      //     ),
                      //     Text(
                      //       '4.5',
                      //       style: AppTextStyle.text14RS().copyWith(
                      //           color: AppColor.whiteColor, height: 1.4),
                      //     ),
                      //   ],
                      // ),
                      Text(
                        'deliveryCount'.tr.replaceAll(
                              '{}',
                              '${widget.acceptedDelegateModel?.completedOrdersCount ?? ""}',
                            ),
                        style: AppTextStyle.text14RS().copyWith(color: AppColors.whiteColor),
                      ),
                      Column(
                        children: [
                          Text(
                            requestDelegateController
                                .calculateExpectedDeliveryTime(
                                  averageSpeedKmPerHour: 30,
                                  toDLat: widget.acceptedDelegateModel?.lat ?? '',
                                  toDLng: widget.acceptedDelegateModel?.lng ?? '',
                                )
                                .toStringAsFixed(2),
                            style: AppTextStyle.text14RS().copyWith(color: AppColors.whiteColor),
                          ),
                          Text(
                            "${requestDelegateController.calculateDistanceInMeters(toDLat: widget.acceptedDelegateModel?.lat ?? "", toDLng: widget.acceptedDelegateModel?.lng ?? "").toStringAsFixed(2)} m",
                            style: AppTextStyle.text14RS().copyWith(color: AppColors.whiteColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(width: context.width * 0.2),
                      Text(
                        'egyp'.tr.replaceAll(
                              '{}',
                              '${widget.acceptedDelegateModel?.offerPrice ?? widget.order?.actualPrice ?? requestDelegateController.actualPrice}',
                            ),
                        style: AppTextStyle.text18RS().copyWith(color: AppColors.whiteColor),
                      ),
                    ],
                  ),
                  20.sbH,
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          height: 40,
                          text: context.languageCode == 'ar' ? 'قبول العرض' : 'Accept offer',
                          onPressed: () {
                            requestDelegateController.acceptedOrDeclinedDelegate(
                              orderId: requestDelegateController.orderId!,
                              delegateId: widget.acceptedDelegateModel!.id!,
                              status: 'accepted',
                              onSuccess: () {
                                widget.cancelReCall?.call();
                                NamedNavigatorImpl.push(
                                  clean: true,
                                  BottomNavigationBarScreen.routeName,
                                );
                              },
                              onError: () {},
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomButton(
                          height: 40,
                          text: 'reject'.tr,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.blackColor.withValues(alpha: 0.5),
                              AppColors.blackColor.withValues(alpha: 0.5),
                            ],
                          ),
                          onPressed: () {
                            requestDelegateController.acceptedOrDeclinedDelegate(
                              orderId: requestDelegateController.orderId!,
                              delegateId: widget.acceptedDelegateModel!.id!,
                              status: 'declined',
                              onSuccess: () {
                                widget.onReject?.call();
                              },
                              onError: () {
                                widget.onErrorCall?.call();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  20.sbH,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
