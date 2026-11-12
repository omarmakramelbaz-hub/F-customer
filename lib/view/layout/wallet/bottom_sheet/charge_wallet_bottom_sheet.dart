import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/custom_payment_web_view/custom_payment_web_view.dart';
import '../../auth/controller/auth_controller.dart';
import '../../my_account/controller/my_account_controller.dart';
import '../controller/wallet_controller.dart';
import '../model/wallet_checkout.dart';
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
  Future<void> _pay(BuildContext context) async {
    final walletController = widget.walletController;
    if (walletController.isCreatingCheckout) return;
    final authController = context.read<AuthController>();
    final sessionToken = HiveMethods.getToken();

    if (!(walletController.chargeWalletFormKey.currentState?.validate() ??
        false)) {
      return;
    }

    if (walletController.selectedPayment == null) {
      CommonMethods.showError(message: 'youMustChoosePaymentMethod'.tr);
      return;
    }

    final checkout = await walletController.chargingWallet(
      amount: walletController.chargeAmountEc.text,
    );
    if (!mounted ||
        !context.mounted ||
        checkout == null ||
        HiveMethods.getToken() != sessionToken ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    NamedNavigatorImpl.push(
      CustomPaymentWebViewScreen.routeName,
      arguments: PaymentArgs(
        url: checkout.url,
        // Wallet orders have their own settlement flow. The restaurant
        // order monitor must not treat a top-up as a food order.
        onFailed: () {
          if (mounted &&
              context.mounted &&
              HiveMethods.getToken() == sessionToken) {
            CommonMethods.showError(message: 'paymentFailed'.tr);
          }
        },
        onSuccess: () {
          if (!mounted ||
              !context.mounted ||
              HiveMethods.getToken() != sessionToken) {
            return;
          }
          if (ModalRoute.of(context)?.isCurrent ?? true) {
            Navigator.pop(context);
          }
          walletController.getWallet();
          authController.getProfile();
        },
      ),
    );
  }

  @override
  void dispose() {
    widget.walletController.cancelCheckoutCreation(notify: false);
    super.dispose();
  }

  String _errorText(WalletCheckoutError error, bool isArabic) {
    if ((error.type == WalletCheckoutErrorType.rejected ||
            error.type == WalletCheckoutErrorType.invalidResponse) &&
        error.message != null) {
      return error.message!;
    }
    return switch (error.type) {
      WalletCheckoutErrorType.offline => isArabic
          ? 'اتأكد من اتصال الإنترنت وحاول تاني.'
          : 'Check your internet connection and try again.',
      WalletCheckoutErrorType.timedOut => isArabic
          ? 'فتح صفحة الدفع اتأخر. انتظر قليلًا قبل المحاولة مرة أخرى.'
          : 'Opening payment took too long. Please wait a moment before trying again.',
      WalletCheckoutErrorType.signInRequired => isArabic
          ? 'سجّل دخولك مرة أخرى لفتح صفحة الدفع.'
          : 'Please sign in again to open payment.',
      _ => isArabic
          ? 'تعذّر فتح صفحة الدفع. حاول مرة أخرى بعد قليل.'
          : 'Could not open payment. Please try again shortly.',
    };
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.walletController,
        builder: (context, _) => _buildSheet(context),
      );

  Widget _buildSheet(BuildContext context) {
    final walletController = widget.walletController;
    final isCreatingCheckout = walletController.isCreatingCheckout;
    final checkoutError = walletController.checkoutError;
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
              color: FasakhanstaBrand.surface,
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
                        color: FasakhanstaBrand.surfaceRaised,
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
                              color: FasakhanstaBrand.surfaceRaised,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: FasakhanstaBrand.border,
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
                    const Divider(height: 1, color: FasakhanstaBrand.border),
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
                                enabled: !isCreatingCheckout,
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
                                    return 'minimumChargeAmount'.tr.replaceAll(
                                          '{}',
                                          '50',
                                        );
                                  }
                                  return null;
                                },
                                style: AppTextStyle.text15BS(),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: '0.00',
                                  hintStyle: AppTextStyle.text14RG().copyWith(
                                    color: FasakhanstaBrand.muted,
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
                                  fillColor: FasakhanstaBrand.field,
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
                              AbsorbPointer(
                                absorbing: isCreatingCheckout,
                                child: ExcludeFocus(
                                  excluding: isCreatingCheckout,
                                  child: ChooseVCashOrVisaWidget(
                                    myAccountController:
                                        widget.myAccountController,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (checkoutError != null)
                      Semantics(
                        liveRegion: true,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _errorText(checkoutError, isArabic),
                            key: const ValueKey('wallet-checkout-error'),
                            textAlign: TextAlign.center,
                            style: AppTextStyle.text12BS().copyWith(
                              color: AppColors.redColor,
                            ),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: FasakhanstaBrand.surfaceRaised,
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
                            key: const ValueKey('wallet-checkout-submit'),
                            onPressed:
                                isCreatingCheckout ? null : () => _pay(context),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.mainAppColor,
                              foregroundColor: FasakhanstaBrand.onOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isCreatingCheckout)
                                  const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 17,
                                  ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    isCreatingCheckout
                                        ? (isArabic
                                            ? 'جارٍ فتح الدفع'
                                            : 'Opening payment')
                                        : 'payNow'.tr,
                                    style: AppTextStyle.text14BS(
                                      color: FasakhanstaBrand.onOrange,
                                    ),
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
