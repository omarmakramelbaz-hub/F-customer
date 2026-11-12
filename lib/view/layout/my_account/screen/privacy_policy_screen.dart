import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/page_container/page_container.dart';
import '../account_app_bar/account_app_bar.dart';
import '../controller/my_account_controller.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  static const String routeName = 'PrivacyPolicyScreen';
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) {
        return MyAccountController()
          ..initialSetting()
          ..getSetting();
      },
      child: Consumer<MyAccountController>(
        builder: (context, myAccountController, _) {
          return Scaffold(
            body: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  30.sbH,
                  CustomAccountAppBar(title: 'privacyPolicy'.tr),
                  const SizedBox(height: 22),
                  ApiResponseWidget(
                    apiResponse: myAccountController.settingResponse,
                    onReload: myAccountController.getSetting,
                    isEmpty: myAccountController.setting == null,
                    child: Expanded(
                      child: Container(
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),
                                Text(
                                  'privacyPolicy'.tr,
                                  style: AppTextStyle.text16BS(),
                                ),
                                10.sbH,
                                // Html(data: cubit.model?.data?.first.value ?? ''),
                                Html(
                                  data:
                                      myAccountController.setting?.privacy ??
                                      '',
                                  style: {
                                    'body': Style.fromTextStyle(
                                      AppTextStyle.text18RS(
                                        color: FasakhanstaBrand.text,
                                      ),
                                    ),
                                  },
                                ),
                                const SizedBox(height: 34),
                              ],
                            ),
                          ),
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
