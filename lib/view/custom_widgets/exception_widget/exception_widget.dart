import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../helpers/extensions/extensions.dart';
import '../../../helpers/images/app_images.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/theme/app_text_style.dart';
import '../../../helpers/translation/all_translation.dart';

class ExceptionWidget extends StatelessWidget {
  final Axis axis;
  final String? message;
  final void Function()? onReload;

  const ExceptionWidget({
    super.key,
    this.axis = Axis.vertical,
    this.message,
    this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return axis == Axis.horizontal
        ? _horizontalError(context)
        : _verticalError(context);
  }

  Widget _verticalError(BuildContext context) {
    final isArabic = context.languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 430),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: FasakhanstaBrand.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: FasakhanstaBrand.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(23),
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surfaceRaised,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.mainAppColor.withValues(alpha: .16),
                  ),
                ),
                child: SvgPicture.asset(
                  AppImages.errorIcon,
                  colorFilter: ColorFilter.mode(
                    AppColors.mainAppColor,
                    BlendMode.srcIn,
                  ),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message ?? 'An error occurred'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyle.text18BS().copyWith(
                  color: FasakhanstaBrand.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'تعذر تحميل المحتوى في الوقت الحالي. حاول مرة أخرى بعد لحظات.'
                    : 'We couldn’t load this content right now. Please try again in a moment.',
                textAlign: TextAlign.center,
                style: AppTextStyle.text13RM().copyWith(
                  color: FasakhanstaBrand.muted,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onReload,
                  icon: const Icon(Icons.refresh_rounded, size: 21),
                  label: Text(
                    'Reload'.tr,
                    style: AppTextStyle.text15BS().copyWith(
                      color: FasakhanstaBrand.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainAppColor,
                    foregroundColor: FasakhanstaBrand.onOrange,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _horizontalError(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FasakhanstaBrand.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: FasakhanstaBrand.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              AppImages.errorIcon,
              colorFilter: ColorFilter.mode(
                AppColors.mainAppColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message ?? 'An error occurred'.tr,
              style: AppTextStyle.text13MS().copyWith(
                color: FasakhanstaBrand.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onReload,
            tooltip: 'Reload'.tr,
            icon: Icon(Icons.refresh_rounded, color: AppColors.mainAppColor),
          ),
        ],
      ),
    );
  }
}
