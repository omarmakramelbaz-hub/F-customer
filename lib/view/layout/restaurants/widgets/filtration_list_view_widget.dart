import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../controller/restaurants_controller.dart';

class FiltrationListViewWidget extends StatefulWidget {
  final VoidCallback? onSuccess;
  const FiltrationListViewWidget({super.key, this.onSuccess});
  @override
  State<FiltrationListViewWidget> createState() =>
      _FiltrationListViewWidgetState();
}

class _FiltrationListViewWidgetState extends State<FiltrationListViewWidget> {
  List filtration = [
    'favorableRestaurants'.tr,
    'topRated'.tr,
    'mostSearched'.tr,
  ];
  int _currentIndex = -1;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Consumer<RestaurantsController>(
        builder: (context, restaurantsController, _) => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () {
              setState(() {
                if (_currentIndex == index) {
                  _currentIndex = -1;
                  restaurantsController.getRestaurants();
                } else {
                  _currentIndex = index;
                }
              });
              if (_currentIndex == 0) {
                restaurantsController.getRestaurants(
                  favorableRestaurants: 'yes',
                );
              } else if (_currentIndex == 1) {
                restaurantsController.getRestaurants(mostReviewed: 1);
              } else if (_currentIndex == 2) {
                restaurantsController.getRestaurants(mostResearched: 2);
              }
              widget.onSuccess?.call();
            },
            child: Row(
              children: [
                index != 0 ? const SizedBox() : const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppColors.yellowColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: FasakhanstaBrand.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        filtration[index],
                        style: _currentIndex == index
                            ? AppTextStyle.text16BW()
                            : AppTextStyle.text16MG(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: SvgPicture.asset(
                          AppImages.closeIcon,
                          colorFilter: ColorFilter.mode(
                            AppColors.whiteColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          itemCount: filtration.length,
        ),
      ),
    );
  }
}
