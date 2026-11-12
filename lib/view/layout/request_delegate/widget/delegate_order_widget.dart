import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../model/request_delegate_order_model.dart';
import '../screen/tracking_delegate_order_screen.dart';

class DelegateOrderWidget extends StatelessWidget {
  const DelegateOrderWidget({
    super.key,
    required this.requestDelegateOrderModel,
  });
  final RequestDelegateOrderModel requestDelegateOrderModel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        NamedNavigatorImpl.push(
          TrackingDelegateOrderScreen.routeName,
          arguments: TrackingDelegateOrderArgs(
            id: requestDelegateOrderModel.id!,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: FasakhanstaBrand.surface,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.greyColor.withValues(alpha: 0.2),
                offset: const Offset(0, -3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    requestDelegateOrderModel.orderNo.toString(),
                    style: AppTextStyle.text16ML(),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      DateMethods.formatOrderDate(
                        requestDelegateOrderModel.createdAt.toString(),
                      ),
                      style: AppTextStyle.text16ML(),
                    ),
                  ),
                  buildOrderStatusContainer(
                    context: context,
                    orderStatus: requestDelegateOrderModel.status ?? '',
                  ),
                ],
              ),
              10.sbH,
              Text(
                requestDelegateOrderModel.description.toString(),
                style: AppTextStyle.text16MS(),
              ),
              15.sbH,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'pound'.tr.replaceAll(
                          '{}',
                          '${requestDelegateOrderModel.actualPrice}',
                        ),
                    style: AppTextStyle.text16RS(),
                  ),
                  (requestDelegateOrderModel.status == 'completed' ||
                          requestDelegateOrderModel.status == 'cancelled' ||
                          requestDelegateOrderModel.status == 'declined')
                      ? const SizedBox()
                      : Text(
                          'trackingYourOrder'.tr,
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
      ),
    );
  }

  Widget buildOrderStatusContainer({
    required String orderStatus,
    required BuildContext context,
  }) {
    switch (orderStatus) {
      case 'accepted':
        return Container(
          decoration: BoxDecoration(
            color: AppColors.yellowColor,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Text('orderAccepted'.tr, style: AppTextStyle.text14MW()),
          ),
        );
      case 'pending':
        return Container(
          decoration: BoxDecoration(
            color: AppColors.mainAppColor,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Text(
              'pending'.tr,
              style: AppTextStyle.text14MW(color: FasakhanstaBrand.onOrange),
            ),
          ),
        );
      case 'shipped':
        return Container(
          decoration: BoxDecoration(
            color: AppColors.greenColor,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Text('orderReceived'.tr, style: AppTextStyle.text14MW()),
          ),
        );

      case 'completed':
        return Container(
          decoration: BoxDecoration(
            color: AppColors.greyColor,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Text('orderDelivered'.tr, style: AppTextStyle.text14MW()),
          ),
        );
      case 'cancelled':
        return Container(
          decoration: BoxDecoration(
            color: AppColors.lightGreyColor,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Text('canceled'.tr, style: AppTextStyle.text14MS()),
          ),
        );
      case 'declined':
        return Container(
          decoration: BoxDecoration(
            color: AppColors.lightGreyColor,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Text('canceled'.tr, style: AppTextStyle.text14MS()),
          ),
        );
    }
    return Container();
  }
}
