import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/theme/fasakhansta_brand.dart';
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
  void initState() {
    super.initState();
    if (widget.walletController.chargeAmountEc.text.trim().isEmpty) {
      widget.walletController.chargeAmountEc.text = '50';
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.walletController,
        builder: (context, _) => ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.walletController.chargeAmountEc,
          builder: (context, value, _) => _buildSheet(context),
        ),
      );

  Widget _buildSheet(BuildContext context) {
    final controller = widget.walletController;
    final busy = controller.isCreatingCheckout;
    final error = controller.checkoutError;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final media = MediaQuery.of(context);
    final amount = int.tryParse(controller.chargeAmountEc.text.trim());
    final validAmount = amount != null && amount >= 50;
    final balance = controller.wallet?.balance;
    final liveSettings = context.watch<MyAccountController>().setting;
    final settings = liveSettings ?? widget.myAccountController.setting;
    final methodAvailable = switch (controller.selectedPayment) {
      'online' => settings?.paymentCardActivate == 'true',
      'v_cash' => settings?.walletCardActivate == 'true',
      _ => false,
    };
    final currency = isArabic ? 'ج.م' : 'EGP';

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: (media.size.height -
                      media.viewInsets.bottom -
                      media.padding.top -
                      16)
                  .clamp(0, double.infinity),
            ),
            child: Material(
              color: FasakhanstaBrand.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
                child: Form(
                  key: controller.chargeWalletFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: FasakhanstaBrand.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _header(context, isArabic),
                      const SizedBox(height: 24),
                      Text(
                        isArabic ? 'عايز تشحن بكام؟' : 'How much to add?',
                        style: AppTextStyle.text16BS(),
                      ),
                      const SizedBox(height: 12),
                      _amountField(context, isArabic, busy),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final quickAmount in [50, 100, 200, 500]) ...[
                            if (quickAmount != 50) const SizedBox(width: 8),
                            Expanded(
                              child: _quickAmount(
                                value: quickAmount,
                                selected: amount == quickAmount,
                                busy: busy,
                                currency: currency,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isArabic ? 'اختار وسيلة الدفع' : 'Payment method',
                        style: AppTextStyle.text16BS(),
                      ),
                      const SizedBox(height: 12),
                      AbsorbPointer(
                        absorbing: busy,
                        child: ExcludeFocus(
                          excluding: busy,
                          child: ChooseVCashOrVisaWidget(
                            myAccountController: widget.myAccountController,
                          ),
                        ),
                      ),
                      if (balance != null && balance.isFinite) ...[
                        const SizedBox(height: 20),
                        Semantics(
                          liveRegion: true,
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              Text(
                                isArabic
                                    ? 'رصيدك بعد نجاح الشحن'
                                    : 'Balance after successful payment',
                                style: AppTextStyle.text13RG(),
                              ),
                              Text(
                                validAmount
                                    ? '${NumberFormat('#,##0.00', 'en').format((balance * 100).round() / 100 + amount)} $currency'
                                    : '— $currency',
                                key: const ValueKey(
                                  'wallet-balance-after-charge',
                                ),
                                textDirection: TextDirection.ltr,
                                style: AppTextStyle.text17BS(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (error != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _errorText(error, isArabic),
                            key: const ValueKey('wallet-checkout-error'),
                            textAlign: TextAlign.center,
                            style: AppTextStyle.text12BS(
                              color: FasakhanstaBrand.danger,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        key: const ValueKey('wallet-checkout-submit'),
                        onPressed: busy || !validAmount || !methodAvailable
                            ? null
                            : () {
                                controller.chargeAmountFocusNode.unfocus();
                                _pay(context);
                              },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: FasakhanstaBrand.orange,
                          foregroundColor: FasakhanstaBrand.onOrange,
                          disabledBackgroundColor: busy
                              ? FasakhanstaBrand.orange
                              : FasakhanstaBrand.surfaceRaised,
                          disabledForegroundColor: busy
                              ? FasakhanstaBrand.onOrange
                              : FasakhanstaBrand.muted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: busy
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: FasakhanstaBrand.onOrange,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      isArabic
                                          ? 'جارٍ فتح الدفع'
                                          : 'Opening payment',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          isArabic
                                              ? 'متابعة الدفع'
                                              : 'Continue to payment',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '${validAmount ? NumberFormat.decimalPattern('en').format(amount) : '—'} $currency',
                                          key: const ValueKey(
                                            'wallet-checkout-amount',
                                          ),
                                          textDirection: TextDirection.ltr,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 14,
                            color: FasakhanstaBrand.muted,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isArabic
                                  ? 'يتم إضافة الرصيد بعد تأكيد نجاح الدفع'
                                  : 'Balance is added after payment is confirmed',
                              textAlign: TextAlign.center,
                              style: AppTextStyle.text11RG(),
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
      ),
    );
  }

  Widget _header(BuildContext context, bool isArabic) => Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: FasakhanstaBrand.orangeTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: FasakhanstaBrand.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('walletCharging'.tr, style: AppTextStyle.text22BS()),
                const SizedBox(height: 3),
                Text(
                  isArabic
                      ? 'رصيدك جاهز لطلبك الجاي'
                      : 'Ready for your next order',
                  style: AppTextStyle.text12RG(),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 22),
            color: FasakhanstaBrand.muted,
          ),
        ],
      );

  Widget _amountField(BuildContext context, bool isArabic, bool busy) {
    final controller = widget.walletController;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.field,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FasakhanstaBrand.orangeBorder),
      ),
      child: Column(
        children: [
          TextFormField(
            key: const ValueKey('wallet-recharge-amount'),
            enabled: !busy,
            controller: controller.chargeAmountEc,
            focusNode: controller.chargeAmountFocusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                final normalized = newValue.text.replaceAllMapped(
                  RegExp('[٠-٩۰-۹]'),
                  (match) {
                    final code = match[0]!.codeUnitAt(0);
                    return (code - (code <= 0x669 ? 0x660 : 0x6f0)).toString();
                  },
                );
                return newValue.copyWith(text: normalized);
              }),
              FilteringTextInputFormatter.digitsOnly,
            ],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onFieldSubmitted: (_) => controller.chargeAmountFocusNode.unfocus(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'enterAmount'.tr;
              }
              if ((int.tryParse(value) ?? 0) < 50) {
                return 'minimumChargeAmount'.tr.replaceAll('{}', '50');
              }
              return null;
            },
            style: AppTextStyle.text24BS().copyWith(fontSize: 46, height: 1.15),
            decoration: const InputDecoration(
              isDense: true,
              filled: false,
              hintText: '50',
              hintStyle: TextStyle(color: FasakhanstaBrand.muted),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              errorMaxLines: 2,
              errorStyle: TextStyle(
                color: FasakhanstaBrand.danger,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isArabic ? 'جنيه مصري' : 'Egyptian pounds',
            style: AppTextStyle.text13RM(),
          ),
          const SizedBox(height: 12),
          Text(
            isArabic
                ? 'أدخل المبلغ أو اختار من المبالغ السريعة'
                : 'Enter an amount or choose a quick amount',
            textAlign: TextAlign.center,
            style: AppTextStyle.text11RG(),
          ),
        ],
      ),
    );
  }

  Widget _quickAmount({
    required int value,
    required bool selected,
    required bool busy,
    required String currency,
  }) =>
      Semantics(
        selected: selected,
        child: OutlinedButton(
          key: ValueKey('wallet-quick-amount-$value'),
          onPressed: busy
              ? null
              : () {
                  widget.walletController.chargeAmountEc.text = '$value';
                  widget.walletController.chargeAmountFocusNode.unfocus();
                },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 46),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            backgroundColor: selected
                ? FasakhanstaBrand.orangeTint
                : FasakhanstaBrand.surfaceRaised,
            foregroundColor:
                selected ? FasakhanstaBrand.orange : FasakhanstaBrand.text,
            disabledForegroundColor: FasakhanstaBrand.muted,
            side: BorderSide(
              color:
                  selected ? FasakhanstaBrand.orange : FasakhanstaBrand.border,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Text('$value',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(currency, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      );
}
