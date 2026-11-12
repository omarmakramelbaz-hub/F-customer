import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../controller/home_controller.dart';

class CelebrateWidget extends StatelessWidget {
  const CelebrateWidget({super.key, required this.homeController});
  final HomeController homeController;

  @override
  Widget build(BuildContext context) {
    final winnerName = (homeController.coupon?.winnerData?.name ?? '').trim();
    final winnerCode = (homeController.coupon?.winner ?? '').trim();
    final prizeValue = (homeController.coupon?.data?.drawAmount ?? '').trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.infoTint,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: .28,
              child: const CustomImage(
                path: AppImages.celebrateBG,
                type: ImageType.svg,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.mainAppColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FasakhanstaBrand.border.withValues(alpha: .25),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: FasakhanstaBrand.onOrange,
                  size: 31,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'مبروك للفائز!',
                textAlign: TextAlign.center,
                style: AppTextStyle.text20BS(color: FasakhanstaBrand.text),
              ),
              const SizedBox(height: 5),
              Text(
                winnerName.isEmpty ? 'الفائز بالمسابقة' : winnerName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.text18BW(),
              ),
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surface.withValues(alpha: .96),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _WinnerInfo(
                        icon: Icons.card_giftcard_rounded,
                        label: 'قيمة الجائزة',
                        value: prizeValue.isEmpty
                            ? '—'
                            : '${_formatAmount(prizeValue)} ج',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 42,
                      color: FasakhanstaBrand.surfaceRaised,
                    ),
                    Expanded(
                      child: _WinnerInfo(
                        icon: Icons.confirmation_number_rounded,
                        label: 'رقم الاشتراك الفائز',
                        value: winnerCode.isEmpty ? '—' : winnerCode,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WinnerInfo extends StatelessWidget {
  const _WinnerInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.mainAppColor, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.text10RG(color: FasakhanstaBrand.muted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.text13BS(color: FasakhanstaBrand.text),
        ),
      ],
    );
  }
}

String _formatAmount(String value) {
  final number = num.tryParse(value);
  if (number == null) return value;
  return number.toStringAsFixed(number % 1 == 0 ? 0 : 2);
}
