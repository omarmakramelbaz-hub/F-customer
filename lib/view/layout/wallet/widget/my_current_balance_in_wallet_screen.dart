import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../model/wallet_model.dart';

class MyCurrentBalanceInWalletScreenWidget extends StatelessWidget {
  final WalletResponse? wallet;
  const MyCurrentBalanceInWalletScreenWidget({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: FasakhanstaBrand.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.greyColor.withValues(alpha: 0.2),
              offset: const Offset(2, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  15.sbH,
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          child: Text(
                            'myCurrentBalance'.tr,
                            style: AppTextStyle.text16MS(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      SvgPicture.asset(AppImages.downIcon),
                    ],
                  ),
                  15.sbH,
                  Text(
                    wallet?.balance.toString() ?? '',
                    style: AppTextStyle.text16BS(),
                  ),
                ],
              ),
            ),
            SvgPicture.asset(AppImages.payWalletIcon),
          ],
        ),
      ),
    );
  }
}
