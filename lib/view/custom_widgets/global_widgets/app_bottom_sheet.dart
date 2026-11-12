import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../helpers/extensions/extensions.dart';
import '../../../helpers/images/app_images.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/theme/app_text_style.dart';

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.title,
    required this.children,
    this.isDark = false,
  });
  final String title;
  final List<Widget> children;
  final bool? isDark;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: isDark == true
            ? FasakhanstaBrand.surfaceRaised
            : FasakhanstaBrand.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              15.sbH,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: AppTextStyle.text16MS().copyWith(
                        color: isDark == true
                            ? FasakhanstaBrand.text
                            : FasakhanstaBrand.text,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark == true
                            ? FasakhanstaBrand.surfaceRaised
                            : FasakhanstaBrand.surface,
                        child: SvgPicture.asset(AppImages.closeIcon),
                      ),
                    ),
                  ),
                ],
              ),
              15.sbH,
              Divider(thickness: 0.7, color: AppColors.greyColor),
              15.sbH,
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
