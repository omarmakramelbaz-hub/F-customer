import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../controller/address_controller.dart';

class ChangeAddressWidget extends StatelessWidget {
  const ChangeAddressWidget({
    super.key,
    required this.addressController,
    this.placemarks,
  });
  final AddressController addressController;
  final List<Placemark>? placemarks;
  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(AppImages.addressIcon, width: 16),
              const SizedBox(width: 10),
              Text('area'.tr, style: AppTextStyle.text14MS()),
              const Spacer(),
              // GestureDetector(
              //   child: Text(
              //     tr(
              //       'change',
              //     ),
              //     style: TextStyle(
              //       fontSize: 16,
              //       color: AppColor.mainAppColor,
              //       decoration: TextDecoration.underline,
              //     ),
              //   ),
              // )
            ],
          ),
          if (placemarks != null)
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 22),
              child: Text(
                "${placemarks![0].country ?? ""}\t-\t${placemarks![0].locality ?? ""} \t-\t${placemarks![0].street ?? ""}",
                style: AppTextStyle.text14RS(),
              ),
            ),
          if (placemarks == null)
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 22),
              child: Text(
                "${addressController.addressDetails?.countryName ?? ""}\t-\t${addressController.addressDetails?.cityName ?? ""} \t-\t${addressController.addressDetails?.addressName ?? ""}",
                style: AppTextStyle.text14RS(),
              ),
            ),
        ],
      ),
    );
  }
}
