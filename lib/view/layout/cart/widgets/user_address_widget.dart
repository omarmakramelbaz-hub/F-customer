import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../address/model/address_model.dart';

class UserAddressWidget extends StatelessWidget {
  const UserAddressWidget({super.key, required this.address});
  final AddressModel address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: FasakhanstaBrand.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.greyColor.withValues(alpha: 0.3),
            offset: const Offset(0, 0),
            blurRadius: 10,
          ),
        ],
        border: Border.all(color: AppColors.mainAppColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(AppImages.addressIcon, width: 16),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('area'.tr, style: AppTextStyle.text14MG()),
                  5.sbH,
                  Text(
                    "${address.addressName ?? ''} ${address.areaName ?? ''} ${address.streetName ?? ''} ",
                    style: AppTextStyle.text14RG(),
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
