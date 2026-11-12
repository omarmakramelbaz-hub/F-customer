import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/custom_slider/custom_slider.dart';
import '../../restaurants/screen/restaurants_screen.dart';
import '../controller/home_controller.dart';
import '../widgets/advertisement_container_widget.dart';
import '../widgets/restaurants_near_you_list_view_widget.dart';
import '../widgets/spacial_rest_widget.dart';

class SliderWidget extends StatelessWidget {
  final HomeController controller;

  const SliderWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final sliderData = controller.slider.isEmpty
        ? controller.defaultSlider
        : controller.slider;

    if (sliderData.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      child: CustomSlider(
        color: AppColors.mainAppColor,
        hasDots: sliderData.length > 1,
        isDotsOnContent: false,
        aspectRatio: 5.0,
        radius: 18,
        sliderArguments: List.generate(
          sliderData.length,
          (index) => SliderArguments(
            child: AdvertisementContainerWidget(
              restaurantId: sliderData[index].resturantId ?? 0,
              images: sliderData[index].imgaes?.isNotEmpty == true
                  ? sliderData[index].imgaes![0].url ?? ''
                  : '',
              title: sliderData[index].title ?? '',
              color: AppColors.mainAppColor,
            ),
          ),
        ),
      ),
    );
  }
}

class RestaurantsNearYouWidget extends StatelessWidget {
  final HomeController controller;

  const RestaurantsNearYouWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.restaurantsNearYou.isEmpty) {
      return const SizedBox.shrink();
    }

    final isGuest = HiveMethods.getToken() == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        22.sbH,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 22,
                color: AppColors.mainAppColor,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'مطاعم قريبة منك',
                  style: AppTextStyle.text18BS(),
                  textAlign: TextAlign.right,
                ),
              ),
              if (isGuest)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: FasakhanstaBrand.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.mainAppColor.withValues(alpha: .18),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: AppColors.mainAppColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'للمشاهدة فقط',
                        style: AppTextStyle.text10BW(
                          color: AppColors.mainAppColor,
                        ),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () =>
                      NamedNavigatorImpl.push(RestaurantsScreen.routeName),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'عرض الكل',
                          style: AppTextStyle.text13BS().copyWith(
                            color: AppColors.mainAppColor,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 22,
                          color: AppColors.mainAppColor,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        10.sbH,
        RestaurantsNearYouListViewWidget(
          restaurantsNearYou: controller.restaurantsNearYou,
        ),
      ],
    );
  }
}

class SpecialRestaurantsSectionWidget extends StatelessWidget {
  final HomeController controller;

  const SpecialRestaurantsSectionWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.spacialRestaurants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        10.sbH,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'favorableRestaurants'.tr,
            style: AppTextStyle.text16BS(),
          ),
        ),
        16.sbH,
        SpacialRestaurantsListViewWidget(
          spacialRest: controller.spacialRestaurants,
        ),
      ],
    );
  }
}
