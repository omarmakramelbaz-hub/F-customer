import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/buttons/custom_button.dart';

class CancelOrderBottomSheet extends StatelessWidget {
  final int orderId;
  final VoidCallback onPressed;
  const CancelOrderBottomSheet({
    super.key,
    required this.orderId,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          20.sbH,
          Row(
            children: [
              Text(
                'doYouReallyWantToCancelTheOrder'.tr,
                style: AppTextStyle.text16RS(),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: FasakhanstaBrand.surface,
                    child: SvgPicture.asset(AppImages.cancelIcon),
                  ),
                ),
              ),
            ],
          ),
          10.sbH,
          const Divider(thickness: 1),
          const SizedBox(height: 33),
          Builder(
            builder: (context) {
              return CustomButton(
                onPressed: onPressed,
                radius: 23,
                text: 'yesIWantToCancelIt'.tr,
                style: AppTextStyle.text16BW(color: FasakhanstaBrand.onOrange),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('no'.tr, style: AppTextStyle.text16BS()),
          ),
        ],
      ),
    );
  }
}
