import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../my_account/controller/my_account_controller.dart';
import '../controller/request_delegate_controller.dart';

class PaymentRDBottomSheet extends StatelessWidget {
  const PaymentRDBottomSheet({
    super.key,
    required this.requestDelegateController,
  });

  final RequestDelegateController requestDelegateController;

  bool _isArabic(BuildContext context) => context.languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyAccountController()
        ..initialSetting()
        ..getSetting(),
      child: Consumer<MyAccountController>(
        builder: (context, accountController, _) {
          return AnimatedBuilder(
            animation: requestDelegateController,
            builder: (context, _) {
              final isAr = _isArabic(context);
              final options = <_PaymentOption>[
                _PaymentOption(
                  value: 'cash',
                  title: 'cash'.tr,
                  subtitle: isAr
                      ? 'الدفع نقدًا عند الاستلام'
                      : 'Pay cash on delivery',
                  icon: Icons.payments_outlined,
                ),
                _PaymentOption(
                  value: 'wallet',
                  title: 'appWalletBalance'.tr,
                  subtitle: isAr
                      ? 'الدفع من رصيد المحفظة داخل التطبيق'
                      : 'Pay from your app wallet balance',
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ];

              if (accountController.setting?.paymentCardActivate == 'true') {
                options.add(
                  _PaymentOption(
                    value: 'online',
                    title: 'creditCard'.tr,
                    subtitle: isAr ? 'الدفع ببطاقة بنكية' : 'Pay by bank card',
                    icon: Icons.credit_card_rounded,
                  ),
                );
              }

              if (accountController.setting?.walletCardActivate == 'true') {
                options.add(
                  _PaymentOption(
                    value: 'v_cash',
                    title: 'digitalWalletAndInstaPay'.tr,
                    subtitle: isAr
                        ? 'محفظة إلكترونية أو إنستا باي'
                        : 'Digital wallet or InstaPay',
                    icon: Icons.phone_android_rounded,
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
                decoration: const BoxDecoration(
                  color: FasakhanstaBrand.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Directionality(
                    textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                              color: FasakhanstaBrand.surfaceRaised,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          isAr ? 'اختر طريقة الدفع' : 'Choose payment method',
                          style: const TextStyle(
                            color: FasakhanstaBrand.text,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isAr
                              ? 'يمكنك تغيير طريقة الدفع في أي وقت قبل تأكيد الطلب'
                              : 'You can change it any time before confirming the order',
                          style: const TextStyle(
                            color: FasakhanstaBrand.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...options.map(
                          (option) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PaymentOptionTile(
                              option: option,
                              selected:
                                  requestDelegateController.selectedPayment ==
                                  option.value,
                              onTap: () => requestDelegateController
                                  .setSelectedPayment(option.value),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.mainAppColor,
                              foregroundColor: FasakhanstaBrand.onOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              isAr
                                  ? 'تأكيد طريقة الدفع'
                                  : 'Confirm payment method',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PaymentOption {
  const _PaymentOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _PaymentOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? FasakhanstaBrand.surfaceRaised
                : FasakhanstaBrand.surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected
                  ? AppColors.mainAppColor
                  : FasakhanstaBrand.border,
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? FasakhanstaBrand.surface
                        : FasakhanstaBrand.surfaceRaised,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    option.icon,
                    color: AppColors.mainAppColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: const TextStyle(
                          color: FasakhanstaBrand.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        option.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FasakhanstaBrand.muted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.mainAppColor
                        : FasakhanstaBrand.surface,
                    border: Border.all(
                      color: selected
                          ? AppColors.mainAppColor
                          : FasakhanstaBrand.border,
                      width: 1.3,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: FasakhanstaBrand.text,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
