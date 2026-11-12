import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../../helpers/utils/url_launcher_methods.dart';
import '../../../custom_widgets/custom_image/custom_network_image.dart';
import '../../chat/screen/chat_screen.dart';
import '../model/orders_model.dart';

class DeliveryAgentWidget extends StatelessWidget {
  final OrdersModel? orders;
  const DeliveryAgentWidget({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FasakhanstaBrand.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.mainAppColor.withValues(alpha: .12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.greyColor.withValues(alpha: .14),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mainAppColor.withValues(alpha: .10),
              ),
              padding: const EdgeInsets.all(3),
              child: CustomNetworkImage(
                imageUrl: orders?.delegateLogo ?? '',
                radius: 40,
                fit: BoxFit.cover,
                height: 70,
                width: 70,
              ),
            ),
            12.sbW,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'deliveryAgent'.tr,
                    style: AppTextStyle.text14RS().copyWith(
                      color: AppColors.mainAppColor,
                    ),
                  ),
                  4.sbH,
                  Text(
                    orders?.delegateName ?? '',
                    style: AppTextStyle.text18BS(),
                  ),
                  5.sbH,
                  if ((orders?.delegateMobile ?? '').isNotEmpty)
                    Text(
                      orders!.delegateMobile!,
                      style: AppTextStyle.text13RG(),
                    ),
                ],
              ),
            ),
            _ActionButton(
              icon: AppImages.callIcon,
              onTap: () => UrlLauncherMethods.makePhoneCall(
                orders?.delegateMobile ?? '',
              ),
            ),
            8.sbW,
            _ActionButton(
              icon: AppImages.chatIcon,
              onTap: () {
                NamedNavigatorImpl.push(
                  ChatScreen.routeName,
                  arguments: ChatScreenArgs(
                    orderId: 'DC${orders?.id ?? 0}',
                    accountType: 'user',
                    isVendor: false,
                    receiverDeviceToken: orders?.delegateFcmId ?? '',
                    receiverName: orders?.delegateName ?? '',
                    senderDeviceToken: orders?.userFcmId ?? '',
                    senderName: orders?.userName ?? '',
                    vendorDeviceToken: orders?.resturantVendorDeviceToken ?? '',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mainAppColor.withValues(alpha: .10),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: SvgPicture.asset(
              icon,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                AppColors.mainAppColor,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
