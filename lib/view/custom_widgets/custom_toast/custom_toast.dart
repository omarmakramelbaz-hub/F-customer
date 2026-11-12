import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../helpers/theme/app_colors.dart';

enum ToastType { success, error, offline, warning, help }

class CustomToast extends StatelessWidget {
  final ToastType type;
  final String? title;
  final String? icon;
  final String message;

  /// Kept for backwards compatibility. In the branded toast this value is
  /// used as a small accent color only; the card background always keeps the
  /// Fasakhansta cream/white identity.
  final Color? backgroundColor;

  /// Kept for backwards compatibility with older calls. Branded toasts use
  /// the unified dark/gray typography so old white text overrides cannot make
  /// the new light card unreadable.
  final Color? textColor;

  final VoidCallback? onClose;
  final VoidCallback? onTap;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const CustomToast({
    super.key,
    required this.type,
    this.title,
    required this.message,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.onClose,
    this.onTap,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final accentColor = backgroundColor ?? _accentColor();
    final displayTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : _defaultTitle(isArabic);
    final hasAction =
        actionLabel?.trim().isNotEmpty == true && onAction != null;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            decoration: BoxDecoration(
              color: FasakhanstaBrand.surfaceRaised,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FasakhanstaBrand.border, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ToastIcon(
                  type: type,
                  customIcon: icon,
                  accentColor: accentColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FasakhanstaBrand.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      if (message.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          message.trim(),
                          maxLines: hasAction ? 2 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FasakhanstaBrand.muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (hasAction) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: onAction,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: FasakhanstaBrand.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: FasakhanstaBrand.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (actionIcon != null) ...[
                                  Icon(
                                    actionIcon,
                                    size: 16,
                                    color: AppColors.mainAppColor,
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                Text(
                                  actionLabel!,
                                  style: TextStyle(
                                    color: AppColors.mainAppColor,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onClose != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(18),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: FasakhanstaBrand.muted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _accentColor() {
    switch (type) {
      case ToastType.success:
        return AppColors.mainAppColor;
      case ToastType.error:
        return const Color(0xFFD84A4A);
      case ToastType.offline:
        return const Color(0xFF6F7680);
      case ToastType.warning:
        return const Color(0xFFE29A22);
      case ToastType.help:
        return const Color(0xFF4A7FD8);
    }
  }

  String _defaultTitle(bool isArabic) {
    switch (type) {
      case ToastType.success:
        return isArabic ? 'تم بنجاح' : 'Success';
      case ToastType.error:
        return isArabic ? 'تعذر إتمام العملية' : 'Something went wrong';
      case ToastType.offline:
        return isArabic ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection';
      case ToastType.warning:
        return isArabic ? 'تنبيه' : 'Notice';
      case ToastType.help:
        return isArabic ? 'معلومة' : 'Information';
    }
  }
}

class _ToastIcon extends StatelessWidget {
  final ToastType type;
  final String? customIcon;
  final Color accentColor;

  const _ToastIcon({
    required this.type,
    required this.customIcon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: FasakhanstaBrand.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: customIcon != null
            ? SvgPicture.asset(
                customIcon!,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
              )
            : _buildDefaultIcon(),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    switch (type) {
      case ToastType.success:
        return SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.mainAppColor, width: 2.3),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.mainAppColor,
                  size: 21,
                ),
              ),
              Positioned(
                top: -1,
                right: 1,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: FasakhanstaBrand.successTint,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      case ToastType.error:
        return Icon(Icons.error_outline_rounded, color: accentColor, size: 28);
      case ToastType.offline:
        return Icon(Icons.wifi_off_rounded, color: accentColor, size: 26);
      case ToastType.warning:
        return Icon(Icons.warning_amber_rounded, color: accentColor, size: 28);
      case ToastType.help:
        return Icon(Icons.info_outline_rounded, color: accentColor, size: 27);
    }
  }
}
