import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/restaurant_hours.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../../custom_widgets/custom_loading/custom_shimmer.dart';
import '../../restaurants/screen/restaurant_details_screen.dart';
import '../controller/home_controller.dart';
import '../model/restaurants_near_you_home_model.dart';

class SpacialRestaurantsListViewWidget extends StatelessWidget {
  final List<RestaurantsNearYouHomeModel> spacialRest;

  const SpacialRestaurantsListViewWidget({super.key, required this.spacialRest});

  @override
  Widget build(BuildContext context) {
    return ApiResponseWidget(
      apiResponse: context.read<HomeController>().spacialRestaurantApiResponse,
      onReload: () => context.read<HomeController>().getSpacialRestaurants(
            lat: HiveMethods.getLat(),
            lng: HiveMethods.getLan(),
          ),
      isEmpty: context.read<HomeController>().spacialRestaurants.isEmpty,
      loadingWidget: CustomShimmer(
        height: 180,
        width: double.infinity,
        fillColor: AppColors.greyColor.withValues(alpha: 0.05),
        shimmerColor: AppColors.mainAppColor,
      ),
      child: SizedBox(
        height: 185,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: spacialRest.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final restaurant = spacialRest[index];
            final unavailable = restaurant.status == 'busy' ||
                restaurant.underContract == 'yes';

            return SizedBox(
              width: 155,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: unavailable
                    ? null
                    : () => NamedNavigatorImpl.push(
                          RestaurantDetailsScreen.routeName,
                          arguments: RestaurantDetailsArgs(id: restaurant.id ?? 0),
                        ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderColor.withValues(alpha: .65)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blackColor.withValues(alpha: .06),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          CustomNetworkImage(
                            imageUrl: restaurant.logo ?? '',
                            height: 105,
                            width: 155,
                            radius: 0,
                            fit: BoxFit.contain,
                          ),
                          if (restaurant.kmPrice == 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.mainAppColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CustomImage(
                                      path: AppImages.fastDeliveryImage,
                                      width: 13,
                                      type: ImageType.asset,
                                    ),
                                    3.sbW,
                                    Text(
                                      'freeDelivery'.tr,
                                      style: AppTextStyle.text12BW().copyWith(
                                        color: AppColors.whiteColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (unavailable || restaurant.status == 'closed')
                            Positioned.fill(
                              child: Container(
                                color: AppColors.blackColor.withValues(alpha: .48),
                                alignment: Alignment.center,
                                child: Text(
                                  restaurant.underContract == 'yes'
                                      ? 'underContract'.tr
                                      : restaurant.status == 'closed'
                                          ? restaurantClosedLabel(context, restaurant.openAt)
                                          : 'busy'.tr,
                                  style: AppTextStyle.text14MW(),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.name ?? '',
                              style: AppTextStyle.text14BS(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            5.sbH,
                            Row(
                              children: [
                                Icon(Icons.star_rounded, size: 16, color: AppColors.mainAppColor),
                                3.sbW,
                                Text(
                                  restaurant.avgRate?.toStringAsFixed(1) ?? '0.0',
                                  style: AppTextStyle.text12MS(),
                                ),
                                const Spacer(),
                                if (restaurant.deliveryTime != null)
                                  Flexible(
                                    child: Text(
                                      restaurant.deliveryTime!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyle.text12RS().copyWith(
                                        color: AppColors.lightTextColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
