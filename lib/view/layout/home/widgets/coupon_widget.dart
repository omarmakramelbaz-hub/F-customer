import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../controller/home_controller.dart';
import '../screen/draw_resturant_screen.dart';
import 'celebrate_widget.dart';

class CouponWidget extends StatelessWidget {
  const CouponWidget({super.key, required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.coupon?.winner != null && controller.coupon?.winner != '') {
      return CelebrateWidget(homeController: controller);
    } else {
      return InkWell(
        onTap: () => NamedNavigatorImpl.push(DrawRestaurantScreen.routeName),
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.mainAppColor,
            borderRadius: BorderRadius.circular(16),
          ),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              10.sbH,
              Text(
                'coupontext'.tr,
                style: AppTextStyle.text16BW(color: FasakhanstaBrand.onOrange),
              ),
              10.sbH,
              Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  CustomImage(
                    path: controller.coupon?.data?.image ?? '',
                    type: ImageType.network,
                    radius: 20,
                    width: double.infinity,
                    height: 165,
                    fit: BoxFit.fitWidth,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: FasakhanstaBrand.surfaceRaised.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'raffleRestaurantsShare'.tr,
                      style: AppTextStyle.text14BS(
                        color: FasakhanstaBrand.text,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
}
