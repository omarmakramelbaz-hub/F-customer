import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/restaurant_hours.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../controller/restaurants_controller.dart';
import '../screen/restaurant_details_screen.dart';

class AllRestaurantsWidget extends StatefulWidget {
  const AllRestaurantsWidget({super.key});

  @override
  State<AllRestaurantsWidget> createState() => _AllRestaurantsWidgetState();
}

class _AllRestaurantsWidgetState extends State<AllRestaurantsWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
        isFront = !isFront;
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
        isFront = !isFront;
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantsController>(
      builder: (context, restaurantsController, _) => ApiResponseWidget(
        apiResponse: restaurantsController.restaurantsApiResponse,
        onReload: () => restaurantsController.getRestaurants(),
        isEmpty: restaurantsController.restaurant.isEmpty,
        child: ListView.builder(
          itemCount: restaurantsController.restaurant.length,
          itemBuilder: (context, index) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                restaurantsController.restaurant[index].status == 'busy' ||
                        restaurantsController.restaurant[index].underContract == 'yes'
                    ? null
                    : NamedNavigatorImpl.push(
                        RestaurantDetailsScreen.routeName,
                        arguments: RestaurantDetailsArgs(id: restaurantsController.restaurant[index].id!),
                      );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CustomNetworkImage(
                        imageUrl: restaurantsController.restaurant[index].logo ?? '',
                        height: 65,
                        width: 95,
                        radius: 15,
                        fit: BoxFit.contain,
                      ),
                      Positioned.fill(
                        child: restaurantsController.restaurant[index].status == 'closed' ||
                                restaurantsController.restaurant[index].status == 'busy' ||
                                restaurantsController.restaurant[index].underContract == 'yes'
                            ? Container(
                                height: 65,
                                width: 95,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.blackColor.withValues(alpha: 0.6),
                                      blurRadius: 1,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        restaurantsController.restaurant[index].underContract == 'yes'
                                            ? 'underContract'.tr
                                            : restaurantsController.restaurant[index].status == 'closed'
                                                ? restaurantClosedLabel(
                                                    context,
                                                    restaurantsController.restaurant[index].openAt,
                                                  )
                                                : 'busy'.tr,
                                        style: AppTextStyle.text18MW().copyWith(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ),
                      Positioned(
                        top: 5,
                        left: 5,
                        child: restaurantsController.restaurant[index].kmPrice == 0 &&
                                restaurantsController.restaurant[index].underContract != 'yes'
                            ? const CustomImage(path: AppImages.freeDeliveryImage, type: ImageType.asset, height: 25)
                            : const SizedBox(),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        15.sbH,
                        Text(restaurantsController.restaurant[index].name ?? '', style: AppTextStyle.text14RS()),
                        10.sbH,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SvgPicture.asset(AppImages.starIcon),
                            const SizedBox(width: 8),
                            Text(
                              restaurantsController.restaurant[index].avgRate!.toStringAsFixed(1).toString(),
                              style: AppTextStyle.text14RS().copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  restaurantsController.restaurant[index].deliveryTime == null
                      ? const SizedBox()
                      : Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: SvgPicture.asset(AppImages.clockIcon),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                restaurantsController.restaurant[index].deliveryTime ?? '',
                                style: AppTextStyle.text14RG().copyWith(fontWeight: FontWeight.w300),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
