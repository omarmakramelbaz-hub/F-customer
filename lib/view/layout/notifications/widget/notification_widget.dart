import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../orders/screen/tracking_your_order_screen.dart';
import '../../request_delegate/screen/request_delegate_screen.dart';
import '../../wallet/screen/wallet_screen.dart';
import '../model/notifications_model.dart';

class NotificationWidget extends StatelessWidget {
  final NotificationsModel notification;
  final int? orderId;

  const NotificationWidget({
    super.key,
    required this.notification,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final type = notification.data?.data?.notificationType;
    final visual = _visualFor(type);
    final logo = (notification.data?.logo ?? '').trim();
    final showRestaurantLogo = type == 1 && logo.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _handleTap(type),
        child: Container(
          decoration: BoxDecoration(
            color: FasakhanstaBrand.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: FasakhanstaBrand.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 14,
                bottom: 14,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: visual.accent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 14, 14),
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NotificationAvatar(
                      visual: visual,
                      logo: logo,
                      showRestaurantLogo: showRestaurantLogo,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            textDirection: TextDirection.rtl,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  notification.data?.title ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: AppTextStyle.text16BS().copyWith(
                                    color: FasakhanstaBrand.text,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: visual.accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: visual.accent.withValues(
                                        alpha: .22,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            notification.data?.text ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: AppTextStyle.text13RM().copyWith(
                              color: FasakhanstaBrand.muted,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 13),
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: visual.softBackground,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      visual.icon,
                                      size: 15,
                                      color: visual.accent,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      visual.label,
                                      style: AppTextStyle.text12RM().copyWith(
                                        color: visual.accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.access_time_rounded,
                                size: 15,
                                color: FasakhanstaBrand.muted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                DateMethods.timeAgo(
                                  notification.createdAt ?? '',
                                  context,
                                ),
                                style: AppTextStyle.text12RM().copyWith(
                                  color: FasakhanstaBrand.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(int? type) {
    if (type == 3) {
      NamedNavigatorImpl.push(WalletScreen.routeName);
      return;
    }

    if (type != 1) return;

    if (notification.data?.data?.orderType == 'shipping') {
      NamedNavigatorImpl.push(RequestDelegateScreen.routeName);
      return;
    }

    if ((orderId ?? 0) > 0) {
      NamedNavigatorImpl.push(
        TrackingYourOrderScreen.routeName,
        arguments: TrackingYourOrderArgs(id: orderId!),
      );
    }
  }

  _NotificationVisual _visualFor(int? type) {
    if (type == 1) {
      return _NotificationVisual(
        label: 'طلب',
        icon: Icons.shopping_bag_outlined,
        accent: AppColors.mainAppColor,
        softBackground: const Color(0xFFFFF1E6),
      );
    }

    if (type == 2) {
      return const _NotificationVisual(
        label: 'عرض',
        icon: Icons.local_offer_outlined,
        accent: Color(0xFFF29D14),
        softBackground: Color(0xFFFFF6E8),
      );
    }

    if (type == 3) {
      return const _NotificationVisual(
        label: 'محفظة',
        icon: Icons.account_balance_wallet_outlined,
        accent: Color(0xFF0B8C84),
        softBackground: Color(0xFFEAF8F6),
      );
    }

    return const _NotificationVisual(
      label: 'تنبيه',
      icon: Icons.notifications_none_rounded,
      accent: Color(0xFF7456D8),
      softBackground: Color(0xFFF2EEFF),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({
    required this.visual,
    required this.logo,
    required this.showRestaurantLogo,
  });

  final _NotificationVisual visual;
  final String logo;
  final bool showRestaurantLogo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: FasakhanstaBrand.surface,
        border: Border.all(color: visual.accent.withValues(alpha: .34)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: showRestaurantLogo
            ? CustomNetworkImage(
                imageUrl: logo,
                width: 64,
                height: 64,
                radius: 0,
                fit: BoxFit.cover,
              )
            : Container(
                color: visual.softBackground,
                alignment: Alignment.center,
                child: Icon(visual.icon, color: visual.accent, size: 30),
              ),
      ),
    );
  }
}

class _NotificationVisual {
  const _NotificationVisual({
    required this.label,
    required this.icon,
    required this.accent,
    required this.softBackground,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Color softBackground;
}
