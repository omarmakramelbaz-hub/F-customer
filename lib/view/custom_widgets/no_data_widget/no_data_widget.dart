import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../helpers/extensions/extensions.dart';
import '../../../helpers/images/app_images.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/translation/all_translation.dart';

class NoDataWidget extends StatelessWidget {
  final Axis axis;
  final String? message;
  const NoDataWidget({super.key, this.axis = Axis.vertical, this.message});

  @override
  Widget build(BuildContext context) {
    switch (axis) {
      case Axis.horizontal:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.mainAppColor.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(7),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                SvgPicture.asset(
                  AppImages.noData,
                  // colorFilter: ColorFilter.mode(
                  //   AppTheme.getByTheme(
                  //     context,
                  //     light: Colors.black,
                  //     dark: Colors.white,
                  //   ),
                  //   BlendMode.srcIn,
                  // ),
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      message ?? 'There is no data'.tr,
                      style: const TextStyle(
                        color: FasakhanstaBrand.onOrange,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case Axis.vertical:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.mainAppColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppImages.emptyFolderIcon,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
              10.sbH,
              Text(
                message ?? 'There is no data'.tr,
                style: const TextStyle(
                  color: FasakhanstaBrand.onOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }
}
