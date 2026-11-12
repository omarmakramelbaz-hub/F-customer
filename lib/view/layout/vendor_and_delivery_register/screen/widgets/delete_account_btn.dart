import 'package:faskhaninja/helpers/theme/fasakhansta_brand.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../helpers/extensions/extensions.dart';
import '../../../../../helpers/theme/app_colors.dart';
import '../../../../../helpers/translation/all_translation.dart';
import '../../../../../helpers/utils/common_methods.dart';
import '../../../../../helpers/utils/utils.dart';
import '../../../../custom_widgets/buttons/custom_button.dart';
import '../../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../../my_account/widgets/setting_button_widget.dart';

class DeleteAccountBtn extends StatelessWidget {
  const DeleteAccountBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingButton(
      title: 'deleteAccount'.tr,
      onTap: () {
        CommonMethods.showChooseDialog(
          context,
          message: 'didYouWantToDeleteThisAccount'.tr,
          onPressed: () {
            Navigator.pop(context);
            Utils.showAppDialog(
              Dialog(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Builder(
                  builder: (context) {
                    final controller = Provider.of<AuthController>(context);
                    return Container(
                      decoration: BoxDecoration(
                        color: FasakhanstaBrand.surface,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      height: 200,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              CustomFormField(
                                title: 'enterVerificationCode'.tr,
                                controller: controller.codeEC,
                              ),
                              10.sbH,
                              CustomButton(
                                text: 'deleteAccount'.tr,
                                onPressed: () => controller.deleteAccount(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
