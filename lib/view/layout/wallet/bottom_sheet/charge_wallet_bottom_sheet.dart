import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/custom_payment_web_view/custom_payment_web_view.dart';
import '../../auth/controller/auth_controller.dart';
import '../../my_account/controller/my_account_controller.dart';
import '../controller/wallet_controller.dart';
import '../widget/chooseVCashOrVisaWidget.dart';

class ChargeWalletBottomSheet extends StatefulWidget {
  const ChargeWalletBottomSheet({
    super.key,
    required this.walletController,
    required this.myAccountController,
  });

  final WalletController walletController;
  final MyAccountController myAccountController;

  @override
  State<ChargeWalletBottomSheet> createState() =>
      _ChargeWalletBottomSheetState();
}

class _ChargeWalletBottomSheetState extends State<ChargeWalletBottomSheet> {
  void _pay(BuildContext context) {
    final walletController = widget.walletController;
    final authController = context.read<AuthController>();

    if (!walletController.chargeWalletFormKey.currentState!.validate()) {
      return;
    }

    if (walletController.selectedPayment == null) {
      CommonMethods.showError(message: 'youMustChoosePaymentMethod'.tr);
      return;
    }

    walletController.chargingWallet(
      amount: walletController.chargeAmountEc.text,
      onSuccess: (link) {
        NamedNavigatorImpl.push(
          CustomPaymentWebViewScreen.routeName,
          arguments: PaymentArgs(
            url: link,
            onFailed: () {
              CommonMethods.showError(message: 'paymentFailed'.tr);
            },
            onSuccess: () {
              Navigator.pop(context);
              walletController.getWallet();
              authController.getProfile();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletController = widget.walletController;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            child: Form(
              key: walletController.chargeWalletFormKey,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7D7D7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF6EE),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFD7B7),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 21,
                              color: AppColors.mainAppColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'walletCharging'.tr,
                                  style: AppTextStyle.text18BS(),
                                ),
                                const SizedBox(width: 7),
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 22,
                                  color: AppColors.mainAppColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              isArabic
                                  ? 'اختر وسيلة الدفع وأدخل المبلغ'
                                  : 'Choose a payment method and enter amount',
                              style: AppTextStyle.text11RG().copyWith(
                                color: AppColors.greyColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    const Divider(height: 1, color: Color(0xFFE9E9E9)),
                    const SizedBox(height: 9),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 142,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'chargeAmount'.tr,
                                style: AppTextStyle.text12BS(),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: walletController.chargeAmountEc,
                                focusNode:
                                    walletController.chargeAmountFocusNode,
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.ltr,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onFieldSubmitted: (_) => walletController
                                    .chargeAmountFocusNode
                                    .unfocus(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'enterAmount'.tr;
                                  }
                                  final amount = double.tryParse(value) ?? 0;
                                  if (amount < 50) {
                                    return 'minimumChargeAmount'
                                        .tr
                                        .replaceAll('{}', '50');
                                  }
                                  return null;
                                },
                                style: AppTextStyle.text15BS(),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: '0.00',
                                  hintStyle: AppTextStyle.text14RG().copyWith(
                                    color: const Color(0xFFB9B9B9),
                                  ),
                                  suffixText: isArabic ? 'جنيه' : 'EGP',
                                  suffixStyle: AppTextStyle.text11RG().copyWith(
                                    color: AppColors.darkTextColor,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: AppColors.mainAppColor,
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: AppColors.mainAppColor,
                                      width: 1.6,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: AppColors.redColor,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: AppColors.redColor,
                                      width: 1.4,
                                    ),
                                  ),
                                  errorStyle: const TextStyle(
                                    fontSize: 9,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isArabic
                                    ? 'اختر وسيلة الدفع'
                                    : 'Payment method',
                                style: AppTextStyle.text12BS(),
                              ),
                              const SizedBox(height: 6),
                              ChooseVCashOrVisaWidget(
                                myAccountController: widget.myAccountController,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF9F4),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 16,
                                  color: AppColors.mainAppColor,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    isArabic
                                        ? 'دفع آمن ومشفّر'
                                        : 'Secure encrypted payment',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyle.text10RG().copyWith(
                                      color: AppColors.greyColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 150,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () => _pay(context),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.mainAppColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline_rounded,
                                    size: 17),
                                const SizedBox(width: 6),
                                Text(
                                  'payNow'.tr,
                                  style: AppTextStyle.text14BS(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
