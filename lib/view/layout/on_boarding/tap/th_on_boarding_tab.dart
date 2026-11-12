import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../custom_widgets/buttons/custom_button.dart';

class ThOnBoardingTab extends StatelessWidget {
  final PageController controller;
  const ThOnBoardingTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          AppImages.thOnBoardingImage,
          height: 300,
          fit: BoxFit.contain,
        ),
        Expanded(
          child: Stack(
            children: [
              Image.asset(
                AppImages.shapeOnBoardingImage,
                width: context.width,
                height: double.infinity,
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
                    onPressed: () {},
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 40,
                      color: FasakhanstaBrand.onOrange,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 130,
                bottom: 20,
                right: 20,
                left: 20,
                child: Column(
                  children: [
                    Expanded(
                      child: Text(
                        'اكتشف أشهى أنواع الفسيخ والرنجة من أفضل المتاجر في مكان واحد',
                        style: AppTextStyle.text20MW(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    10.sbH,
                    SmoothPageIndicator(
                      controller: controller,
                      count: 3,
                      axisDirection: Axis.horizontal,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppColors.whiteColor,
                        dotColor: AppColors.whiteColor,
                        dotHeight: 10,
                        dotWidth: 10,
                        radius: 5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
