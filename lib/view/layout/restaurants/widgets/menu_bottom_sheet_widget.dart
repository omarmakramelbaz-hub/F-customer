import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../model/previous_order_model.dart';
import '../model/products_restaurant_model.dart';

class MenuBottomSheetWidget extends StatefulWidget {
  final List<ProductsRestaurantModel> products;
  final List<PreviousOrderModel> previousOrders;
  final Function(int index)? onSuccess;
  final int initialIndex; // Add this parameter

  const MenuBottomSheetWidget({
    super.key,
    required this.products,
    required this.previousOrders,
    this.onSuccess,
    this.initialIndex = 0,
  });

  @override
  State<MenuBottomSheetWidget> createState() => _MenuBottomSheetWidgetState();
}

class _MenuBottomSheetWidgetState extends State<MenuBottomSheetWidget> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.height * 0.8,
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('menu'.tr, style: AppTextStyle.text20BS()),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: FasakhanstaBrand.surface,
                      child: SvgPicture.asset(AppImages.closeIcon),
                    ),
                  ),
                ),
              ],
            ),
            15.sbH,
            const Divider(thickness: 1),
            15.sbH,
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _currentIndex = index;
                        });
                        Navigator.pop(context);
                        widget.onSuccess?.call(index - 1);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 12),
                        child: Row(
                          children: [
                            Container(
                              height: 24,
                              width: 5,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(7),
                                  bottomLeft: Radius.circular(7),
                                ),
                                color: _currentIndex == index
                                    ? AppColors.mainAppColor
                                    : Colors.transparent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'previousOrders'.tr,
                              style: AppTextStyle.text16BS(),
                            ),
                            const Spacer(),
                            Text(
                              widget.previousOrders.length.toString(),
                              style: AppTextStyle.text16BG(),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    final productIndex = index - 1;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _currentIndex = index;
                          Navigator.pop(context);
                          widget.onSuccess?.call(productIndex);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 12),
                        child: Row(
                          children: [
                            Container(
                              height: 24,
                              width: 5,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(7),
                                  bottomLeft: Radius.circular(7),
                                ),
                                color: _currentIndex == index
                                    ? AppColors.mainAppColor
                                    : Colors.transparent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              widget.products[productIndex].categoryName ?? '',
                              style: AppTextStyle.text16BS(),
                            ),
                            const Spacer(),
                            Text(
                              widget.products[productIndex].resturantItems
                                      ?.length
                                      .toString() ??
                                  '',
                              style: AppTextStyle.text16BG(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                separatorBuilder: (context, index) =>
                    const Divider(thickness: 1),
                itemCount: widget.products.length + 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
