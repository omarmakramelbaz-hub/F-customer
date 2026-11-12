import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../auth/screen/register_screen.dart';
import '../model/splashes_model.dart';

class FOnBoardingTab extends StatelessWidget {
  final SplashesModel splashModel;
  final PageController controller;
  final int index, length;

  const FOnBoardingTab({
    super.key,
    required this.controller,
    required this.splashModel,
    required this.index,
    required this.length,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomNetworkImage(
              width: double.infinity,
              fit: BoxFit.fill,
              radius: 10,
              imageUrl: splashModel.image ?? '',
            ),
          ),
        ),
        15.sbH,
        Stack(
          children: [
            Image.asset(
              AppImages.shapeOnBoardingImage,
              width: context.width,
              fit: BoxFit.fill,
            ),
            Positioned(
              right: 0,
              left: 0,
              child: Center(
                child: CustomButton(
                  width: 80,
                  height: 80,
                  radius: 40,
                  onPressed: () {
                    if (index < length - 1) {
                      controller.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.linear,
                      );
                    } else if (index == length - 1) {
                      NamedNavigatorImpl.push(
                        clean: true,
                        RegisterScreen.routeName,
                      );
                    }
                  },
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 40,
                    color: FasakhanstaBrand.onOrange,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 150,
              right: 20,
              left: 20,
              child: Column(
                children: [
                  15.sbH,
                  Text(
                    splashModel.title ?? '',
                    style: AppTextStyle.text20MW(),
                    textAlign: TextAlign.center,
                  ),
                  10.sbH,
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              left: 20,
              child: Center(
                child: SmoothPageIndicator(
                  controller: controller,
                  count: length,
                  axisDirection: Axis.horizontal,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AppColors.whiteColor,
                    dotColor: AppColors.whiteColor,
                    dotHeight: 10,
                    dotWidth: 10,
                    radius: 5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
