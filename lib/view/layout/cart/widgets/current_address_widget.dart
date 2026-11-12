import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../address/controller/address_controller.dart';
import '../screen/add_address_from_cart_screen.dart';

class CurrentAddressWidget extends StatelessWidget {
  const CurrentAddressWidget({super.key, required this.addressController});

  final AddressController addressController;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(AppImages.addressIcon, width: 16),
                  const SizedBox(width: 10),
                  Text('area'.tr, style: AppTextStyle.text14MG()),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 22, right: 22),
                child: Text(
                  '${addressController.address.last.areaName}-${addressController.address.last.streetName}',
                  style: AppTextStyle.text14RG(),
                ),
              ),
            ],
          ),
          const Expanded(child: SizedBox()),
          TextButton(
            onPressed: () {
              NamedNavigatorImpl.push(AddAddressFromCartScreen.routeName);
            },
            child: Text(
              'change'.tr,
              style: AppTextStyle.text14MM().copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
