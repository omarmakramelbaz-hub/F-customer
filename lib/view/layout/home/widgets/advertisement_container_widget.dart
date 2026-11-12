import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../restaurants/screen/restaurant_details_screen.dart';

class AdvertisementContainerWidget extends StatelessWidget {
  final String images;
  final String title;
  final int restaurantId;
  final Color color;

  const AdvertisementContainerWidget({
    super.key,
    required this.images,
    required this.title,
    required this.restaurantId,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    void openRestaurant() {
      if (restaurantId == 0) return;
      NamedNavigatorImpl.push(
        RestaurantDetailsScreen.routeName,
        arguments: RestaurantDetailsArgs(id: restaurantId),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.mainAppColor.withValues(alpha: .10),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.trim().isNotEmpty)
            CustomNetworkImage(
              imageUrl: images,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.fill,
            )
          else
            Container(color: color),
          if (restaurantId != 0)
            PositionedDirectional(
              end: 10,
              bottom: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: openRestaurant,
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: FasakhanstaBrand.surface.withValues(alpha: .96),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: AppColors.mainAppColor.withValues(alpha: .18),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20000000),
                          blurRadius: 7,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'buyNow'.tr,
                      style: AppTextStyle.text12BS().copyWith(
                        color: AppColors.mainAppColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
