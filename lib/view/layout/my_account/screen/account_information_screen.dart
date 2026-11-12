import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/page_container/page_container.dart';
import '../../address/screen/address_screen.dart';
import '../../auth/controller/auth_controller.dart';
import '../account_app_bar/account_app_bar.dart';
import '../widgets/setting_button_widget.dart';
import 'personal_information_screen.dart';

class AccountInformationScreenArgs {
  final VoidCallback onSuccess;

  AccountInformationScreenArgs({required this.onSuccess});
}

class AccountInformationScreen extends StatefulWidget {
  static const String routeName = 'AccountInformationScreen';

  final AccountInformationScreenArgs args;
  const AccountInformationScreen({super.key, required this.args});

  @override
  State<AccountInformationScreen> createState() =>
      _AccountInformationScreenState();
}

class _AccountInformationScreenState extends State<AccountInformationScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        widget.args.onSuccess.call();
      },
      child: Scaffold(
        body: PageContainer(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                30.sbH,
                CustomAccountAppBar(title: 'accountInformation'.tr),
                const SizedBox(height: 22),
                Container(
                  width: context.width,
                  decoration: BoxDecoration(
                    color: FasakhanstaBrand.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(34),
                      topRight: Radius.circular(34),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.greyColor.withValues(alpha: 0.2),
                        offset: const Offset(0, -3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 26),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Provider.of<AuthController>(context)
                                        .profile
                                        ?.gender ==
                                    'male'
                                ? SvgPicture.asset(AppImages.avatarMale)
                                : Provider.of<AuthController>(context)
                                          .profile
                                          ?.gender ==
                                      'female'
                                ? SvgPicture.asset(AppImages.avatarFemale)
                                : Container(
                                    height: 56,
                                    width: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.mainAppColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        Provider.of<AuthController>(context)
                                                .profile
                                                ?.name
                                                ?.substring(0, 1) ??
                                            '',
                                        style: AppTextStyle.text18BW(
                                          color: FasakhanstaBrand.onOrange,
                                        ).copyWith(fontSize: 40),
                                      ),
                                    ),
                                  ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Provider.of<AuthController>(context)
                                          .profile
                                          ?.name ??
                                      '',
                                  style: AppTextStyle.text18BS(),
                                ),
                                10.sbH,
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SvgPicture.asset(AppImages.egyptIcon),
                                    const SizedBox(width: 8),
                                    Text(
                                      Provider.of<AuthController>(context)
                                              .profile
                                              ?.areaTitle ??
                                          '',
                                      style: AppTextStyle.text18RS(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 29),
                      Divider(
                        color: AppColors.greyColor.withValues(alpha: 0.2),
                        height: 2,
                      ),
                      const SizedBox(height: 24),
                      SettingButton(
                        title: 'personalInformation'.tr,
                        onTap: () => NamedNavigatorImpl.push(
                          PersonalInformationScreen.routeName,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SettingButton(
                        title: 'addresses'.tr,
                        onTap: () {
                          NamedNavigatorImpl.push(AddressScreen.routeName);
                        },
                      ),
                      const SizedBox(height: 32),
                      // SettingButton(
                      //   title: 'changeTheLanguage'.tr,
                      //   onTap: () {
                      //     NavigatorMethods.showAppBottomSheet(context,
                      //         ChangeLangBottomSheet(
                      //       onSuccess: () {
                      //         setState(() {});
                      //       },
                      //     ));
                      //   },
                      // ),
                      const SizedBox(height: 32),
                      // SettingButton(
                      //   title: 'favorite'.tr,
                      //   onTap: () {
                      //     NavigatorMethods.pushNamed(
                      //         context, FavoriteScreen.routeName);
                      //   },
                      // ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
