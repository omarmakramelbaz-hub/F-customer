import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/theme/fasakhansta_brand.dart';
import '../../my_account/controller/my_account_controller.dart';
import '../controller/wallet_controller.dart';

class ChooseVCashOrVisaWidget extends StatefulWidget {
  const ChooseVCashOrVisaWidget({super.key, required this.myAccountController});

  final MyAccountController myAccountController;

  @override
  State<ChooseVCashOrVisaWidget> createState() =>
      _ChooseVCashOrVisaWidgetState();
}

class _ChooseVCashOrVisaWidgetState extends State<ChooseVCashOrVisaWidget> {
  String? _selectedOptionKey;

  @override
  Widget build(BuildContext context) {
    final walletController = context.watch<WalletController>();
    // Keep listening so payment methods appear when settings finish loading.
    final liveAccountController = context.watch<MyAccountController>();
    final accountController = liveAccountController.setting != null
        ? liveAccountController
        : widget.myAccountController;
    final setting = accountController.setting;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final walletEnabled = setting?.walletCardActivate == 'true';
    final cardEnabled = setting?.paymentCardActivate == 'true';

    final methods = <_PaymentOptionData>[
      if (cardEnabled)
        _PaymentOptionData(
          keyName: 'bank_card',
          label: isArabic ? 'بطاقة بنكية' : 'Bank card',
          subtitle: 'Visa · Mastercard',
          backendMethod: 'online',
          brand: const Icon(
            Icons.credit_card_rounded,
            size: 28,
            color: FasakhanstaBrand.orange,
          ),
        ),
      if (walletEnabled)
        _PaymentOptionData(
          keyName: 'vodafone_cash',
          label: isArabic ? 'فودافون كاش' : 'Vodafone Cash',
          subtitle: isArabic ? 'Vodafone Cash' : 'Mobile wallet',
          backendMethod: 'v_cash',
          brand: Image.asset(
            AppImages.vfCash,
            height: 30,
            width: 34,
            fit: BoxFit.contain,
          ),
        ),
      if (walletEnabled)
        _PaymentOptionData(
          keyName: 'orange_cash',
          label: isArabic ? 'أورنج كاش' : 'Orange Cash',
          subtitle: isArabic ? 'Orange Cash' : 'Mobile wallet',
          backendMethod: 'v_cash',
          brand: const _BrandMark(
            text: 'orange',
            fontSize: 11,
            color: Colors.white,
            background: Color(0xFFFF7900),
          ),
        ),
      if (walletEnabled)
        _PaymentOptionData(
          keyName: 'etisalat_cash',
          label: isArabic ? 'اتصالات كاش' : 'Etisalat Cash',
          subtitle: isArabic ? 'e& Cash' : 'Mobile wallet',
          backendMethod: 'v_cash',
          brand: const _BrandMark(
            text: 'e&',
            fontSize: 25,
            color: Color(0xFFFF4E57),
          ),
        ),
    ];

    if (methods.isEmpty) {
      final settingsState = liveAccountController.settingResponse.state;
      final isLoading = setting == null &&
          (settingsState == ResponseState.loading ||
              settingsState == ResponseState.sleep);
      final message = isLoading
          ? (isArabic
              ? 'جاري تحميل وسائل الدفع...'
              : 'Loading payment methods...')
          : (isArabic
              ? 'تعذر تحميل وسائل الدفع، اضغط لإعادة المحاولة'
              : 'Could not load payment methods. Tap to retry');
      final content = Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: FasakhanstaBrand.surfaceRaised,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: FasakhanstaBrand.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: FasakhanstaBrand.orange,
                ),
              )
            else
              const Icon(
                Icons.refresh_rounded,
                size: 20,
                color: FasakhanstaBrand.orange,
              ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyle.text12RG(color: FasakhanstaBrand.muted),
              ),
            ),
          ],
        ),
      );
      if (isLoading) return content;
      return Semantics(
        button: true,
        label: message,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => liveAccountController.getSetting(),
          child: content,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: methods
              .map(
                (method) => SizedBox(
                  width: itemWidth,
                  child: _buildMethod(
                    method: method,
                    walletController: walletController,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildMethod({
    required _PaymentOptionData method,
    required WalletController walletController,
  }) {
    // The API groups all mobile wallets under v_cash. Retain the user's
    // local brand selection without changing the backend payment contract.
    final selectedKey = walletController.selectedPayment == 'online'
        ? 'bank_card'
        : walletController.selectedPayment == 'v_cash'
            ? (_selectedOptionKey == 'orange_cash' ||
                    _selectedOptionKey == 'etisalat_cash'
                ? _selectedOptionKey
                : 'vodafone_cash')
            : null;

    return PaymentMethodWidget(
      key: ValueKey('wallet-payment-${method.keyName}'),
      label: method.label,
      subtitle: method.subtitle,
      brand: method.brand,
      isSelected: selectedKey == method.keyName,
      onTap: () {
        if (walletController.isCreatingCheckout) return;
        setState(() => _selectedOptionKey = method.keyName);
        walletController.setSelectedPayment(method.backendMethod);
      },
    );
  }
}

class _PaymentOptionData {
  final String keyName;
  final String label;
  final String subtitle;
  final String backendMethod;
  final Widget brand;

  const _PaymentOptionData({
    required this.keyName,
    required this.label,
    required this.subtitle,
    required this.backendMethod,
    required this.brand,
  });
}

class PaymentMethodWidget extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget brand;
  final bool isSelected;
  final bool compactHorizontal;
  final VoidCallback onTap;

  const PaymentMethodWidget({
    super.key,
    required this.label,
    this.subtitle,
    required this.brand,
    required this.isSelected,
    required this.onTap,
    this.compactHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyle.text14BS(color: FasakhanstaBrand.text)
        .copyWith(height: 1.3);
    return Semantics(
      button: true,
      selected: isSelected,
      label: subtitle == null ? label : '$label, $subtitle',
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          constraints: BoxConstraints(minHeight: compactHorizontal ? 60 : 110),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isSelected
                ? FasakhanstaBrand.orangeTint
                : FasakhanstaBrand.surfaceRaised,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected
                  ? FasakhanstaBrand.orange
                  : FasakhanstaBrand.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: compactHorizontal
              ? Row(
                  children: [
                    SizedBox(width: 34, child: Center(child: brand)),
                    const SizedBox(width: 9),
                    Expanded(child: Text(label, style: labelStyle)),
                    const SizedBox(width: 7),
                    _selectionDot(),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 42,
                          height: 30,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: brand,
                          ),
                        ),
                        _selectionDot(),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(label, style: labelStyle),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          subtitle!,
                          textDirection: TextDirection.ltr,
                          style: AppTextStyle.text11RG(
                            color: FasakhanstaBrand.muted,
                          ).copyWith(height: 1.3),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _selectionDot() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? FasakhanstaBrand.orange
            : FasakhanstaBrand.surfaceRaised,
        border: Border.all(
          color: isSelected ? FasakhanstaBrand.orange : FasakhanstaBrand.border,
          width: 1.2,
        ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check_rounded,
              size: 13,
              color: FasakhanstaBrand.onOrange,
            )
          : null,
    );
  }
}

class _BrandMark extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final Color? background;

  const _BrandMark({
    required this.text,
    required this.fontSize,
    required this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: background == null ? EdgeInsets.zero : const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontSize: fontSize,
          height: 1,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
