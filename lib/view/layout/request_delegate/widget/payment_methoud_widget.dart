import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../my_account/controller/my_account_controller.dart';
import '../controller/request_delegate_controller.dart';

class ChoosePaymentMethodWidget extends StatelessWidget {
  const ChoosePaymentMethodWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyAccountController()
        ..initialSetting()
        ..getSetting(),
      child: Consumer<MyAccountController>(
        builder: (context, myAccountController, _) {
          return Column(
            children: [
              PaymentMethodWidget(
                label: 'cash'.tr,
                selectedPayment: 'cash',
                leading: CustomImage(
                  path: AppImages.cashIcon,
                  type: ImageType.svg,
                  color: AppColors.mainAppColor,
                  height: 22,
                ),
              ),
              const SizedBox(height: 10),
              PaymentMethodWidget(
                label: 'appWalletBalance'.tr,
                selectedPayment: 'wallet',
                leading: CustomImage(
                  path: AppImages.payWalletIcon,
                  type: ImageType.svg,
                  color: AppColors.mainAppColor,
                  height: 21,
                ),
              ),
              if (myAccountController.setting?.paymentCardActivate ==
                  'true') ...[
                const SizedBox(height: 10),
                PaymentMethodWidget(
                  label: 'creditCard'.tr,
                  selectedPayment: 'online',
                  leading: const CustomImage(
                    path: AppImages.visaIcon,
                    type: ImageType.svg,
                    height: 22,
                  ),
                ),
              ],
              if (myAccountController.setting?.walletCardActivate ==
                  'true') ...[
                const SizedBox(height: 10),
                PaymentMethodWidget(
                  label: 'digitalWalletAndInstaPay'.tr,
                  selectedPayment: 'v_cash',
                  leading: const CustomImage(
                    path: AppImages.vfCash,
                    type: ImageType.asset,
                    height: 22,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class PaymentMethodWidget extends StatelessWidget {
  final String label;
  final String selectedPayment;
  final String? iconColor;
  final Widget leading;

  const PaymentMethodWidget({
    super.key,
    required this.label,
    required this.selectedPayment,
    this.iconColor,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final requestDelegateController =
        context.watch<RequestDelegateController>();
    final isSelected =
        requestDelegateController.selectedPayment == selectedPayment;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () =>
            requestDelegateController.setSelectedPayment(selectedPayment),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: isSelected
                ? FasakhanstaBrand.surfaceRaised
                : FasakhanstaBrand.surface,
            border: Border.all(
              color:
                  isSelected ? AppColors.mainAppColor : FasakhanstaBrand.border,
              width: isSelected ? 1.3 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surfaceRaised,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: leading,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.text16MS().copyWith(
                    color: FasakhanstaBrand.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? AppColors.mainAppColor : Colors.transparent,
                  border: Border.all(
                    width: 1.4,
                    color: isSelected
                        ? AppColors.mainAppColor
                        : FasakhanstaBrand.border,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: FasakhanstaBrand.onOrange,
                        size: 15,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
