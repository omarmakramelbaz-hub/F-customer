import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../auth/controller/auth_controller.dart';

class ChooseAvatarBottomSheet extends StatelessWidget {
  final VoidCallback? onSuccess;
  const ChooseAvatarBottomSheet({super.key, this.onSuccess});

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
              Text('chooseYourAvatar'.tr, style: AppTextStyle.text16RS()),
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
          20.sbH,
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    context.read<AuthController>().chooseAvatar(
                      gender: 'male',
                      onSuccess: () {
                        context.read<AuthController>().getProfile();
                        Navigator.pop(context);
                      },
                    );
                  },
                  child: SvgPicture.asset(AppImages.avatarMale),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    context.read<AuthController>().chooseAvatar(
                      gender: 'female',
                      onSuccess: () {
                        context.read<AuthController>().getProfile();
                        Navigator.pop(context);
                      },
                    );
                  },
                  child: SvgPicture.asset(AppImages.avatarFemale),
                ),
              ),
            ],
          ),
          20.sbH,
        ],
      ),
    );
  }
}
