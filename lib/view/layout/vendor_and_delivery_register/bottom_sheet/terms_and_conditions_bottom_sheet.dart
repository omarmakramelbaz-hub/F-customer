import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/routes/app_routers_import.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/global_widgets/app_bottom_sheet.dart';
import '../../bottom_navigation/bottom_navigation_bar_screen.dart';
import '../../my_account/controller/my_account_controller.dart';

class TermsAndConditionsBottomSheet extends StatelessWidget {
  const TermsAndConditionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyAccountController>(
      builder: (context, myAccountController, child) {
        return AppBottomSheet(
          title: 'termsAndConditions'.tr,
          children: [
            ApiResponseWidget(
              apiResponse: myAccountController.settingResponse,
              onReload: myAccountController.getSetting,
              isEmpty: myAccountController.setting == null,
              child: Html(
                data: myAccountController.setting?.terms ?? '',
                style: {
                  'body': Style.fromTextStyle(
                    AppTextStyle.text16RS(color: FasakhanstaBrand.text),
                  ),
                },
              ),
            ),
            20.sbH,
            CustomButton(
              text: 'acceptTermsAndConditions'.tr,
              onPressed: () {
                NamedNavigatorImpl.push(
                  clean: true,
                  BottomNavigationBarScreen.routeName,
                );
              },
            ),
            20.sbH,
          ],
        );
      },
    );
  }
}
