import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/custom_slider/custom_slider.dart';
import '../../restaurants/screen/restaurants_screen.dart';
import '../controller/home_controller.dart';

class RestaurantsAndDelegateRequestWidget extends StatelessWidget {
  const RestaurantsAndDelegateRequestWidget({
    super.key,
    required this.controller,
  });
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: SizedBox(
        width: context.width * 0.44,
        height: 120,
        child: InkWell(
          onTap: () => NamedNavigatorImpl.push(RestaurantsScreen.routeName),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: SizedBox(
              child: Column(
                children: [
                  if (controller.restaurantsNearYou.isEmpty &&
                      controller.spacialRestaurants.isEmpty)
                    const CustomImage(
                      path: AppImages.restaurantHome,
                      type: ImageType.asset,
                      height: 75,
                    )
                  else
                    Expanded(
                      child: CustomSlider(
                        width: context.width / 3.7,
                        radius: 12,
                        color: Colors.transparent,
                        hasDots: false,
                        sliderArguments: [
                          ...List.generate(
                            controller.restaurantsNearYou.isEmpty
                                ? controller.spacialRestaurants.length
                                : (HiveMethods.getCity() == null)
                                ? controller.spacialRestaurants.length
                                : controller.restaurantsNearYou.length,
                            (index) {
                              return SliderArguments(
                                child: InkWell(
                                  child: CustomImage(
                                    width: context.width / 3.7,
                                    fit: BoxFit.contain,
                                    path: controller.restaurantsNearYou.isEmpty
                                        ? controller
                                                  .spacialRestaurants[index]
                                                  .logo ??
                                              ''
                                        : (HiveMethods.getCity() == null)
                                        ? controller
                                                  .spacialRestaurants[index]
                                                  .logo ??
                                              ''
                                        : controller
                                                  .restaurantsNearYou[index]
                                                  .logo ??
                                              '',
                                    type: ImageType.network,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  5.sbH,
                  Text('restaurants'.tr, style: AppTextStyle.text18MS()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
