import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../address/controller/address_controller.dart';
import '../../address/screen/add_address_screen.dart';

class NoDeliveryLocationWidget extends StatelessWidget {
  const NoDeliveryLocationWidget({super.key, required this.addressController});
  final AddressController addressController;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: context.height * 0.15),
        SvgPicture.asset(AppImages.noAddressIcon),
        20.sbH,
        Text('noAddresses'.tr, style: AppTextStyle.text16BM()),
        SizedBox(height: context.height * 0.12),
        InkWell(
          onTap: () {
            NamedNavigatorImpl.push(
              AddAddressScreen.routeName,
              arguments: AddAddressArgs(
                onSuccess: () {
                  addressController.getAddress();
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: FasakhanstaBrand.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.greyColor.withValues(alpha: 0.2),
                    offset: const Offset(0, -3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.add, color: AppColors.greyColor, size: 25),
                  const SizedBox(width: 15),
                  Text(
                    'addAddress'.tr,
                    style: AppTextStyle.text18RS().copyWith(
                      height: context.languageCode == 'ar' ? 1.5 : 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
