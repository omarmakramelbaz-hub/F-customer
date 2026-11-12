import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../controller/restaurants_controller.dart';
import '../model/previous_order_model.dart';
import '../screen/product_details_screen.dart';

class PreviousOrdersListViewWidget extends StatelessWidget {
  const PreviousOrdersListViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantsController>(
      builder: (context, restaurantsController, _) {
        return SizedBox(
          height: 212,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: restaurantsController.previousOrders.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = restaurantsController.previousOrders[index];
              return _PreviousProductCard(
                item: item,
                restaurantClosed:
                    restaurantsController.detailsRestaurant?.status == 'closed',
              );
            },
          ),
        );
      },
    );
  }
}

class _PreviousProductCard extends StatelessWidget {
  final PreviousOrderModel item;
  final bool restaurantClosed;

  const _PreviousProductCard({
    required this.item,
    required this.restaurantClosed,
  });

  @override
  Widget build(BuildContext context) {
    final available = item.status == 'show';

    return GestureDetector(
      onTap: () {
        if (restaurantClosed) {
          CommonMethods.showError(message: 'thisRestaurantIsClosed'.tr);
          return;
        }

        if (!available) {
          CommonMethods.showError(message: 'productNotAvailable'.tr);
          return;
        }

        NamedNavigatorImpl.push(
          ProductDetailsScreen.routeName,
          arguments: ProductDetailsDetailsArgs(id: item.id ?? 0),
        );
      },
      child: Container(
        width: 155,
        decoration: BoxDecoration(
          color: FasakhanstaBrand.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FasakhanstaBrand.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              width: double.infinity,
              child: CustomNetworkImage(
                imageUrl: item.productImage ?? '',
                radius: 0,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Text(
                item.productName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.text14BS(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    available
                        ? '${item.productPrice?.toStringAsFixed(0) ?? '-'} ج'
                        : 'غير متاح',
                    style: AppTextStyle.text14BS().copyWith(
                      color: available
                          ? AppColors.mainAppColor
                          : AppColors.greyColor,
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: available
                          ? AppColors.mainAppColor
                          : AppColors.greyColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: FasakhanstaBrand.onOrange,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
