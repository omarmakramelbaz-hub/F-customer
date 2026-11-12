import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/custom_toast/custom_toast.dart';
import '../../auth/screen/register_screen.dart';
import '../../cart/controller/cart_controller.dart';
import '../controller/restaurants_controller.dart';

class CustomButtonBottomNavigation extends StatefulWidget {
  final int restaurantProductId;
  final String productFeature;
  final int? featureId;
  final int qty;
  final String? productClean;
  final String? total;
  final VoidCallback? onSuccessAddItems;

  const CustomButtonBottomNavigation({
    super.key,
    required this.restaurantProductId,
    required this.productFeature,
    this.productClean,
    this.total,
    this.onSuccessAddItems,
    required this.qty,
    required this.featureId,
  });

  @override
  State<CustomButtonBottomNavigation> createState() =>
      _CustomButtonBottomNavigationState();
}

class _CustomButtonBottomNavigationState
    extends State<CustomButtonBottomNavigation> {
  bool addToCartSelected = false;
  int count = 1;

  int get _baseTotal => int.tryParse(widget.total ?? '0') ?? 0;

  int _displayPrice(CartController controller) {
    final currentTotal = int.tryParse(controller.totalCountAddTCart ?? '') ??
        (_baseTotal * count);
    final divider = widget.qty <= 0 ? 1 : widget.qty;
    return (currentTotal / divider).round();
  }

  @override
  Widget build(BuildContext context) {
    final cartController = context.watch<CartController>();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: FasakhanstaBrand.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 22,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            if (!addToCartSelected)
              SizedBox(
                width: 92,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_displayPrice(cartController)} ج',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.text20BS(
                        color: AppColors.mainAppColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('السعر الإجمالي', style: AppTextStyle.text11RG()),
                  ],
                ),
              )
            else
              _buildQuantityStepper(cartController),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _handleAddTap(context, cartController),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.mainAppColor,
                    foregroundColor: FasakhanstaBrand.onOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 22),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'addToCart'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.text16BW(
                            color: FasakhanstaBrand.onOrange,
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
    );
  }

  Widget _buildQuantityStepper(CartController controller) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FasakhanstaBrand.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(
            icon: Icons.add_rounded,
            onTap: () {
              setState(() {
                count++;
                controller.totalCountAddTCart = (_baseTotal * count).toString();
              });
            },
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: AppTextStyle.text15BS(),
            ),
          ),
          _stepperButton(
            icon: Icons.remove_rounded,
            onTap: () {
              if (count <= 1) return;
              setState(() {
                count--;
                controller.totalCountAddTCart = (_baseTotal * count).toString();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: SizedBox(
        width: 30,
        height: 36,
        child: Icon(icon, size: 19, color: AppColors.mainAppColor),
      ),
    );
  }

  int? _currentRestaurantId(BuildContext context) {
    try {
      return context
          .read<RestaurantsController>()
          .productsDetailsRestaurant
          ?.resturantId;
    } catch (_) {
      return null;
    }
  }

  bool _cartContainsAnotherRestaurant(
    CartController controller,
    int restaurantId,
  ) {
    final restaurantIds = <int>{};
    final cart = controller.cart;

    final cartRestaurantId = cart?.resturant?.resturantId;
    if (cartRestaurantId != null) restaurantIds.add(cartRestaurantId);

    for (final item in cart?.carts ?? const []) {
      final id = item.resturantId ?? item.resturantProduct?.resturantId;
      if (id != null) restaurantIds.add(id);
    }

    if (restaurantIds.isEmpty) return false;
    return restaurantIds.length > 1 || !restaurantIds.contains(restaurantId);
  }

  void _showDifferentRestaurantError(
    BuildContext context,
    CartController cartController,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    BotToast.showCustomText(
      duration: const Duration(seconds: 8),
      toastBuilder: (cancelFunc) => CustomToast(
        type: ToastType.error,
        title: isArabic ? 'سلة من مطعم آخر' : 'Different restaurant cart',
        message: isArabic
            ? 'السلة الحالية تحتوي على منتجات من مطعم آخر. يمكنك حذفها الآن وإنشاء سلة جديدة لهذا المطعم.'
            : 'Your current cart contains items from another restaurant. Clear it now to start a new cart for this restaurant.',
        onClose: cancelFunc,
        actionLabel: isArabic ? 'حذف السلة الحالية' : 'Clear current cart',
        actionIcon: Icons.delete_outline_rounded,
        onAction: () {
          cancelFunc();
          cartController.emptyCart(
            onSuccess: () async {
              await cartController.getCart();
              if (!mounted) return;
              setState(() {
                addToCartSelected = true;
                count = 1;
                cartController.totalCountAddTCart = null;
              });
            },
          );
        },
      ),
    );
  }

  Future<void> _handleAddTap(
    BuildContext context,
    CartController cartController,
  ) async {
    if (HiveMethods.getToken() == null) {
      CommonMethods.showChooseDialog(
        context,
        onPressed: () {
          Navigator.pop(context);
          NamedNavigatorImpl.push(RegisterScreen.routeName);
        },
        message: 'youMustLoginFirst'.tr,
      );
      return;
    }

    if (!addToCartSelected) {
      setState(() {
        addToCartSelected = true;
        count = 1;
        cartController.totalCountAddTCart = null;
      });
      return;
    }

    final currentRestaurantId = _currentRestaurantId(context);
    if (currentRestaurantId != null) {
      if (cartController.cart == null) {
        await cartController.getCart();
      }

      if (_cartContainsAnotherRestaurant(cartController, currentRestaurantId)) {
        _showDifferentRestaurantError(context, cartController);
        return;
      }
    }

    cartController.addToCart(
      restaurantProductId: widget.restaurantProductId,
      productFeature: widget.featureId,
      productClean: widget.productClean,
      qty: count,
      onSuccess: () {
        widget.onSuccessAddItems?.call();
        cartController.getCart();
      },
      anotherCart: () => _showDifferentRestaurantError(context, cartController),
    );
  }
}
