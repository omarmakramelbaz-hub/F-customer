import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../controller/cart_controller.dart';

class ExecuteOrderPricesWidget extends StatelessWidget {
  const ExecuteOrderPricesWidget({
    super.key,
    required this.totalPrice,
    required this.kmPrice,
    required this.serviceFees,
    required this.cartController,
    required this.addedPrice,
    required this.resturantMinOrderPrice,
  });

  final double totalPrice;
  final num kmPrice;
  final num serviceFees;
  final num addedPrice;
  final num resturantMinOrderPrice;
  final CartController cartController;

  @override
  Widget build(BuildContext context) {
    final grandTotal = totalPrice + serviceFees + kmPrice + addedPrice;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.greyColor.withValues(alpha: .12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.mainAppColor.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.mainAppColor,
                ),
              ),
              const SizedBox(width: 10),
              Text('paymentSummary'.tr, style: AppTextStyle.text17BS()),
            ],
          ),
          const SizedBox(height: 18),
          _row('subtotal'.tr, totalPrice, false),
          const SizedBox(height: 12),
          _row('deliveryCharges'.tr, kmPrice, kmPrice == 0),
          const SizedBox(height: 12),
          _row('serviceFees'.tr, serviceFees, false),
          const SizedBox(height: 12),
          _row('addedValuePrice'.tr, addedPrice, false),
          const SizedBox(height: 14),
          Divider(color: AppColors.greyColor.withValues(alpha: .2)),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('total'.tr, style: AppTextStyle.text17BS()),
              const Spacer(),
              Text(
                'pound'.tr.replaceAll('{}', grandTotal.toStringAsFixed(2)),
                style: AppTextStyle.text19BS().copyWith(
                  color: AppColors.mainAppColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String title, num value, bool free) {
    return Row(
      children: [
        Text(title, style: AppTextStyle.text14RG()),
        const Spacer(),
        Text(
          free
              ? 'free'.tr
              : 'pound'.tr.replaceAll('{}', value.toStringAsFixed(2)),
          style: AppTextStyle.text14RM().copyWith(
            color: free ? AppColors.mainAppColor : null,
          ),
        ),
      ],
    );
  }
}
