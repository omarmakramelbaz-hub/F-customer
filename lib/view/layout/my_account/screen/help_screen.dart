import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/extensions/extensions.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/translation/all_translation.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/page_container/page_container.dart';
import '../account_app_bar/account_app_bar.dart';
import '../controller/my_account_controller.dart';
import '../widgets/help_box_widget.dart';

class HelpScreen extends StatefulWidget {
  static const String routeName = 'HelpScreen';
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) {
        return MyAccountController()
          ..initialHelp()
          ..getHelp();
      },
      child: Consumer<MyAccountController>(
        builder: (context, myAccountController, _) {
          return Scaffold(
            body: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  30.sbH,
                  CustomAccountAppBar(title: 'help'.tr),
                  const SizedBox(height: 22),
                  ApiResponseWidget(
                    apiResponse: myAccountController.helpResponse,
                    onReload: myAccountController.getHelp,
                    isEmpty: myAccountController.help.isEmpty,
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
                        child: ListView.builder(
                          itemCount: myAccountController.help.length,
                          itemBuilder: (context, index) {
                            return HelpBoxWidget(
                              question:
                                  myAccountController.help[index].question ??
                                      '',
                              answer:
                                  myAccountController.help[index].answer ?? '',
                            );
                          },
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
