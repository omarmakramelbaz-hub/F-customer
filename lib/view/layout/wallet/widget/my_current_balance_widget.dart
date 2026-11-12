import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../custom_widgets/custom_loading/custom_shimmer.dart';
import '../model/wallet_model.dart';

class MyCurrentBalanceWidget extends StatefulWidget {
  final WalletResponse? wallet;
  final String? pusherWalletAmount;
  const MyCurrentBalanceWidget({
    super.key,
    required this.wallet,
    this.pusherWalletAmount,
  });

  @override
  State<MyCurrentBalanceWidget> createState() => _MyCurrentBalanceWidgetState();
}

class _MyCurrentBalanceWidgetState extends State<MyCurrentBalanceWidget> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    final balance =
        widget.pusherWalletAmount ?? widget.wallet?.balance?.toStringAsFixed(2);
    final name = widget.wallet?.profile?.name ?? 'فسخانستا';

    return Container(
      width: double.infinity,
      height: 205,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.mainAppColor,
            AppColors.mainAppColor.withValues(alpha: .82),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainAppColor.withValues(alpha: .25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -35,
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 170,
              color: FasakhanstaBrand.onOrange.withValues(alpha: .08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: AppTextStyle.text18MS().copyWith(
                        color: FasakhanstaBrand.onOrange,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _visible = !_visible),
                    icon: Icon(
                      _visible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: FasakhanstaBrand.onOrange,
                    ),
                  ),
                ],
              ),
              Text(
                'رصيد المحفظة',
                style: AppTextStyle.text16MS().copyWith(
                  color: FasakhanstaBrand.onOrange.withValues(alpha: .9),
                ),
              ),
              const SizedBox(height: 8),
              if (balance == null)
                CustomShimmer(
                  height: 42,
                  width: 150,
                  radius: 8,
                  fillColor: FasakhanstaBrand.field.withValues(alpha: .2),
                  shimmerColor: Colors.white,
                )
              else
                Text(
                  _visible ? balance : '••••••',
                  style: AppTextStyle.text20MW(color: FasakhanstaBrand.onOrange)
                      .copyWith(color: FasakhanstaBrand.onOrange, fontSize: 38),
                ),
              Text(
                'جنيه مصري',
                style: AppTextStyle.text16MS().copyWith(
                  color: FasakhanstaBrand.onOrange.withValues(alpha: .9),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.remove_red_eye_outlined,
                    size: 18,
                    color: FasakhanstaBrand.onOrange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _visible ? 'إخفاء الرصيد' : 'إظهار الرصيد',
                    style: AppTextStyle.text16MS().copyWith(
                      color: FasakhanstaBrand.onOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
