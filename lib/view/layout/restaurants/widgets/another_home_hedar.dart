import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../cart/controller/cart_controller.dart';
import '../../cart/screen/cart_screen.dart';
import '../../home/widgets/current_city_widget.dart';
import '../model/details_restaurants_model.dart';

class AnotherHomeHeaderCoverAndImageRestaurantDetailsWidget
    extends StatelessWidget {
  final DetailsRestaurantModel? detailsRestaurant;
  const AnotherHomeHeaderCoverAndImageRestaurantDetailsWidget({
    super.key,
    required this.detailsRestaurant,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxWidth * 0.5);
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Stack(
                  children: [
                    CustomImage(
                      path: AppImages.restAnotherHomeBG,
                      width: size.width,
                      height: size.height,
                      fit: BoxFit.cover,
                      type: ImageType.asset,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          20.sbH,
                          Text('deliveryTo'.tr, style: AppTextStyle.text18BW()),
                          CurrentCityWidget(onCityChanged: () {}),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 45,
                      left: 20,
                      child: InkWell(
                        onTap: () =>
                            NamedNavigatorImpl.push(CartScreen.routeName),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SvgPicture.asset(AppImages.nCartIcon),
                            Positioned(
                              bottom: 0,
                              right: -2,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.mainAppColor,
                                child: InkWell(
                                  onTap: () => NamedNavigatorImpl.push(
                                    CartScreen.routeName,
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      SvgPicture.asset(AppImages.nCartIcon),
                                      Positioned(
                                        bottom: 0,
                                        right: -2,
                                        child: CircleAvatar(
                                          radius: 8,
                                          backgroundColor:
                                              AppColors.darkMainAppColor,
                                          child: Text(
                                            context
                                                    .read<CartController>()
                                                    .cart
                                                    ?.carts
                                                    ?.length
                                                    .toString() ??
                                                '0',
                                            // context.read<HomeController>().countCart.toString(),
                                            style: AppTextStyle.text16BW()
                                                .copyWith(
                                              height: 1.4,
                                              fontSize: 14,
                                              color: FasakhanstaBrand.text,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: -70,
                  left: 20,
                  right: 20,
                  child: Container(
                    width: size.width,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: FasakhanstaBrand.surface,
                      border: Border.all(color: AppColors.borderColorContainer),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.borderColorContainer,
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundColor: FasakhanstaBrand.surface,
                                  radius: 30,
                                  child: CustomNetworkImage(
                                    imageUrl: detailsRestaurant?.logo ?? '',
                                    radius: 30,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    detailsRestaurant?.name ?? '',
                                    style: AppTextStyle.text18BS(),
                                  ),
                                  10.sbH,
                                  Container(
                                    padding: const EdgeInsets.only(
                                      left: 5,
                                      right: 5,
                                      top: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGreyColor,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SvgPicture.asset(AppImages.starIcon),
                                        const SizedBox(width: 5),
                                        Text(
                                          detailsRestaurant?.avgRate
                                                  ?.toStringAsFixed(1)
                                                  .toString() ??
                                              '',
                                          style: AppTextStyle.text14RS()
                                              .copyWith(height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time, size: 20),
                            const SizedBox(width: 5),
                            Text(
                              detailsRestaurant?.deliveryTime ?? '',
                              style: AppTextStyle.text14MS(),
                            ),
                            const SizedBox(width: 40),
                            const CustomImage(
                              path: AppImages.fastDeliveryImage,
                              width: 20,
                              type: ImageType.asset,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'egyPound'.tr.replaceAll(
                                    '{}',
                                    '${detailsRestaurant?.kmPrice.toString()}',
                                  ),
                              style: AppTextStyle.text14MS(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 70),
          ],
        );
      },
    );
  }
}
