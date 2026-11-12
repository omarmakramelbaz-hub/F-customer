import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../my_account/controller/my_account_controller.dart';
import '../controller/cart_controller.dart';

class ChooseCashOrVisaOrVCashWidget extends StatelessWidget {
  const ChooseCashOrVisaOrVCashWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyAccountController()
        ..initialSetting()
        ..getSetting(),
      child: Consumer<MyAccountController>(
        builder: (context, controller, _) {
          return Column(
            children: [
              PaymentMethodWidget(
                icon: AppImages.cashIcon,
                label: 'cash'.tr,
                selectedPayment: 'cash',
              ),
              10.sbH,
              PaymentMethodWidget(
                icon: AppImages.walletImage,
                label: 'appWalletBalance'.tr,
                selectedPayment: 'wallet',
                isSvg: false,
              ),
              10.sbH,
              if (controller.setting?.paymentCardActivate == 'true') ...[
                PaymentMethodWidget(
                  icon: AppImages.visaIcon,
                  label: 'creditCard'.tr,
                  selectedPayment: 'online',
                ),
                10.sbH,
              ],
              if (controller.setting?.walletCardActivate == 'true')
                PaymentMethodWidget(
                  icon: AppImages.digitalWallet,
                  label: 'digitalWalletAndInstaPay'.tr,
                  selectedPayment: 'v_cash',
                  isSvg: false,
                ),
            ],
          );
        },
      ),
    );
  }
}

class PaymentMethodWidget extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSvg;
  final String selectedPayment;

  const PaymentMethodWidget({
    super.key,
    required this.icon,
    required this.label,
    this.isSvg = true,
    required this.selectedPayment,
  });

  @override
  Widget build(BuildContext context) {
    final cartController = context.watch<CartController>();
    final isSelected = cartController.selectedPayment == selectedPayment;

    return InkWell(
      onTap: () => cartController.setSelectedPayment(selectedPayment),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.mainAppColor.withValues(alpha: .07)
              : FasakhanstaBrand.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.mainAppColor : AppColors.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.mainAppColor.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: isSvg
                  ? SvgPicture.asset(icon, width: 24, height: 24)
                  : Image.asset(icon, height: 25),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTextStyle.text15MS())),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? AppColors.mainAppColor : AppColors.greyColor,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: isSelected
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.mainAppColor,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
