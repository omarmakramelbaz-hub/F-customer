import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../auth/screen/register_screen.dart';
import '../controller/cart_controller.dart';

class CustomCartItemButtonBottomNavigation extends StatefulWidget {
  final int cartId;
  final int restaurantProductId;
  final String productFeature;
  final int? featureId;
  final num productPrice;
  final int qty;
  final int quantity;

  final String? productClean;
  final String? total;
  final VoidCallback? onSuccessAddItems;

  const CustomCartItemButtonBottomNavigation({
    super.key,
    required this.restaurantProductId,
    required this.productFeature,
    this.productClean,
    this.total,
    this.onSuccessAddItems,
    //(1,0.5,0.25)
    required this.qty,
    //(1||2....)
    required this.quantity,
    required this.featureId,
    required this.cartId,
    required this.productPrice,
  });

  @override
  State<CustomCartItemButtonBottomNavigation> createState() =>
      _CustomCartItemButtonBottomNavigationState();
}

class _CustomCartItemButtonBottomNavigationState
    extends State<CustomCartItemButtonBottomNavigation> {
  bool addToCartSelected = false;
  int _quantity = 0;
  @override
  void initState() {
    super.initState();
    _quantity = widget.quantity;
  }

  @override
  Widget build(BuildContext context) {
    log(widget.quantity.toString());
    log(widget.qty.toString());
    log(widget.total.toString());
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (HiveMethods.getToken() == null) {
                      CommonMethods.showChooseDialog(
                        context,
                        onPressed: () {
                          Navigator.pop(context);
                          NamedNavigatorImpl.push(RegisterScreen.routeName);
                        },
                        message: 'youMustLoginFirst'.tr,
                      );
                    } else if (addToCartSelected) {
                      context.read<CartController>().updateItemInCart(
                        cartId: widget.cartId,
                        restaurantProductId: widget.restaurantProductId,
                        productFeature: widget.featureId,
                        productClean: widget.productClean,
                        qty: widget.quantity,
                        onSuccess: () {
                          widget.onSuccessAddItems?.call();
                          //context.read<CartController>().getCart();
                        },
                        anotherCart: () {},
                      );
                    }
                    setState(() {
                      addToCartSelected = true;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    // height: 45,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 29,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mainAppColor,
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'saveChanges'.tr,
                            style: AppTextStyle.buttonStyle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // (widget.qty == 0)
                        //     ? Text(
                        //         widget.productPrice.toString(),
                        //         style: AppTextStyle.buttonStyle,
                        //       )
                        //     :
                        Text(
                          (double.parse(widget.total ?? '0') *
                                  widget.quantity /
                                  widget.qty)
                              .toString(),
                          style: AppTextStyle.buttonStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surface,
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.5),
                      blurRadius: 7,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _quantity++;
                        });
                      },
                      child: Icon(
                        Icons.add,
                        color: AppColors.yellowColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Text(_quantity.toString()),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () {
                        if (_quantity > 1) {
                          setState(() {
                            _quantity--;
                          });
                        }
                      },
                      child: Icon(
                        Icons.remove,
                        color: FasakhanstaBrand.text,
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
