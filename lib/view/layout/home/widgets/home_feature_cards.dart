import 'package:flutter/material.dart';

import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../controller/home_controller.dart';
import '../screen/draw_resturant_screen.dart';
import 'celebrate_widget.dart';
import '../../../../helpers/networking/api_helper.dart';

class HomeFeatureCards extends StatelessWidget {
  final HomeController controller;
  final EdgeInsetsGeometry padding;

  const HomeFeatureCards({
    super.key,
    required this.controller,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final coupon = controller.coupon;
    final isWinner = coupon?.flag?.trim().toLowerCase() == 'winner';

    if (isWinner) {
      return Padding(
        padding: padding,
        child: CelebrateWidget(homeController: controller),
      );
    }

    final dashboardImage = coupon?.data?.image?.trim() ?? '';
    final loading =
        dashboardImage.isEmpty &&
        (controller.couponResponse.state == ResponseState.loading ||
            controller.couponResponse.state == ResponseState.sleep);

    if (loading) {
      return Padding(
        padding: padding,
        child: const AspectRatio(
          aspectRatio: 1320 / 502,
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFA258),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: InkWell(
        onTap: () => NamedNavigatorImpl.push(DrawRestaurantScreen.routeName),
        borderRadius: BorderRadius.circular(22),
        child: dashboardImage.isNotEmpty
            ? _DashboardContestImage(imageUrl: dashboardImage)
            : const _ContestFallbackCard(),
      ),
    );
  }
}

class _DashboardContestImage extends StatelessWidget {
  final String imageUrl;

  const _DashboardContestImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1320 / 502,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xB0092225),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.mainAppColor.withValues(alpha: .20),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          radius: 0,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _ContestFallbackCard extends StatelessWidget {
  const _ContestFallbackCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xD908282E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x55FFAF69)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: Color(0xFFFFB874),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مسابقة فسخانستا',
                  style: AppTextStyle.text16BS(color: Colors.white),
                ),
                const SizedBox(height: 5),
                Text(
                  'تفاصيل المسابقة وطريقة الاشتراك',
                  style: AppTextStyle.text12BS(color: const Color(0xFFDDE4D6)),
                ),
                const SizedBox(height: 8),
                Text(
                  'شوف المسابقة',
                  style: AppTextStyle.text12BS(color: const Color(0xFFFFB874)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
