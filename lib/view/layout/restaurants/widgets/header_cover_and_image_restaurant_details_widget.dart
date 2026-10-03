import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/restaurant_hours.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../controller/restaurants_controller.dart';
import '../model/details_restaurants_model.dart';

class HeaderCoverAndImageRestaurantDetailsWidget extends StatelessWidget {
  final DetailsRestaurantModel? detailsRestaurant;

  const HeaderCoverAndImageRestaurantDetailsWidget({
    super.key,
    required this.detailsRestaurant,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final imageHeight = (width * .42).clamp(150.0, 205.0);
        final hasAddress = (detailsRestaurant?.address ?? '').trim().isNotEmpty;
        final infoCardHeight = hasAddress ? 126.0 : 108.0;
        const overlap = 34.0;

        return SizedBox(
          width: width,
          height: imageHeight + infoCardHeight - overlap + 8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: imageHeight,
                child: CustomNetworkImage(
                  imageUrl: detailsRestaurant?.bgImage ?? '',
                  width: width,
                  height: imageHeight,
                  fit: BoxFit.cover,
                  radius: 0,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: imageHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .10),
                        Colors.black.withValues(alpha: .04),
                        Colors.black.withValues(alpha: .28),
                      ],
                      stops: const [0, .48, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 22,
                right: 16,
                child: _circleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                top: 22,
                left: 16,
                child: Row(
                  children: [
                    if (HiveMethods.getToken() != null) ...[
                      _circleButton(
                        icon: detailsRestaurant?.isFav == 1
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
                        iconColor: detailsRestaurant?.isFav == 1
                            ? AppColors.mainAppColor
                            : AppColors.secondAppColor,
                        onTap: () {
                          context.read<RestaurantsController>().addOrRemoveToWishlist(
                                id: detailsRestaurant?.id ?? 0,
                                onSuccess: () {
                                  detailsRestaurant?.isFav = detailsRestaurant?.isFav == 1 ? 0 : 1;
                                },
                              );
                        },
                      ),
                      const SizedBox(width: 9),
                    ],
                    _circleButton(
                      icon: Icons.share_outlined,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تجهيز مشاركة الفرع')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                top: imageHeight - overlap,
                left: 16,
                right: 16,
                height: infoCardHeight,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        detailsRestaurant?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.text20BS().copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('(تقييم)', style: AppTextStyle.text13RS()),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB400),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            detailsRestaurant?.avgRate?.toStringAsFixed(1) ?? '-',
                            style: AppTextStyle.text14BS(),
                          ),
                        ],
                      ),
                      if (hasAddress) ...[
                        const SizedBox(height: 7),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: AppColors.mainAppColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                detailsRestaurant?.address ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTextStyle.text12RS(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                top: imageHeight - 16,
                left: 28,
                child: _statusPill(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusPill(BuildContext context) {
    final status = detailsRestaurant?.status;
    final isClosed = status == 'closed';
    final isBusy = status == 'busy';
    final label = isClosed
        ? restaurantClosedLabel(context, detailsRestaurant?.openAt)
        : isBusy
            ? 'busy'.tr
            : 'مفتوح الآن';

    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: isClosed
                ? Colors.red
                : isBusy
                    ? Colors.orange
                    : Colors.green,
            size: 8,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.text12BS().copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.secondAppColor,
            size: 23,
          ),
        ),
      ),
    );
  }
}
