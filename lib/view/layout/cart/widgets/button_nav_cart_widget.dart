import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';

class ButtonNavCartWidget extends StatelessWidget {
  final Function()? onPressedExecuteTheOrder;
  final Function()? onTapAddItems;
  final String totalInCart;

  const ButtonNavCartWidget({
    super.key,
    this.onPressedExecuteTheOrder,
    this.onTapAddItems,
    required this.totalInCart,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: FasakhanstaBrand.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: onPressedExecuteTheOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainAppColor,
                    foregroundColor: FasakhanstaBrand.onOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'continueToPayment'.tr,
                        style: AppTextStyle.text16BW(
                          color: FasakhanstaBrand.onOrange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: FasakhanstaBrand.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.mainAppColor.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'total'.tr,
                    style: AppTextStyle.text12RG().copyWith(
                      color: AppColors.greyColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'pound'.tr.replaceAll('{}', totalInCart),
                    style: AppTextStyle.text14BS().copyWith(
                      color: AppColors.mainAppColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
