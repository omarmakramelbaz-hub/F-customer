import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/url_launcher_methods.dart';
import '../../auth/controller/auth_controller.dart';
import '../../chat/screen/admin_chat_screen.dart';
import '../controller/my_account_controller.dart';

class MobileAndEmailContactUsWidget extends StatelessWidget {
  final String mobile;
  final String email;
  final String adminId;
  final MyAccountController myAccountController;

  const MobileAndEmailContactUsWidget({
    super.key,
    required this.mobile,
    required this.email,
    required this.adminId,
    required this.myAccountController,
  });

  @override
  Widget build(BuildContext context) {
    final hasMobile = mobile.trim().isNotEmpty;
    final hasEmail = email.trim().isNotEmpty;

    return Column(
      children: [
        _ContactActionCard(
          icon: Icons.phone_in_talk_rounded,
          title: 'mobileNumber'.tr,
          value: hasMobile
              ? mobile
              : context.languageCode == 'ar'
                  ? 'غير متاح حاليًا'
                  : 'Not available right now',
          onTap:
              hasMobile ? () => UrlLauncherMethods.makePhoneCall(mobile) : null,
        ),
        const SizedBox(height: 10),
        _ContactActionCard(
          icon: Icons.alternate_email_rounded,
          title: 'email'.tr,
          value: hasEmail
              ? email
              : context.languageCode == 'ar'
                  ? 'غير متاح حاليًا'
                  : 'Not available right now',
          onTap:
              hasEmail ? () => UrlLauncherMethods.makeMailMessage(email) : null,
        ),
        if (HiveMethods.getToken() != null) ...[
          const SizedBox(height: 10),
          _ContactActionCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'contactSupport'.tr,
            value: context.languageCode == 'ar'
                ? 'دردشة مباشرة مع فريق الدعم'
                : 'Chat directly with our support team',
            onTap: () {
              final profile = context.read<AuthController>().profile;
              final setting = myAccountController.setting;
              if (profile?.id == null ||
                  setting?.adminId == null ||
                  setting?.adminDeviceToken == null) {
                return;
              }

              NamedNavigatorImpl.push(
                AdminChatScreen.routeName,
                arguments: AdminChatScreenArgs(
                  receiverId: adminId,
                  senderId: profile!.id!.toString(),
                  adminId: setting!.adminId!,
                  adminDeviceToken: setting.adminDeviceToken!,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _ContactActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _ContactActionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FasakhanstaBrand.surface,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: FasakhanstaBrand.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: FasakhanstaBrand.surfaceRaised,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.mainAppColor, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.text11RG().copyWith(
                        color: FasakhanstaBrand.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.text14BS().copyWith(
                        color: FasakhanstaBrand.text,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: onTap == null
                      ? FasakhanstaBrand.surfaceRaised
                      : AppColors.mainAppColor.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  context.languageCode == 'ar'
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
                  color: onTap == null
                      ? FasakhanstaBrand.muted
                      : AppColors.mainAppColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
