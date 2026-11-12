import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../controller/cart_controller.dart';
import '../model/user_cart_model.dart';

class OrdersInCartWidget extends StatelessWidget {
  final Carts cart;

  const OrdersInCartWidget({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    final cartController = context.read<CartController>();
    final quantity = cart.qty ?? 0;
    final unitPrice = double.tryParse(cart.price?.toString() ?? '') ?? 0;
    final total = unitPrice * quantity;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.greyColor.withValues(alpha: .15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductImage(),
          12.sbW,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cart.resturantProduct?.productName ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.text16BS(),
                ),
                if ((cart.resturantProduct?.productTitle ?? '').isNotEmpty) ...[
                  5.sbH,
                  Text(
                    cart.resturantProduct?.productTitle ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.text12RG(),
                  ),
                ],
                8.sbH,
                if (cart.productClean != null) ...[
                  _OptionChip(
                    text: getProductClean(cart.productClean ?? '') ?? '',
                  ),
                  4.sbH,
                ],
                if (cart.productFeatureName != null)
                  _OptionChip(
                    text:
                        getProductFeatureName(cart.productFeatureName ?? '') ??
                        '',
                  ),
                10.sbH,
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'pound'.translate(args: [total.toStringAsFixed(2)]),
                        style: AppTextStyle.text16MS().copyWith(
                          color: AppColors.mainAppColor,
                        ),
                      ),
                    ),
                    _buildQuantityControl(cartController, quantity),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return CustomNetworkImage(
      imageUrl: cart.resturantProduct?.productImage ?? '',
      height: 118,
      width: 112,
      radius: 16,
      fit: BoxFit.cover,
    );
  }

  Widget _buildQuantityControl(CartController controller, int quantity) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.mainAppColor.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.add,
            onTap: () => controller.incrementQty(cart),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$quantity', style: AppTextStyle.text14BS()),
          ),
          _QtyButton(
            icon: quantity == 1 ? Icons.delete_outline : Icons.remove,
            onTap: () {
              controller.decrementQty(cart);
              if (cart.qty == 0) controller.removeFromCart(cart);
            },
          ),
        ],
      ),
    );
  }

  String? getProductClean(String? productClean) {
    switch (productClean) {
      case 'extra_clean':
        return 'clean'.tr;
      case 'extra_clear':
        return 'clear'.tr;
      case 'extra_large':
        return 'large'.tr;
      case 'extra_medium':
        return 'medium'.tr;
      case 'extra_vacuim':
        return 'vacuum'.tr;
      case 'extra_combo':
        return 'combo'.tr;
      default:
        return '';
    }
  }

  String? getProductFeatureName(String? productFeatureName) {
    switch (productFeatureName) {
      case 'kilo':
        return 'kilo'.tr;
      case 'half':
        return 'half'.tr;
      case 'quarter':
        return 'quarter'.tr;
      default:
        return '';
    }
  }
}

class _OptionChip extends StatelessWidget {
  final String text;
  const _OptionChip({required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.greyColor.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(text, style: AppTextStyle.text12RG()),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 34,
        height: 38,
        child: Icon(icon, size: 18, color: AppColors.mainAppColor),
      ),
    );
  }
}
