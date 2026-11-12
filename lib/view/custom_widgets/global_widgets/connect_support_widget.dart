import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../helpers/images/app_images.dart';
import '../../../helpers/routes/app_routers_import.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/theme/app_text_style.dart';
import '../../../helpers/translation/all_translation.dart';
import '../../../helpers/utils/url_launcher_methods.dart';
import '../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../custom_widgets/custom_image/custom_image.dart';
import '../../layout/auth/controller/auth_controller.dart';
import '../../layout/chat/screen/admin_chat_screen.dart';
import '../../layout/my_account/controller/my_account_controller.dart';

class ConnectSupportWidget extends StatelessWidget {
  const ConnectSupportWidget({super.key, this.isDark = false});
  final bool? isDark;
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAccountController()
        ..initialSetting()
        ..getSetting(),
      child: Consumer<MyAccountController>(
        builder: (context, settingController, _) {
          return ApiResponseWidget(
            apiResponse: settingController.settingResponse,
            onReload: () => settingController.getSetting(),
            isEmpty: settingController.setting == null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  CustomImage(
                    path: AppImages.supportIcon,
                    type: ImageType.svg,
                    height: 32,
                    color: isDark == true
                        ? FasakhanstaBrand.text
                        : AppColors.mainAppColor,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      'contactSupport'.tr,
                      style: isDark == true
                          ? AppTextStyle.text14BS().copyWith(
                              color: FasakhanstaBrand.text,
                            )
                          : AppTextStyle.text14BS(),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      UrlLauncherMethods.makePhoneCall(
                        settingController.setting?.mobile ?? '',
                      );
                    },
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark == true
                            ? FasakhanstaBrand.surface
                            : AppColors.mainAppColor,
                        child: CustomImage(
                          path: AppImages.callIcon,
                          type: ImageType.svg,
                          color: isDark == true
                              ? FasakhanstaBrand.text
                              : FasakhanstaBrand.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(),
                  InkWell(
                    onTap: () {
                      NamedNavigatorImpl.push(
                        AdminChatScreen.routeName,
                        arguments: AdminChatScreenArgs(
                          receiverId:
                              settingController.setting?.adminId.toString() ??
                                  '1',
                          senderId: context
                              .read<AuthController>()
                              .profile!
                              .id!
                              .toString(),
                          adminId: settingController.setting?.adminId ?? 1,
                          adminDeviceToken:
                              settingController.setting?.adminDeviceToken ?? '',
                        ),
                      );
                    },
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark == true
                            ? FasakhanstaBrand.surface
                            : AppColors.mainAppColor,
                        child: CustomImage(
                          path: AppImages.chatIcon,
                          type: ImageType.svg,
                          color: isDark == true
                              ? FasakhanstaBrand.text
                              : FasakhanstaBrand.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
